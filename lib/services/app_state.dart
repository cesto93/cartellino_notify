/// App-wide state management using ChangeNotifier (simple, no external deps).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cartellino_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Represents the current status of the work shift.
enum ShiftStatus {
  notStarted, // No start time set today
  working, // Currently in the work shift
  overtime, // Past work end but < 30 min
  liquidatable, // Past 30 min of overtime
}

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();

  // ── Reactive fields ────────────────────────────────────────────────────

  String? _startTime;
  String? get startTime => _startTime;

  String _workTime = '07:12';
  String get workTime => _workTime;

  String _lunchTime = '00:30';
  String get lunchTime => _lunchTime;

  String _minTime = '06:00';
  String get minTime => _minTime;

  bool _liqOvertimeNotifyEnabled = true;
  bool get liqOvertimeNotifyEnabled => _liqOvertimeNotifyEnabled;

  ShiftStatus _status = ShiftStatus.notStarted;
  ShiftStatus get status => _status;

  String _endTimeDisplay = '--:--';
  String get endTimeDisplay => _endTimeDisplay;

  String _remainingDisplay = '';
  String get remainingDisplay => _remainingDisplay;

  String _liquidatableTimeDisplay = '--:--';
  String get liquidatableTimeDisplay => _liquidatableTimeDisplay;

  String _minEndTimeDisplay = '--:--';
  String get minEndTimeDisplay => _minEndTimeDisplay;

  bool _notificationsScheduled = false;
  bool get notificationsScheduled => _notificationsScheduled;

  double _progress = 0; // 0..1
  double get progress => _progress;

  Timer? _ticker;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  Future<void> init() async {
    await _notifications.init();
    await _notifications.requestPermissions();
    await _loadFromDb();
    if (_startTime != null) {
      await _scheduleNotifications();
    }
    _startTicker();
  }

  Future<void> _loadFromDb() async {
    _workTime = await _db.getSetting('work_time') ?? '07:12';
    _lunchTime = await _db.getSetting('lunch_time') ?? '00:30';
    _minTime = await _db.getSetting('min_time') ?? '06:00';
    final liqNotifyRaw = await _db.getSetting('liq_overtime_notify_enabled');
    // Default to enabled when the setting was never stored.
    _liqOvertimeNotifyEnabled =
        liqNotifyRaw == null || liqNotifyRaw == '1' || liqNotifyRaw.toLowerCase() == 'true';
    _startTime = await _db.getStartTime();
    _recalculate();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _recalculate();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────

  /// Mark arrival at current time.
  Future<void> markArrival() async {
    final now = formatTime(DateTime.now());
    _startTime = now;
    await _db.storeStartTime(now);
    _recalculate();
    notifyListeners();
    await _scheduleNotifications();
  }

  /// Set a manual start time.
  Future<void> setStartTime(String time) async {
    _startTime = time;
    await _db.storeStartTime(time);
    _recalculate();
    notifyListeners();
    await _scheduleNotifications();
  }

  /// Update global work time setting.
  Future<void> setWorkTime(String time) async {
    _workTime = time;
    await _db.storeSetting('work_time', time);
    _recalculate();
    notifyListeners();
    if (_startTime != null) await _scheduleNotifications();
  }

  /// Update global lunch time setting.
  Future<void> setLunchTime(String time) async {
    _lunchTime = time;
    await _db.storeSetting('lunch_time', time);
    _recalculate();
    notifyListeners();
    if (_startTime != null) await _scheduleNotifications();
  }

  /// Update global minimum work time setting.
  /// This is the minimum time to stay at work when recovering another day
  /// (less than the full work time).
  Future<void> setMinTime(String time) async {
    _minTime = time;
    await _db.storeSetting('min_time', time);
    _recalculate();
    notifyListeners();
    if (_startTime != null) await _scheduleNotifications();
  }

  /// Enable or disable the liquidatable overtime notification.
  Future<void> setLiqOvertimeNotifyEnabled(bool enabled) async {
    _liqOvertimeNotifyEnabled = enabled;
    await _db.storeSetting(
        'liq_overtime_notify_enabled', enabled ? '1' : '0');
    notifyListeners();
    if (_startTime != null) await _scheduleNotifications();
  }

  /// Reset the day (clear start time).
  Future<void> resetDay() async {
    _startTime = null;
    _notificationsScheduled = false;
    await _db.clearDailySetting('start_time');
    await _notifications.cancelAll();
    _recalculate();
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────

  void _recalculate() {
    if (_startTime == null) {
      _status = ShiftStatus.notStarted;
      _endTimeDisplay = '--:--';
      _remainingDisplay = '';
      _liquidatableTimeDisplay = '--:--';
      _minEndTimeDisplay = '--:--';
      _progress = 0;
      return;
    }

    final endDt = turnEndDateTime(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
    );
    _endTimeDisplay = formatTime(endDt);

    final minEndDt = minTurnEndDateTime(
      _startTime!,
      minTimeStr: _minTime,
      lunchTimeStr: _lunchTime,
    );
    _minEndTimeDisplay = formatTime(minEndDt);

    final liquidatableDt = endDt.add(
      const Duration(minutes: liquidatableOvertimeThresholdMinutes),
    );
    _liquidatableTimeDisplay = formatTime(liquidatableDt);

    final remaining = durationToTurnEnd(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
    );

    _remainingDisplay = workTimeStatus(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
    );

    // Calculate progress (0.0 = just started → 1.0 = shift done)

    final startDt = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      int.parse(_startTime!.split(':')[0]),
      int.parse(_startTime!.split(':')[1]),
    );
    final totalWork = endDt.difference(startDt);
    final elapsed = DateTime.now().difference(startDt);
    if (totalWork.inSeconds > 0) {
      _progress = (elapsed.inSeconds / totalWork.inSeconds).clamp(0.0, 1.0);
    }

    if (remaining.isNegative) {
      final overtimeMinutes = remaining.abs().inMinutes;
      if (overtimeMinutes > liquidatableOvertimeThresholdMinutes) {
        _status = ShiftStatus.liquidatable;
      } else {
        _status = ShiftStatus.overtime;
      }
    } else {
      _status = ShiftStatus.working;
    }
  }

  Future<void> _scheduleNotifications() async {
    if (_startTime == null) return;

    final secToEnd = secondsToTurnEnd(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
    );

    final secToMin = secondsToMinEnd(
      _startTime!,
      minTimeStr: _minTime,
      lunchTimeStr: _lunchTime,
    );

    final secToLiq = secondsToLiquidatableOvertime(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
    );

    if (secToMin > 0) {
      await _notifications.scheduleMinEnd(Duration(seconds: secToMin.round()));
    }

    if (secToEnd > 0) {
      await _notifications.scheduleWorkEnd(Duration(seconds: secToEnd.round()));
    }

    if (_liqOvertimeNotifyEnabled && secToLiq > 0) {
      await _notifications.scheduleLiquidatableOvertime(Duration(seconds: secToLiq.round()));
    } else {
      // Make sure a previously scheduled liq. overtime notification
      // is removed when the option is off.
      await _notifications.cancelNotification(2);
    }

    _notificationsScheduled = true;
    notifyListeners();
  }
}
