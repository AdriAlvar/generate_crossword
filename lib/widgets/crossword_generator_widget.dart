import 'package:material_ui/material_ui.dart';

import '../model.dart';
import 'puzzle_grid.dart';

class CrosswordGeneratorWidget extends StatefulWidget {
  const CrosswordGeneratorWidget({super.key, required this.board});
  final Crossword board;
  @override
  State<CrosswordGeneratorWidget> createState() => _GenerationState();
}

class _GenerationState extends State<CrosswordGeneratorWidget>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);
  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Generando el crucigrama…'),
        ),
        Expanded(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(pulse),
            child: PuzzleGrid(
              board: widget.board,
              cellBuilder: (p) {
                return Center(
                  child: Text(
                    widget.board.characters.containsKey(p) ? '•' : '',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
