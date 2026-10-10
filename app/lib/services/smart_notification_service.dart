import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/squad_service.dart';
import '../services/live_tracking_enhancements.dart';

/// Smart notification service for arrival, separation, battery, and route alerts
class SmartNotificationService {
  SmartNotificationService({
    FlutterLocalNotificationsPlugin? notifications,
    SquadService? squad,
    LiveTrackingEngine? tracking,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _squad = squad ?? SquadService.instance,
       _tracking = tracking ?? LiveTrackingEngine.instance;
  static final SmartNotificationService instance = SmartNotificationService();

  final FlutterLocalNotificationsPlugin _notifications;
  final SquadService _squad;
  final LiveTrackingEngine _tracking;

  bool _initialized = false;
  Timer? _batteryCheckTimer;
  Timer? _separationCheckTimer;
  String? _notifiedSeparatedMember;
  bool _lowBatteryNotified = false;
  int? _lastEtaMinutes;
  Future<void>? _initialization;
  void Function(int tabIndex)? onNavigateToTab;
  NotificationResponse? _pendingTap;

  bool get isInitialized => _initialized;

  static const String _channelId = 'puja_smart_alerts';
  static const String _channelName = 'Puja Smart Alerts';
  static const String _channelDesc =
      'Real-time alerts for arrival, squad separation, battery, and route deviations';

  /// Initialize notification channels and listeners
  Future<void> initialize() async {
    if (_initialized) return;
    final pending = _initialization;
    if (pending != null) return pending;
    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('ic_notification');
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

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
      final launch = await _notifications.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _pendingTap = launch?.notificationResponse;
      }
      _attachListeners();
      _startPeriodicChecks();

      debugPrint('[SmartNotifications] ✅ Initialized');
    } catch (e) {
      // In test environment, platform implementations may not be available
      debugPrint('[SmartNotifications] Initialization failed: $e');
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
    _lastEtaMinutes = null;
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
    final eta = metrics.etaToDestination?.inMinutes;
    if (eta == null) {
      _lastEtaMinutes = null;
      return;
    }
    final previous = _lastEtaMinutes;
    if (previous == null) {
      _lastEtaMinutes = eta;
    } else if ((eta - previous).abs() >= 5) {
      _lastEtaMinutes = eta;
      _showNotification(
        id: 104,
        title: 'Walking ETA updated',
        body: 'Your destination is now about $eta minutes away.',
        payload: 'eta:$eta',
        priority: Priority.defaultPriority,
      );
    }
  }

  void _checkSquadSeparation() {
    final alert = _squad.activeSeparationAlert;
    if (alert == null || alert.isCleared) {
      _notifiedSeparatedMember = null;
      return;
    }
    if (_notifiedSeparatedMember == alert.memberId) return;
    _notifiedSeparatedMember = alert.memberId;
      _showNotification(
        id: 102,
        title: '👥 Squad Separation',
        body:
            '${alert.memberName} is ${_formatDistance(alert.distanceMeters)} away (threshold: ${_formatDistance(alert.thresholdMeters)})',
        payload: 'separation:${alert.memberId}',
        priority: Priority.max,
      );
  }

  Future<void> _checkBatteryLevel() async {
    final level = await _squad.refreshBatteryLevel();
    if (!_initialized) return;
    if (level > 20) _lowBatteryNotified = false;
    if (level <= 20 && level >= 0 && !_lowBatteryNotified) {
      _lowBatteryNotified = true;
      _showNotification(
        id: 103,
        title: '🔋 Low Battery',
        body:
            'Your battery is at $level%. Consider enabling battery saver mode.',
        payload: 'battery:$level',
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
    if (!_initialized) return;
    try {
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
          icon: 'ic_notification',
          enableVibration: true,
          playSound: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.private,
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
    } catch (e) {
      debugPrint('[SmartNotifications] Could not show alert: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    debugPrint('[SmartNotifications] Tapped: $payload');

    // Handle deep links based on payload
    if (payload.startsWith('separation:')) {
      final memberId = payload.split(':')[1];
      _squad.focusMember(memberId);
    }
    if (onNavigateToTab == null) {
      _pendingTap = response;
    } else {
      onNavigateToTab!(payload.startsWith('separation:') ? 3 : 0);
    }
  }

  void handlePendingTap() {
    final response = _pendingTap;
    _pendingTap = null;
    if (response != null) _onNotificationTap(response);
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
    await initialize();
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
    _initialized = false;
    _notifiedSeparatedMember = null;
    _lowBatteryNotified = false;
    _lastEtaMinutes = null;
  }
}
