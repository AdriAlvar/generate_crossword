import 'package:material_ui/material_ui.dart';

class PuzzleCompletedWidget extends StatelessWidget {
  const PuzzleCompletedWidget({super.key, required this.onReplay});
  final VoidCallback onReplay;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¡Crucigrama resuelto!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onReplay,
            child: const Text('Jugar otra vez'),
          ),
        ],
      ),
    );
  }
}
