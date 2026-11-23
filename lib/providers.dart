import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'model.dart' as model;
import 'isolates.dart';

part 'providers.g.dart';

@riverpod
Future<BuiltSet<String>> wordList(Ref ref) async {
  final texto = await rootBundle.loadString('assets/words.txt');
  final soloLetras = RegExp(r'^[a-z]+$');

  final palabras = const LineSplitter()
      .convert(texto)
      .map((linea) => linea.trim().toLowerCase())
      .where((palabra) => palabra.length >= 3 && soloLetras.hasMatch(palabra));

  return BuiltSet<String>(palabras);
}

enum CrosswordSize {
  small(20, 11),
  medium(40, 22),
  large(80, 44),
  xlarge(160, 88),
  xxlarge(500, 500);

  const CrosswordSize(this.width, this.height);

  final int width;
  final int height;
  String get label => '$width × $height';
}

@Riverpod(keepAlive: true)
class Size extends _$Size {
  @override
  CrosswordSize build() => CrosswordSize.medium;

  void setSize(CrosswordSize size) => state = size;
}

@riverpod
Stream<model.WorkQueue> workQueue(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final dictionary = await ref.watch(wordListProvider.future);
  if (!ref.mounted) return;

  ref.read(startTimeProvider.notifier).start();
  ref.read(endTimeProvider.notifier).reset();
  yield* exploreCrosswordSolutions(
    crossword: model.Crossword.crossword(
      width: size.width,
      height: size.height,
    ),
    wordList: dictionary,
    isActive: () => ref.mounted,
  );
  if (ref.mounted) ref.read(endTimeProvider.notifier).finish();
}

@Riverpod(keepAlive: true)
class StartTime extends _$StartTime {
  @override
  DateTime? build() {
    ref.watch(sizeProvider);
    return null;
  }

  void start() => state = DateTime.now();
}

@Riverpod(keepAlive: true)
class EndTime extends _$EndTime {
  @override
  DateTime? build() {
    ref.watch(sizeProvider);
    return null;
  }

  void reset() => state = null;
  void finish() => state = DateTime.now();
}

@Riverpod(keepAlive: true)
class ShowDisplayInfo extends _$ShowDisplayInfo {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

@riverpod
class DisplayInfo extends _$DisplayInfo {
  @override
  model.DisplayInfo build() => ref.watch(
    workQueueProvider.select((result) {
      final queue = result.asData?.value;
      return queue == null
          ? model.DisplayInfo.empty
          : model.DisplayInfo.from(workQueue: queue);
    }),
  );
}

const _estimatedTotalCoverage = 0.54;

@riverpod
Duration expectedRemainingTime(Ref ref) {
  final start = ref.watch(startTimeProvider);
  final end = ref.watch(endTimeProvider);
  final progress = ref.watch(
    displayInfoProvider.select((info) => info.gridFilledPercentage / 100),
  );
  if (start == null ||
      end != null ||
      progress <= 0 ||
      progress >= _estimatedTotalCoverage) {
    return Duration.zero;
  }
  final elapsed = DateTime.now().difference(start);
  if (elapsed.isNegative) return Duration.zero;
  final remaining =
      elapsed.inMicroseconds * (_estimatedTotalCoverage / progress - 1);
  return Duration(microseconds: remaining.round());
}
