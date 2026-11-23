import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';

class CrosswordGeneratorApp extends ConsumerWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(wordListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crossword Generator')),
      body: resultado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error al cargar el diccionario: $error'),
        ),
        data: (diccionario) {
          final palabras = diccionario.toList(growable: false);

          return ListView.builder(
            itemCount: palabras.length,
            itemBuilder: (context, indice) {
              return ListTile(title: Text(palabras[indice]));
            },
          );
        },
      ),
    );
  }
}