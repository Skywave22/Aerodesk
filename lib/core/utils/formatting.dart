const List<String> _monthNames = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdayNames = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Zero-pads [value] to two digits.
String two(int value) => value.toString().padLeft(2, '0');

/// Formats a time of day, e.g. `09:05` or `9:05 AM`.
String formatTimeOfDay(DateTime dateTime, {required bool use24Hour}) {
  if (use24Hour) return '${two(dateTime.hour)}:${two(dateTime.minute)}';
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final suffix = dateTime.hour < 12 ? 'AM' : 'PM';
  return '$hour:${two(dateTime.minute)} $suffix';
}

/// Formats a time of day including seconds.
String formatTimeWithSeconds(DateTime dateTime, {required bool use24Hour}) {
  if (use24Hour) return '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  return '${formatTimeOfDay(dateTime, use24Hour: use24Hour)}:${two(dateTime.second)}';
}

/// Formats a desktop-style date, e.g. `Sat, 17 Oct 2026`.
String formatDesktopDate(DateTime dateTime) {
  return '${_weekdayNames[dateTime.weekday - 1]}, '
      '${dateTime.day} ${_monthNames[dateTime.month - 1]} ${dateTime.year}';
}

/// Formats a stopwatch duration as `MM:SS.cc` (or `H:MM:SS.cc`).
String formatStopwatch(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final centis = (duration.inMilliseconds ~/ 10) % 100;
  final base = '${two(minutes)}:${two(seconds)}.${two(centis)}';
  return hours > 0 ? '$hours:$base' : base;
}

/// Formats a byte count as a human readable size, e.g. `1.4 MB`.
String formatBytes(int? bytes) {
  if (bytes == null || bytes < 0) return '—';
  if (bytes < 1024) return '$bytes B';
  const units = <String>['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value < 10 && value != value.roundToDouble() ? 1 : 0)} ${units[unitIndex]}';
}
