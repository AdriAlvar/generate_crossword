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

Iterable<CrosswordWord> _placements(_Search search) sync* {
  final letter = search.board.characters[search.anchor]?.character;
  for (final word in search.words) {
    if (letter == null) {
      for (final direction in Direction.values) {
        yield CrosswordWord.word(
          word: word,
          location: search.anchor,
          direction: direction,
        );
      }
    } else {
      for (
        var i = word.indexOf(letter);
        i >= 0;
        i = word.indexOf(letter, i + 1)
      ) {
        yield CrosswordWord.word(
          word: word,
          direction: search.direction,
          location: search.direction.offsetFrom(search.anchor, -i),
        );
      }
    }
  }
}

CrosswordWord? _generateCandidate(_Search search) {
  final clock = Stopwatch()..start();
  for (final move in _placements(search).take(1000)) {
    if (clock.elapsed >= const Duration(seconds: 10)) break;
    final trial = search.board.addWord(
      word: move.word,
      location: move.location,
      direction: move.direction,
    );
    if (trial != null) return move;
  }
  return null;
}

Future<WorkQueue> _generate((WorkQueue, int) request) async {
  final (queue, maxWorkers) = request;
  final random = Random();
  final options = queue.locationsToTry.keys.toList()..shuffle(random);
  final anchors = options.take(maxWorkers).toList(growable: false);
  final pool = queue.candidateWords.toList(growable: false)..shuffle(random);
  final tasks = <Future<CrosswordWord?>>[];
  for (final anchor in anchors) {
    final letter = queue.crossword.characters[anchor]?.character;
    final offset = random.nextInt(pool.length);
    final sample = <String>[];
    for (var i = 0; i < pool.length && sample.length < 1000; i++) {
      final word = pool[(offset + i) % pool.length];
      if (letter == null || word.contains(letter)) sample.add(word);
    }
    tasks.add(
      compute(_generateCandidate, (
        board: queue.crossword,
        anchor: anchor,
        direction: queue.locationsToTry[anchor]!,
        words: sample,
      )),
    );
  }

  final moves = await tasks.wait;
  var board = queue.crossword;
  final exhausted = <Location>[];
  for (final (i, move) in moves.indexed) {
    if (move == null) {
      exhausted.add(anchors[i]);
      continue;
    }
    // Una propuesta de otro trabajador ya puede haber ocupado este cruce.
    final updated = board.addWord(
      word: move.word,
      location: move.location,
      direction: move.direction,
    );
    if (updated != null) board = updated;
  }
  var next = identical(board, queue.crossword)
      ? queue
      : queue.updateFrom(board);
  for (final anchor in exhausted) {
    if (next.locationsToTry.containsKey(anchor)) next = next.remove(anchor);
  }
  return next;
}

Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
  required int maxWorkerCount,
  bool Function()? isActive,
}) async* {
  RangeError.checkValueInInterval(maxWorkerCount, 1, 128, 'maxWorkerCount');
  if (!(isActive?.call() ?? true)) return;
  final elapsed = Stopwatch()..start();
  var queue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );
  yield queue;
  while (!queue.isCompleted && (isActive?.call() ?? true)) {
    queue = await compute(_generate, (queue, maxWorkerCount));
    if (!(isActive?.call() ?? true)) return;
    yield queue;
  }
  if (!(isActive?.call() ?? true)) return;
  elapsed.stop();
  debugPrint(
    'Generación terminada en ${elapsed.elapsed.formatted}. Palabras: ${queue.crossword.words.length}',
  );
}
