import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/formatting.dart';

/// Stopwatch panel with lap times.
class StopwatchPanel extends StatefulWidget {
  const StopwatchPanel({super.key});

  @override
  State<StopwatchPanel> createState() => _StopwatchPanelState();
}

class _StopwatchPanelState extends State<StopwatchPanel> {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = <Duration>[];
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 31), (_) {
      if (mounted) setState(() {});
    });
  }

  void _toggle() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
      } else {
        _stopwatch.start();
        _ensureTicker();
      }
    });
  }

  void _lap() {
    if (!_stopwatch.isRunning) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  void _reset() {
    setState(() {
      _stopwatch.reset();
      _laps.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elapsed = _stopwatch.elapsed;
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          formatStopwatch(elapsed),
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_stopwatch.isRunning ? 'Stop' : 'Start'),
            ),
            OutlinedButton.icon(
              onPressed: _lap,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Lap'),
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_laps.isNotEmpty)
          Expanded(
            child: ListView.separated(
              itemCount: _laps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lap = _laps[index];
                final previous = index + 1 < _laps.length ? _laps[index + 1] : Duration.zero;
                return ListTile(
                  dense: true,
                  leading: Text('${_laps.length - index}'),
                  title: Text(formatStopwatch(lap)),
                  trailing: Text(formatStopwatch(lap - previous)),
                );
              },
            ),
          )
        else
          const Spacer(),
      ],
    );
  }
}
