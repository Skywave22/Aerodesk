import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/formatting.dart';

/// A simple analogue clock face drawn with a CustomPainter.
class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.dateTime, this.diameter = 140});

  final DateTime dateTime;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _ClockFacePainter(
          dateTime: dateTime,
          dialColor: theme.colorScheme.surfaceContainerHigh,
          handColor: theme.colorScheme.onSurface,
          accentColor: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  const _ClockFacePainter({
    required this.dateTime,
    required this.dialColor,
    required this.handColor,
    required this.accentColor,
  });

  final DateTime dateTime;
  final Color dialColor;
  final Color handColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final dial = Paint()
      ..color = dialColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, dial);

    final outline = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 2, outline);

    final tick = Paint()
      ..color = handColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (var minute = 0; minute < 60; minute += 5) {
      final angle = (minute / 60) * 2 * math.pi - math.pi / 2;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 14);
      canvas.drawLine(inner, outer, tick);
    }

    final hourAngle = ((dateTime.hour % 12) / 12 + dateTime.minute / 720) * 2 * math.pi - math.pi / 2;
    final minuteAngle = (dateTime.minute / 60) * 2 * math.pi - math.pi / 2;
    final secondAngle = (dateTime.second / 60) * 2 * math.pi - math.pi / 2;

    final hourHand = Paint()
      ..color = handColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * 0.5),
      hourHand,
    );

    final minuteHand = Paint()
      ..color = handColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * 0.72),
      minuteHand,
    );

    final secondHand = Paint()
      ..color = accentColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(secondAngle), math.sin(secondAngle)) * (radius * 0.78),
      secondHand,
    );

    final pin = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pin);
  }

  @override
  bool shouldRepaint(_ClockFacePainter oldDelegate) => oldDelegate.dateTime != dateTime;
}

/// A city with a fixed UTC offset, used by the world clock.
class WorldClock {
  const WorldClock(this.city, this.country, this.offsetHours);

  final String city;
  final String country;
  final double offsetHours;

  /// Local time of this city for [now].
  DateTime timeFor(DateTime now) {
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    ).add(Duration(minutes: (offsetHours * 60).round()));
  }
}

/// Cities offered by the world clock. Offsets are fixed; daylight saving is
/// intentionally not applied because the app does not ship a timezone database.
const List<WorldClock> kWorldClocks = <WorldClock>[
  WorldClock('Karachi', 'Pakistan', 5),
  WorldClock('Dubai', 'United Arab Emirates', 4),
  WorldClock('London', 'United Kingdom', 0),
  WorldClock('Berlin', 'Germany', 1),
  WorldClock('New York', 'United States', -5),
  WorldClock('Los Angeles', 'United States', -8),
  WorldClock('Tokyo', 'Japan', 9),
  WorldClock('Sydney', 'Australia', 10),
];

/// Formats the offset of a world clock, e.g. `UTC+5`.
String formatUtcOffset(WorldClock clock) {
  final hours = clock.offsetHours.truncate();
  final minutes = ((clock.offsetHours - hours).abs() * 60).round();
  final sign = clock.offsetHours < 0 ? '-' : '+';
  return 'UTC$sign${hours.abs()}${minutes == 0 ? '' : ':${two(minutes)}'}';
}
