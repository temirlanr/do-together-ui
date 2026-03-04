import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Local notification service for chore reminders.
/// Uses flutter_local_notifications. Push notifications via FCM/APNs
/// are handled server-side; this service handles local scheduling only.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Logger _log = Logger();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    _log.i('NotificationService initialized');
  }

  /// Check if notifications are currently enabled/permitted on this device.
  Future<bool> checkPermissionStatus() async {
    if (!_initialized) await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await ios?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return false;
  }

  /// Request notification permissions. Returns true if granted.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      return result ?? true;
    }
    return false;
  }

  /// Schedule a reminder notification for a chore due today.
  Future<void> scheduleChoreReminder({
    required int notificationId,
    required String choreTitle,
    required String assigneeName,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chore_reminders',
      'Chore Reminders',
      channelDescription: 'Reminders for household chores',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use a simple display — schedule for the given time
    // For MVP, show immediately or use the built-in schedule
    await _plugin.show(
      notificationId,
      'Chore Reminder: $choreTitle',
      '$assigneeName — this chore is due today!',
      details,
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    _log.i('Notification tapped: ${response.payload}');
    // Navigation could be handled via a stream or callback
  }
}
