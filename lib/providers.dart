import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show compute;
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

const backgroundWorkerCount = 4;

@riverpod
Stream<model.WorkQueue> workQueue(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final dictionary = await ref.watch(wordListProvider.future);
  if (!ref.mounted) return;
  yield* exploreCrosswordSolutions(
    crossword: model.Crossword.crossword(
      width: size.width,
      height: size.height,
    ),
    wordList: dictionary,
    maxWorkerCount: backgroundWorkerCount,
    isActive: () => ref.mounted,
  );
}

model.CrosswordPuzzleGame _puzzleFromCrosswordTrampoline(
  (model.Crossword, BuiltSet<String>) args,
) =>
    model.CrosswordPuzzleGame.from(crossword: args.$1, candidateWords: args.$2);

typedef _Move = ({
  model.CrosswordPuzzleGame game,
  model.Location location,
  model.Direction direction,
  String word,
});

model.CrosswordPuzzleGame? _puzzleSelectWordTrampoline(_Move move) =>
    move.game.selectWord(
      location: move.location,
      direction: move.direction,
      word: move.word,
    );

@riverpod
class Puzzle extends _$Puzzle {
  @override
  Future<model.CrosswordPuzzleGame?> build() async {
    final queue = ref.watch(workQueueProvider).asData?.value;
    if (queue == null || !queue.isCompleted) return null;
    return compute(_puzzleFromCrosswordTrampoline, (
      queue.crossword,
      queue.candidateWords,
    ));
  }

  Future<void> selectWord(
    model.Location location,
    model.Direction direction,
    String word,
  ) async {
    final session = ref;
    while (session.mounted) {
      final game = state.asData?.value;
      if (game == null || game.solved) return;
      final next = await compute(_puzzleSelectWordTrampoline, (
        game: game,
        location: location,
        direction: direction,
        word: word,
      ));
      if (!session.mounted) return;
      if (!identical(game, state.asData?.value)) continue;
      if (next != null) state = AsyncData(next);
      return;
    }
  }
}
