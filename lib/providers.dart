import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'model.dart' as model;
import 'utils.dart';

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
Stream<model.Crossword> crossword(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final dictionary = await ref.watch(wordListProvider.future);
  if (!ref.mounted) return;

  final longest = max(size.width, size.height);
  final candidates = BuiltSet<String>.of(
    dictionary.where((word) => word.length <= longest),
  );
  if (candidates.isEmpty) {
    throw StateError('El diccionario no contiene palabras que quepan.');
  }

  final random = Random();
  var board = model.Crossword.crossword(width: size.width, height: size.height);
  final target = (size.width * size.height * 0.8).ceil();
  yield board;

  while (board.characters.length < target) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!ref.mounted) return;

    final word = candidates.randomElement();
    final across =
        word.length > size.height ||
        (word.length <= size.width && random.nextBool());
    final xCount = across ? size.width - word.length + 1 : size.width;
    final yCount = across ? size.height : size.height - word.length + 1;
    board = board.addWord(
      location: model.Location.at(
        random.nextInt(xCount),
        random.nextInt(yCount),
      ),
      word: word,
      direction: across ? model.Direction.across : model.Direction.down,
    );
    yield board;
  }
}
