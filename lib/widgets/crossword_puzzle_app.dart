import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart' as p;
import 'crossword_generator_widget.dart';
import 'crossword_puzzle_widget.dart';
import 'puzzle_completed_widget.dart';

class CrosswordPuzzleApp extends ConsumerWidget {
  const CrosswordPuzzleApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(p.sizeProvider);
    final queue = ref.watch(p.workQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword Puzzle'),
        actions: [
          MenuAnchor(
            menuChildren: [
              for (final option in p.CrosswordSize.values)
                MenuItemButton(
                  onPressed: () =>
                      ref.read(p.sizeProvider.notifier).setSize(option),
                  child: Text(option.label),
                ),
            ],
            builder: (_, menu, _) => IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Tamaño del tablero (${size.label})',
              onPressed: () => menu.isOpen ? menu.close() : menu.open(),
            ),
          ),
        ],
      ),
      body: queue.when(
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error al generar: $error')),
        data: (q) => q.isCompleted
            ? const _Game()
            : CrosswordGeneratorWidget(board: q.crossword),
      ),
    );
  }
}

class _Game extends ConsumerWidget {
  const _Game();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      p.puzzleProvider.select(
        (s) => (
          ready: s.asData?.value != null,
          solved: s.asData?.value?.solved ?? false,
          error: s.error,
        ),
      ),
    );
    if (status.error != null) {
      return Center(
        child: Text('Error al preparar la partida: ${status.error}'),
      );
    }
    if (!status.ready) return const Center(child: CircularProgressIndicator());
    if (status.solved) {
      return PuzzleCompletedWidget(
        onReplay: () => ref.invalidate(p.workQueueProvider),
      );
    }
    return const CrosswordPuzzleWidget();
  }
}
