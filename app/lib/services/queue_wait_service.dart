import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'squad_service.dart';

/// Service for crowdsourced pandal queue wait times
/// Users report actual wait times → shared with squad + nearby users
class QueueWaitService {
  QueueWaitService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;
  static final QueueWaitService instance = QueueWaitService();

  final FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore? get _firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }
  final SquadService _squad = SquadService.instance;

  // In-memory cache of recent reports
  final Map<String, List<QueueReport>> _reportCache = {};
  final Map<String, QueueWaitEstimate> _serverEstimates = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _subscriptions = {};
  static const Duration _reportTtl = Duration(minutes: 30);
  static const int _maxReportsPerPandal = 20;

  // Stream controllers for UI updates
  final StreamController<Map<String, QueueWaitEstimate>> _estimatesController =
      StreamController.broadcast();
  Stream<Map<String, QueueWaitEstimate>> get estimatesStream =>
      _estimatesController.stream;

  /// Report a queue wait time for a pandal
  /// Called when user taps "I'm in queue - 45 min" in pandal detail sheet
  Future<void> reportQueueWait({
    required String pandalId,
    required int waitMinutes,
    String? source = 'user', // 'user' | 'squad' | 'public'
  }) async {
    final userId = _squad.currentUserId ?? 'anonymous';
    final now = DateTime.now();

    final report = QueueReport(
      pandalId: pandalId,
      waitMinutes: waitMinutes.clamp(0, 300), // Cap at 5 hours
      timestamp: now,
      reporterId: userId,
      source: source ?? 'user',
    );

    // Add to local cache immediately for instant UI feedback
    _addToCache(report);

    // Broadcast to squad members in real-time
    if (_squad.hasActiveSquad) {
      _broadcastToSquad(report);
    }

    // Persist to Firestore (aggregated, not raw reports)
    _persistToFirestore(pandalId).catchError((e) {
      debugPrint('[QueueWaitService] Firestore persist error: $e');
    });

    debugPrint('[QueueWaitService] 📝 Queue report: $pandalId = ${waitMinutes}min ($source)');
  }

  /// Get current wait estimate for a pandal
  QueueWaitEstimate? getEstimate(String pandalId) {
    _cleanupCache(pandalId);
    final reports = _reportCache[pandalId] ?? [];
    if (reports.isEmpty) {
      final server = _serverEstimates[pandalId];
      return server != null && DateTime.now().difference(server.lastUpdated) <= _reportTtl
          ? server : null;
    }
    return _computeEstimate(pandalId, reports);
  }

  /// Get estimates for multiple pandals (for list view)
  Map<String, QueueWaitEstimate> getEstimates(Iterable<String> pandalIds) {
    final result = <String, QueueWaitEstimate>{};
    for (final id in pandalIds) {
      final est = getEstimate(id);
      if (est != null) result[id] = est;
    }
    return result;
  }

  /// Listen to real-time queue updates from Firestore
  void startListening(Iterable<String> pandalIds) {
    for (final id in pandalIds) {
      _listenToPandal(id);
    }
  }

  void stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Receive queue report from squad member (via SquadService)
  void receiveSquadReport(QueueReport report) {
    _addToCache(report);
    _estimatesController.add(getEstimates(_reportCache.keys));
  }

  void _addToCache(QueueReport report) {
    final reports = _reportCache.putIfAbsent(report.pandalId, () => []);
    reports.add(report);
    
    // Keep only recent reports, max 20
    if (reports.length > _maxReportsPerPandal) {
      reports.removeRange(0, reports.length - _maxReportsPerPandal);
    }
    
    _estimatesController.add(getEstimates(_reportCache.keys));
  }

  void _cleanupCache(String pandalId) {
    final reports = _reportCache[pandalId];
    if (reports == null) return;
    
    final now = DateTime.now();
    reports.removeWhere((r) => now.difference(r.timestamp) > _reportTtl);
    
    if (reports.isEmpty) {
      _reportCache.remove(pandalId);
    }
  }

  QueueWaitEstimate _computeEstimate(String pandalId, List<QueueReport> reports) {
    final now = DateTime.now();
    
    // Weight recent reports higher
    double weightedSum = 0;
    double totalWeight = 0;
    int userReports = 0;
    int squadReports = 0;
    int publicReports = 0;

    for (final r in reports) {
      final ageMinutes = now.difference(r.timestamp).inMinutes;
      // Exponential decay: half-life of 10 minutes
      final weight = math.exp(-ageMinutes / 10.0);
      
      weightedSum += r.waitMinutes * weight;
      totalWeight += weight;
      
      switch (r.source) {
        case 'user': userReports++; break;
        case 'squad': squadReports++; break;
        case 'public': publicReports++; break;
      }
    }

    final estimatedWait = totalWeight > 0 ? (weightedSum / totalWeight).round() : reports.last.waitMinutes;
    final confidence = _calculateConfidence(reports.length, userReports, squadReports, publicReports);
    final trend = _calculateTrend(reports);

    return QueueWaitEstimate(
      pandalId: pandalId,
      estimatedWaitMinutes: estimatedWait,
      confidence: confidence,
      trend: trend,
      reportCount: reports.length,
      userReports: userReports,
      squadReports: squadReports,
      publicReports: publicReports,
      lastUpdated: reports.isNotEmpty ? reports.last.timestamp : now,
    );
  }

  QueueConfidence _calculateConfidence(int total, int user, int squad, int public) {
    // More reports = higher confidence, user/squad reports weighted higher
    final effectiveReports = user * 2 + squad * 1.5 + public * 1;
    if (effectiveReports >= 10) return QueueConfidence.high;
    if (effectiveReports >= 4) return QueueConfidence.medium;
    if (effectiveReports >= 1) return QueueConfidence.low;
    return QueueConfidence.none;
  }

  QueueTrend _calculateTrend(List<QueueReport> reports) {
    if (reports.length < 3) return QueueTrend.stable;
    
    // Compare last 3 vs previous 3
    final recent = reports.take(3).map((r) => r.waitMinutes.toDouble()).toList();
    final older = reports.skip(3).take(3).map((r) => r.waitMinutes.toDouble()).toList();
    
    if (older.isEmpty) return QueueTrend.stable;
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    final diff = recentAvg - olderAvg;
    
    if (diff > 5) return QueueTrend.increasing;
    if (diff < -5) return QueueTrend.decreasing;
    return QueueTrend.stable;
  }

  Future<void> _persistToFirestore(String pandalId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final reports = _reportCache[pandalId];
    if (reports == null || reports.isEmpty) return;

    final estimate = _computeEstimate(pandalId, reports);
    
    await firestore.collection('pandal_queue_waits').doc(pandalId).set({
      'estimated_wait_minutes': estimate.estimatedWaitMinutes,
      'confidence': estimate.confidence.name,
      'trend': estimate.trend.name,
      'report_count': estimate.reportCount,
      'user_reports': estimate.userReports,
      'squad_reports': estimate.squadReports,
      'public_reports': estimate.publicReports,
      'last_updated': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToPandal(String pandalId) {
    final firestore = _firestore;
    if (firestore == null || _subscriptions.containsKey(pandalId)) return;
    _subscriptions[pandalId] = firestore.collection('pandal_queue_waits').doc(pandalId).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;
        // Update cache with server estimate
        final estimate = QueueWaitEstimate(
          pandalId: pandalId,
          estimatedWaitMinutes: data['estimated_wait_minutes'] as int? ?? 0,
          confidence: QueueConfidence.values.firstWhere(
            (c) => c.name == data['confidence'],
            orElse: () => QueueConfidence.none),
          trend: QueueTrend.values.firstWhere(
            (t) => t.name == data['trend'],
            orElse: () => QueueTrend.stable),
          reportCount: data['report_count'] as int? ?? 0,
          userReports: data['user_reports'] as int? ?? 0,
          squadReports: data['squad_reports'] as int? ?? 0,
          publicReports: data['public_reports'] as int? ?? 0,
          lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
        // Merge with local cache (server wins for older data)
        _mergeServerEstimate(pandalId, estimate);
      },
      onError: (e) => debugPrint('[QueueWaitService] Listener error for $pandalId: $e'),
    );
  }

  void _mergeServerEstimate(String pandalId, QueueWaitEstimate server) {
    // Keep local reports that are newer than server
    final localReports = _reportCache[pandalId] ?? [];
    final cutoff = server.lastUpdated.subtract(const Duration(minutes: 5));
    final freshLocal = localReports.where((r) => r.timestamp.isAfter(cutoff)).toList();
    
    _serverEstimates[pandalId] = server;
    if (freshLocal.isEmpty) _reportCache.remove(pandalId);
    _estimatesController.add(getEstimates({..._reportCache.keys, ..._serverEstimates.keys}));
  }

  void _broadcastToSquad(QueueReport report) {
    _squad.broadcastQueueReport(report);
  }

  void dispose() {
    stopListening();
    _estimatesController.close();
  }
}

/// Individual queue wait report
class QueueReport {
  const QueueReport({
    required this.pandalId,
    required this.waitMinutes,
    required this.timestamp,
    required this.reporterId,
    required this.source,
  });

  final String pandalId;
  final int waitMinutes;
  final DateTime timestamp;
  final String reporterId;
  final String source; // 'user' | 'squad' | 'public'
}

/// Aggregated queue wait estimate for UI
class QueueWaitEstimate {
  const QueueWaitEstimate({
    required this.pandalId,
    required this.estimatedWaitMinutes,
    required this.confidence,
    required this.trend,
    required this.reportCount,
    required this.userReports,
    required this.squadReports,
    required this.publicReports,
    required this.lastUpdated,
  });

  final String pandalId;
  final int estimatedWaitMinutes;
  final QueueConfidence confidence;
  final QueueTrend trend;
  final int reportCount;
  final int userReports;
  final int squadReports;
  final int publicReports;
  final DateTime lastUpdated;

  String get formattedWait {
    if (estimatedWaitMinutes < 1) return 'No wait';
    if (estimatedWaitMinutes < 60) return '$estimatedWaitMinutes min';
    final hrs = estimatedWaitMinutes ~/ 60;
    final mins = estimatedWaitMinutes % 60;
    return mins == 0 ? '${hrs}h' : '${hrs}h ${mins}m';
  }

  String get confidenceLabel {
    switch (confidence) {
      case QueueConfidence.high: return 'High confidence';
      case QueueConfidence.medium: return 'Medium confidence';
      case QueueConfidence.low: return 'Low confidence';
      case QueueConfidence.none: return 'No data';
    }
  }

  String get trendIcon {
    switch (trend) {
      case QueueTrend.increasing: return '📈';
      case QueueTrend.decreasing: return '📉';
      case QueueTrend.stable: return '➡️';
    }
  }

  Color get confidenceColor {
    switch (confidence) {
      case QueueConfidence.high: return const Color(0xFF4CAF50);
      case QueueConfidence.medium: return const Color(0xFFFFC107);
      case QueueConfidence.low: return const Color(0xFFFF9800);
      case QueueConfidence.none: return const Color(0xFF9E9E9E);
    }
  }
}

enum QueueConfidence { high, medium, low, none }
enum QueueTrend { increasing, decreasing, stable }
