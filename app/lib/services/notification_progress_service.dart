import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages native Android ongoing notification shade updates
/// with a progress bar, current location, and next pandal in list.
class NotificationProgressService {
  static final NotificationProgressService instance = NotificationProgressService._();
  NotificationProgressService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _trailNotificationId = 7701;
  static const String _trailChannelId = 'pujo_trail_progress_channel';
  static const String _trailChannelName = 'Pujo Trail Live Progress';
  static const String _trailChannelDescription =
      'Shows live pandal hopping progress bar, current pandal, and next target';

  /// Initializes notification plugin and requests permissions on Android 13+
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Tapping notification brings the user back to the app
        },
      );

      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationProgressService] Init error: $e');
    }
  }

  /// Updates the ongoing progress bar notification in the Android shade
  Future<void> showTrailProgress({
    required int currentStep,
    required int totalSteps,
    required String currentPandalName,
    required String nextPandalName,
    double? distanceToNextMeters,
    int? remainingMinutes,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    final percent = totalSteps > 0 ? ((currentStep / totalSteps) * 100).round() : 0;
    final distStr = distanceToNextMeters != null
        ? (distanceToNextMeters >= 1000
            ? '${(distanceToNextMeters / 1000).toStringAsFixed(1)} km away'
            : '${distanceToNextMeters.round()} m away')
        : '';

    final subtext = remainingMinutes != null && remainingMinutes > 0
        ? '$remainingMinutes mins left'
        : 'Active Trail';

    final body = nextPandalName.isNotEmpty
        ? '📍 At: $currentPandalName\n➡️ Next: $nextPandalName ${distStr.isNotEmpty ? '($distStr)' : ''}'
        : '🎉 Visited all planned pandals!';

    final androidDetails = AndroidNotificationDetails(
      _trailChannelId,
      _trailChannelName,
      channelDescription: _trailChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: totalSteps,
      progress: currentStep,
      onlyAlertOnce: true,
      color: const Color(0xFFD32F2F),
      subText: subtext,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '🎯 Pujo Trail: $currentStep of $totalSteps Visited ($percent%)',
        summaryText: subtext,
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        _trailNotificationId,
        '🎯 Pujo Trail: $currentStep of $totalSteps Visited ($percent%)',
        body,
        details,
      );
    } catch (e) {
      debugPrint('[NotificationProgressService] show error: $e');
    }
  }

  /// Cancels the ongoing trail progress notification
  Future<void> cancelTrailProgress() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(_trailNotificationId);
    } catch (e) {
      debugPrint('[NotificationProgressService] cancel error: $e');
    }
  }

  /// Shows celebratory notification when the entire trail is completed
  Future<void> showTrailCompleted({
    required int totalVisited,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      _trailChannelId,
      _trailChannelName,
      channelDescription: _trailChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
      color: const Color(0xFFFFD700),
      styleInformation: BigTextStyleInformation(
        'Congratulations! You have visited all $totalVisited pandals on your custom trail. Shubho Sharodiya!',
        contentTitle: '🎉 Custom Pujo Trail Completed!',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.cancel(_trailNotificationId);
      await _notificationsPlugin.show(
        _trailNotificationId + 1,
        '🎉 Custom Pujo Trail Completed!',
        'You visited $totalVisited pandals! Shubho Sharodiya!',
        details,
      );
    } catch (e) {
      debugPrint('[NotificationProgressService] completion error: $e');
    }
  }
}
