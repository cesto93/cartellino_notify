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

  String? _leisureTime;
  String? get leisureTime => _leisureTime;

  ShiftStatus _status = ShiftStatus.notStarted;
  ShiftStatus get status => _status;

  String _endTimeDisplay = '--:--';
  String get endTimeDisplay => _endTimeDisplay;

  String _remainingDisplay = '';
  String get remainingDisplay => _remainingDisplay;

  String _liquidatableTimeDisplay = '--:--';
  String get liquidatableTimeDisplay => _liquidatableTimeDisplay;

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
    _startTicker();
  }

  Future<void> _loadFromDb() async {
    _workTime = await _db.getSetting('work_time') ?? '07:12';
    _lunchTime = await _db.getSetting('lunch_time') ?? '00:30';
    _startTime = await _db.getStartTime();
    _leisureTime = await _db.getDailySetting('leisure_time');
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

  /// Set leisure time for today.
  Future<void> setLeisureTime(String time) async {
    _leisureTime = time;
    await _db.storeDailySetting('leisure_time', time);
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

  /// Clear leisure time for today.
  Future<void> clearLeisureTime() async {
    _leisureTime = null;
    await _db.clearDailySetting('leisure_time');
    _recalculate();
    notifyListeners();
    if (_startTime != null) await _scheduleNotifications();
  }

  /// Reset the day (clear start time + leisure time).
  Future<void> resetDay() async {
    _startTime = null;
    _leisureTime = null;
    _notificationsScheduled = false;
    await _db.clearDailySetting('start_time');
    await _db.clearDailySetting('leisure_time');
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
      _progress = 0;
      return;
    }

    final endDt = turnEndDateTime(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
      leisureTimeStr: _leisureTime,
    );
    _endTimeDisplay = formatTime(endDt);

    final liquidatableDt = endDt.add(
      const Duration(minutes: liquidatableOvertimeThresholdMinutes),
    );
    _liquidatableTimeDisplay = formatTime(liquidatableDt);

    final remaining = durationToTurnEnd(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
      leisureTimeStr: _leisureTime,
    );

    _remainingDisplay = workTimeStatus(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
      leisureTimeStr: _leisureTime,
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
      leisureTimeStr: _leisureTime,
    );

    final secToLiq = secondsToLiquidatableOvertime(
      _startTime!,
      workTimeStr: _workTime,
      lunchTimeStr: _lunchTime,
      leisureTimeStr: _leisureTime,
    );

    if (secToEnd > 0) {
      await _notifications.scheduleWorkEnd(Duration(seconds: secToEnd.round()));
    }

    if (secToLiq > 0) {
      await _notifications.scheduleLiquidatableOvertime(Duration(seconds: secToLiq.round()));
    }

    _notificationsScheduled = true;
    notifyListeners();
  }
}
