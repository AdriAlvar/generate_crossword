import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart' as providers;
import 'crossword_widget.dart';

class CrosswordGeneratorApp extends StatelessWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword Generator'),
        actions: const [_CrosswordGeneratorMenu()],
      ),
      body: const CrosswordWidget(),
    );
  }
}

class _CrosswordGeneratorMenu extends ConsumerWidget {
  const _CrosswordGeneratorMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(providers.sizeProvider);
    return MenuAnchor(
      menuChildren: [
        for (final size in providers.CrosswordSize.values)
          MenuItemButton(
            onPressed: () =>
                ref.read(providers.sizeProvider.notifier).setSize(size),
            child: Text(size.label),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Tamaño del tablero (${current.label})',
        icon: const Icon(Icons.settings),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
    );
  }
}
