/// Local notification service — replaces Telegram notifications.
///
/// Schedules local notifications for:
///   • Work shift end
///   • Liquidatable overtime threshold (30 min after shift end)
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

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
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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

    // Use a simple delayed show approach since we only need relative delays
    Future.delayed(delay, () async {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
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
      );
    });
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
