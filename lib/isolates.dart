import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';

typedef _Batch = ({Crossword board, List<String> words});

// Solo pasan datos del crucigrama a compute. Riverpod queda en la interfaz.
Crossword? _tryBatch(_Batch batch) {
  final board = batch.board;
  final random = Random();
  for (final word in batch.words) {
    // El proveedor normaliza el diccionario a letras ASCII.
    final across =
        word.length > board.height ||
        (word.length <= board.width && random.nextBool());
    final xCount = board.width - (across ? word.length : 1) + 1;
    final yCount = board.height - (across ? 1 : word.length) + 1;
    final candidate = board.addWord(
      word: word,
      direction: across ? Direction.across : Direction.down,
      location: Location.at(random.nextInt(xCount), random.nextInt(yCount)),
    );
    if (candidate != null) return candidate;
  }
  return null;
}

Stream<Crossword> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
  bool Function()? isActive,
}) async* {
  var board = crossword;
  yield board;
  final longest = max(board.width, board.height);
  final pool = wordList
      .where((word) => word.isNotEmpty && word.length <= longest)
      .toList();
  if (pool.isEmpty) return;

  final random = Random();
  final target = (board.width * board.height * 0.8).ceil();
  while (board.characters.length < target && (isActive?.call() ?? true)) {
    final sample = List.generate(256, (_) => pool[random.nextInt(pool.length)]);
    final next = await compute(_tryBatch, (board: board, words: sample));
    if (!(isActive?.call() ?? true)) return;
    if (next != null) {
      board = next;
      yield board;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
