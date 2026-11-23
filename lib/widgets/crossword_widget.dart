import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';
import '../providers.dart' as providers;

class CrosswordWidget extends ConsumerWidget {
  const CrosswordWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(providers.sizeProvider);
    final status = ref.watch(
      providers.workQueueProvider.select(
        (state) => (ready: state.hasValue, error: state.error),
      ),
    );
    if (status.error != null) {
      return Center(child: Text('Error al crear el tablero: ${status.error}'));
    }
    if (!status.ready) {
      return const Center(child: CircularProgressIndicator());
    }

    const span = TableSpan(extent: FixedTableSpanExtent(32));
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final cellStyle = BoxDecoration(
      border: Border(
        right: BorderSide(color: outline),
        bottom: BorderSide(color: outline),
      ),
    );
    return TableView.builder(
      key: ValueKey(size),
      diagonalDragBehavior: DiagonalDragBehavior.free,
      columnCount: size.width,
      rowCount: size.height,
      columnBuilder: (_) => span,
      rowBuilder: (_) => span,
      cellBuilder: (context, vicinity) {
        final location = Location.at(vicinity.column, vicinity.row);
        return TableViewCell(
          child: DecoratedBox(
            decoration: cellStyle,
            child: Consumer(
              builder: (context, ref, _) {
                final letter = ref.watch(
                  providers.workQueueProvider.select(
                    (state) => state
                        .asData
                        ?.value
                        .crossword
                        .characters[location]
                        ?.character,
                  ),
                );
                return Center(child: Text(letter ?? ''));
              },
            ),
          ),
        );
      },
    );
  }
}
