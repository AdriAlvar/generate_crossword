import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

typedef _Search = ({
  Crossword board,
  Location anchor,
  Direction direction,
  List<String> words,
});

Crossword? _tryAtAnchor(_Search search) {
  final board = search.board;
  final letter = board.characters[search.anchor]?.character;
  for (final word in search.words) {
    if (letter == null) {
      for (final direction in Direction.values) {
        final seed = board.addWord(
          location: search.anchor,
          word: word,
          direction: direction,
        );
        if (seed != null) return seed;
      }
    } else {
      // El diccionario está normalizado a ASCII; una letra ocupa una posición.
      for (
        var i = word.indexOf(letter);
        i >= 0;
        i = word.indexOf(letter, i + 1)
      ) {
        final start = search.direction.offsetFrom(search.anchor, -i);
        final candidate = board.addWord(
          location: start,
          word: word,
          direction: search.direction,
        );
        if (candidate != null) return candidate;
      }
    }
  }
  return null;
}

Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
  bool Function()? isActive,
}) async* {
  final elapsed = Stopwatch()..start();
  if (!(isActive?.call() ?? true)) return;

  var queue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );
  yield queue;
  final random = Random();
  // Un orden aleatorio por tablero. Cada búsqueda empieza en un índice distinto.
  final pool = queue.candidateWords.toList(growable: false)..shuffle(random);
  while (!queue.isCompleted) {
    if (!(isActive?.call() ?? true)) return;
    final options = queue.locationsToTry;
    final anchor = options.keys.elementAt(random.nextInt(options.length));
    final letter = queue.crossword.characters[anchor]?.character;
    final start = random.nextInt(pool.length);
    final batch = <String>[];
    for (var i = 0; i < pool.length && batch.length < 1000; i++) {
      final word = pool[(start + i) % pool.length];
      if (queue.candidateWords.contains(word) &&
          (letter == null || word.contains(letter))) {
        batch.add(word);
      }
    }
    final next = await compute(_tryAtAnchor, (
      board: queue.crossword,
      anchor: anchor,
      direction: options[anchor]!,
      words: batch,
    ));
    if (!(isActive?.call() ?? true)) return;
    if (next == null) {
      queue = queue.remove(anchor);
    } else {
      queue = queue.updateFrom(next);
    }
    yield queue;
  }
  elapsed.stop();
  debugPrint(
    'Generación terminada en ${elapsed.elapsed.formatted}. Palabras: ${queue.crossword.words.length}',
  );
}
