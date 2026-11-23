import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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