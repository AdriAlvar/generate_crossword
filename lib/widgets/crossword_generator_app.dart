import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart' as providers;
import 'crossword_info_widget.dart';
import 'crossword_widget.dart';

class CrosswordGeneratorApp extends ConsumerWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showInfo = ref.watch(providers.showDisplayInfoProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword Generator'),
        actions: const [_CrosswordGeneratorMenu()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CrosswordWidget(),
          if (showInfo) const CrosswordInfoWidget(),
        ],
      ),
    );
  }
}

class _CrosswordGeneratorMenu extends ConsumerWidget {
  const _CrosswordGeneratorMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(providers.sizeProvider);
    final showInfo = ref.watch(providers.showDisplayInfoProvider);
    return MenuAnchor(
      menuChildren: [
        CheckboxMenuButton(
          value: showInfo,
          onChanged: (_) =>
              ref.read(providers.showDisplayInfoProvider.notifier).toggle(),
          child: const Text('Mostrar estadísticas'),
        ),
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
