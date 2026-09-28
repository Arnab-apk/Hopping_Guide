import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/squad_member.dart';
import '../services/squad_service.dart';
import '../services/live_tracking_enhancements.dart';

/// Smart notification service for arrival, separation, battery, and route alerts
class SmartNotificationService {
  SmartNotificationService._();
  static final SmartNotificationService instance = SmartNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SquadService _squad = SquadService.instance;
  final LiveTrackingEngine _tracking = LiveTrackingEngine.instance;

  bool _initialized = false;
  Timer? _batteryCheckTimer;
  Timer? _separationCheckTimer;

  static const String _channelId = 'puja_smart_alerts';
  static const String _channelName = 'Puja Smart Alerts';
  static const String _channelDesc =
      'Real-time alerts for arrival, squad separation, battery, and route deviations';

  /// Initialize notification channels and listeners
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _notifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create channel
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: _channelDesc,
                importance: Importance.high,
                enableVibration: true,
                playSound: true,
              ));

      _initialized = true;
      _attachListeners();
      _startPeriodicChecks();

      debugPrint('[SmartNotifications] ✅ Initialized');
    } catch (e) {
      // In test environment, platform implementations may not be available
      debugPrint('[SmartNotifications] Init skipped in test env: $e');
      _initialized = true; // Mark as initialized to avoid repeated attempts
    }
  }

  void _attachListeners() {
    // Live tracking alerts
    _tracking.onArrivalAlert = _onArrival;
    _tracking.onDeviationAlert = _onDeviation;
    _tracking.onEtaUpdate = _onEtaSignificantChange;

    // Squad separation
    _squad.addListener(_checkSquadSeparation);
  }

  void _startPeriodicChecks() {
    // Battery check every 2 minutes
    _batteryCheckTimer?.cancel();
    _batteryCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkBatteryLevel();
    });

    // Separation check every 10 seconds
    _separationCheckTimer?.cancel();
    _separationCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkSquadSeparation();
    });
  }

  // --- Alert Handlers ---

  void _onArrival(ArrivalAlert alert) {
    _showNotification(
      id: 100,
      title: '🎉 Arrived!',
      body: 'You\'ve reached ${alert.destinationName}',
      payload: 'arrival:${alert.destinationName}',
      priority: Priority.high,
    );
  }

  void _onDeviation(RouteDeviationAlert alert) {
    if (alert.consecutiveCount == 1) {
      _showNotification(
        id: 101,
        title: '⚠️ Off Route',
        body:
            'You\'ve deviated ${alert.deviationMeters.round()}m from your walking route',
        payload: 'deviation:${alert.deviationMeters.round()}',
        priority: Priority.high,
      );
    }
  }

  void _onEtaSignificantChange(LiveWalkingMetrics metrics) {
    // Notify on significant ETA changes (> 5 min difference)
    // Could be implemented with previous ETA tracking
  }

  void _checkSquadSeparation() {
    final alert = _squad.activeSeparationAlert;
    if (alert != null && !alert.isCleared) {
      _showNotification(
        id: 102,
        title: '👥 Squad Separation',
        body:
            '${alert.memberName} is ${_formatDistance(alert.distanceMeters)} away (threshold: ${_formatDistance(alert.thresholdMeters)})',
        payload: 'separation:${alert.memberId}',
        priority: Priority.max,
      );
    }
  }

  void _checkBatteryLevel() {
    final userMember = _squad.members.firstWhere(
      (m) => m.isUser,
      orElse: () => SquadMember(
        id: 'user',
        name: 'You',
        latitude: 0,
        longitude: 0,
        status: '',
        lastSeen: DateTime.now(),
        isUser: true,
        batteryLevel: 100,
        avatarColorHex: 0xFFD32F2F,
      ),
    );

    if (userMember.batteryLevel <= 20 && userMember.batteryLevel > 0) {
      _showNotification(
        id: 103,
        title: '🔋 Low Battery',
        body:
            'Your battery is at ${userMember.batteryLevel}%. Consider enabling battery saver mode.',
        payload: 'battery:${userMember.batteryLevel}',
        priority: Priority.defaultPriority,
      );
    }
  }

  // --- Notification Helpers ---

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required Priority priority,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: priority,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    debugPrint('[SmartNotifications] Tapped: $payload');

    // Handle deep links based on payload
    if (payload.startsWith('separation:')) {
      final memberId = payload.split(':')[1];
      _squad.focusMember(memberId);
    }
    // Add more handlers as needed
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Show custom notification (for testing or external triggers)
  Future<void> showCustom({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload ?? '',
      priority: Priority.high,
    );
  }

  void dispose() {
    _batteryCheckTimer?.cancel();
    _separationCheckTimer?.cancel();
    _squad.removeListener(_checkSquadSeparation);
    _tracking.onArrivalAlert = null;
    _tracking.onDeviationAlert = null;
    _tracking.onEtaUpdate = null;
  }
}