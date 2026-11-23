import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';

class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({super.key, required this.board, required this.cellBuilder});
  final Crossword board;
  final Widget Function(Location) cellBuilder;

  @override
  Widget build(BuildContext context) {
    const span = TableSpan(extent: FixedTableSpanExtent(40));
    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      rowCount: board.height,
      columnCount: board.width,
      columnBuilder: (_) => span,
      rowBuilder: (_) => span,
      cellBuilder: (_, v) =>
          TableViewCell(child: cellBuilder(Location.at(v.column, v.row))),
    );
  }
}
