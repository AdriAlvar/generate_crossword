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
    final colors = Theme.of(context).colorScheme;
    final textStyle = DefaultTextStyle.of(context).style;
    final border = Border(
      right: BorderSide(color: colors.outlineVariant),
      bottom: BorderSide(color: colors.outlineVariant),
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
          child: Consumer(
            builder: (context, ref, _) {
              final cell = ref.watch(
                providers.workQueueProvider.select((state) {
                  final queue = state.asData?.value;
                  return (
                    letter: queue?.crossword.characters[location]?.character,
                    open: queue?.locationsToTry.containsKey(location) ?? false,
                  );
                }),
              );
              return AnimatedContainer(
                alignment: Alignment.center,
                duration: Durations.extralong1,
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: cell.open ? colors.primary : colors.onPrimary,
                  border: border,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: Durations.extralong1,
                  curve: Curves.easeInOut,
                  style: textStyle.copyWith(
                    color: cell.open ? colors.onPrimary : colors.primary,
                  ),
                  child: Text(cell.letter ?? ''),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
