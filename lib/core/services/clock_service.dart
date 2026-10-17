import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current time once per second.
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
