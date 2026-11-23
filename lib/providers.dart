import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
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
Stream<model.Crossword> crossword(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final dictionary = await ref.watch(wordListProvider.future);
  if (!ref.mounted) return;

  yield* exploreCrosswordSolutions(
    crossword: model.Crossword.crossword(
      width: size.width,
      height: size.height,
    ),
    wordList: dictionary,
    isActive: () => ref.mounted,
  );
}
