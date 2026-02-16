/// Port of cartellino.py — pure Dart time calculation logic.
///
/// All time strings use the 'HH:MM' format.
library;

/// Threshold in minutes after work end time when overtime becomes liquidatable.
const int liquidatableOvertimeThresholdMinutes = 30;

/// Parses an 'HH:MM' string into a [Duration].
Duration _parseDuration(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) throw FormatException('Invalid time format: $hhmm');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return Duration(hours: hours, minutes: minutes);
}

/// Parses an 'HH:MM' string into a [DateTime] on today's date.
DateTime _parseTimeToday(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) throw FormatException('Invalid time format: $hhmm');
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
}

/// Formats a [DateTime] as 'HH:MM'.
String formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Formats a [Duration] as 'HHh:MMm'.
String formatDuration(Duration d) {
  final totalMinutes = d.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m';
}

/// Calculates the exact [DateTime] when the work turn ends.
DateTime turnEndDateTime(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  final start = _parseTimeToday(startTimeStr);
  final work = _parseDuration(workTimeStr);
  final lunch = _parseDuration(lunchTimeStr);
  final leisure = leisureTimeStr != null ? _parseDuration(leisureTimeStr) : Duration.zero;

  return start.add(work).add(lunch).subtract(leisure);
}

/// Calculates the turn end time as an 'HH:MM' string.
String turnEndTime(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  return formatTime(turnEndDateTime(startTimeStr,
      workTimeStr: workTimeStr, lunchTimeStr: lunchTimeStr, leisureTimeStr: leisureTimeStr));
}

/// Calculates the remaining [Duration] until the work turn finishes.
/// Returns a negative duration if the work turn is already over.
Duration durationToTurnEnd(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  final finishTime = turnEndDateTime(startTimeStr,
      workTimeStr: workTimeStr, lunchTimeStr: lunchTimeStr, leisureTimeStr: leisureTimeStr);
  return finishTime.difference(DateTime.now());
}

/// Calculates the remaining seconds until the work turn finishes. Returns 0 if already past.
double secondsToTurnEnd(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  final d = durationToTurnEnd(startTimeStr,
      workTimeStr: workTimeStr, lunchTimeStr: lunchTimeStr, leisureTimeStr: leisureTimeStr);
  return d.isNegative ? 0 : d.inMilliseconds / 1000;
}

/// Calculates the remaining seconds until liquidatable overtime begins
/// (30 minutes after work end).
double secondsToLiquidatableOvertime(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  final finishTime = turnEndDateTime(startTimeStr,
      workTimeStr: workTimeStr, lunchTimeStr: lunchTimeStr, leisureTimeStr: leisureTimeStr);
  final liquidatableTime = finishTime.add(
    const Duration(minutes: liquidatableOvertimeThresholdMinutes),
  );
  final diff = liquidatableTime.difference(DateTime.now());
  return diff.isNegative ? 0 : diff.inMilliseconds / 1000;
}

/// Returns a human-readable status string for the current work time.
///
/// Possible outputs:
/// - "Remaining time: 02h:15m"
/// - "Overtime: 00h:10m"
/// - "Liquidatable Overtime: 00h:35m"
String workTimeStatus(
  String startTimeStr, {
  String workTimeStr = '07:12',
  String lunchTimeStr = '00:30',
  String? leisureTimeStr,
}) {
  final remaining = durationToTurnEnd(startTimeStr,
      workTimeStr: workTimeStr, lunchTimeStr: lunchTimeStr, leisureTimeStr: leisureTimeStr);

  if (!remaining.isNegative) {
    return 'Remaining: ${formatDuration(remaining)}';
  }

  final overtime = remaining.abs();
  final overtimeMinutes = overtime.inMinutes;

  if (overtimeMinutes > liquidatableOvertimeThresholdMinutes) {
    return 'Liquidatable Overtime: ${formatDuration(overtime)}';
  }
  return 'Overtime: ${formatDuration(overtime)}';
}

/// Validates an 'HH:MM' string. Returns true if valid.
bool isValidTimeFormat(String value) {
  final regex = RegExp(r'^\d{2}:\d{2}$');
  if (!regex.hasMatch(value)) return false;
  final parts = value.split(':');
  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  if (hours == null || minutes == null) return false;
  return hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59;
}
