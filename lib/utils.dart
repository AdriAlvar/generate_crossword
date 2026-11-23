import 'dart:math';

import 'package:built_collection/built_collection.dart';

final _random = Random();

extension RandomElements<E> on BuiltSet<E> {
  E randomElement() {
    if (isEmpty) throw StateError('El conjunto está vacío.');
    return elementAt(_random.nextInt(length));
  }
}

extension DurationFormat on Duration {
  String get formatted {
    final hours = inHours.remainder(24);
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    return switch ((inDays, hours, minutes)) {
      (0, 0, 0) => '${seconds}s',
      (0, 0, _) => '$minutes:${two(seconds)}',
      (0, _, _) => '$hours:${two(minutes)}:${two(seconds)}',
      _ => '${inDays}d ${two(hours)}:${two(minutes)}:${two(seconds)}',
    };
  }
}
