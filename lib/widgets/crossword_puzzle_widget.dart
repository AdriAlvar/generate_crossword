import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../model.dart';
import '../providers.dart' as providers;
import 'puzzle_grid.dart';

class CrosswordPuzzleWidget extends ConsumerWidget {
  const CrosswordPuzzleWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(providers.puzzleProvider).asData?.value;
    if (game == null) return const Center(child: CircularProgressIndicator());
    final colors = Theme.of(context).colorScheme;
    final placed = game.crosswordFromSelectedWords;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Tocá una casilla para elegir una palabra. Elegila otra vez para quitarla.  '
            '${game.selectedWords.length}/${game.crossword.words.length}',
          ),
        ),
        Expanded(
          child: PuzzleGrid(
            board: game.crossword,
            cellBuilder: (p) {
              final square = game.crossword.characters[p];
              if (square == null) return const SizedBox.shrink();
              return MenuAnchor(
                menuChildren: [
                  for (final slot in [
                    square.acrossWord,
                    square.downWord,
                  ].nonNulls)
                    for (final word in ([
                      slot.word,
                      ...?game.alternateWords[slot.location]?[slot.direction],
                    ]..sort()))
                      _WordSelectMenuItem(slot: slot, word: word),
                ],
                builder: (context, controller, _) => Material(
                  color: colors.surfaceContainerHigh,
                  shape: Border.all(color: colors.outlineVariant),
                  child: InkWell(
                    key: ValueKey(p),
                    onTap: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    child: Center(
                      child: Text(placed.characters[p]?.character ?? '•'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WordSelectMenuItem extends ConsumerWidget {
  const _WordSelectMenuItem({required this.slot, required this.word});
  final CrosswordWord slot;
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      providers.puzzleProvider.select((result) {
        final game = result.asData?.value;
        final cell = game?.crosswordFromSelectedWords.characters[slot.location];
        final current = slot.direction == Direction.across
            ? cell?.acrossWord
            : cell?.downWord;
        return (
          enabled:
              game?.canSelectWord(
                location: slot.location,
                direction: slot.direction,
                word: word,
              ) ??
              false,
          selected: current?.word == word,
        );
      }),
    );
    final notifier = ref.read(providers.puzzleProvider.notifier);
    return MenuItemButton(
      leadingIcon: Icon(
        slot.direction == Direction.across
            ? Icons.arrow_forward
            : Icons.arrow_downward,
        semanticLabel: slot.direction == Direction.across
            ? 'Horizontal'
            : 'Vertical',
      ),
      trailingIcon: status.selected ? const Icon(Icons.check) : null,
      onPressed: status.enabled
          ? () => notifier.selectWord(slot.location, slot.direction, word)
          : null,
      child: Text(word),
    );
  }
}
