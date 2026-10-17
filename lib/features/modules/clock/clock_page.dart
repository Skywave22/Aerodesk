import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/clock_service.dart';
import '../../../core/utils/formatting.dart';
import 'clock_face.dart';
import 'stopwatch_panel.dart';

/// Clock module: world clocks, stopwatch and countdown timer.
class ClockPage extends ConsumerWidget {
  const ClockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Widget>[
              Tab(text: 'Clock'),
              Tab(text: 'Stopwatch'),
              Tab(text: 'Timer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _ClockTab(now: now, use24Hour: use24Hour),
                const StopwatchPanel(),
                const TimerPanel(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Fixed UTC offsets · daylight saving is not applied',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockTab extends StatelessWidget {
  const _ClockTab({required this.now, required this.use24Hour});

  final DateTime now;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              ClockFace(dateTime: now),
              const SizedBox(height: 12),
              Text(formatTimeOfDay(now, use24Hour: use24Hour), style: theme.textTheme.headlineSmall),
              Text(
                formatDesktopDate(now),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('World clock', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final clock in kWorldClocks)
          ListTile(
            dense: true,
            leading: const Icon(Icons.public),
            title: Text(clock.city),
            subtitle: Text('${clock.country} · ${formatUtcOffset(clock)}'),
            trailing: Text(
              formatTimeOfDay(clock.timeFor(now), use24Hour: use24Hour),
              style: theme.textTheme.titleMedium,
            ),
          ),
      ],
    );
  }
}

/// Countdown timer with presets.
class TimerPanel extends StatefulWidget {
  const TimerPanel({super.key});

  @override
  State<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends State<TimerPanel> {
  static const List<int> _presets = <int>[1, 3, 5, 10, 25];

  Duration _remaining = const Duration(minutes: 5);
  Timer? _ticker;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running || _remaining <= Duration.zero) return;
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          _running = false;
          _ticker?.cancel();
          return;
        }
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _remaining = const Duration(minutes: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${two(minutes)}:${two(seconds)}',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _running ? _pause : _start,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Start'),
              ),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Presets', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (minutes) => ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _remaining.inMinutes == minutes && !_running,
                    onSelected: (_) {
                      _ticker?.cancel();
                      setState(() {
                        _running = false;
                        _remaining = Duration(minutes: minutes);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
