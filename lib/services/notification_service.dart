/// Local notification service — replaces Telegram notifications.
///
/// Schedules local notifications for:
///   • Work shift end
///   • Liquidatable overtime threshold (30 min after shift end)
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    // Android 13+ runtime permission
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // iOS permission
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedule a notification after [delay].
  Future<void> scheduleAfter({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (kIsWeb || delay.isNegative) return;

    await _cancelNotification(id);

    // Schedule notification in the background
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'cartellino_channel',
          'Cartellino Notify',
          channelDescription: 'Work shift notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule work-end notification.
  Future<void> scheduleWorkEnd(Duration delay) async {
    await scheduleAfter(
      id: 1,
      title: '🏁 Turno finito!',
      body: 'Il tuo turno di lavoro è finito. È ora di andare!',
      delay: delay,
    );
  }

  /// Schedule liquidatable overtime notification.
  Future<void> scheduleLiquidatableOvertime(Duration delay) async {
    await scheduleAfter(
      id: 2,
      title: '⏰ Straordinario liquidabile!',
      body: 'Hai superato i 30 minuti di straordinario. Ora è liquidabile!',
      delay: delay,
    );
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> _cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }
}
