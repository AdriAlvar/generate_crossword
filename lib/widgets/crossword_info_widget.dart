import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../providers.dart' as providers;
import '../utils.dart';
import 'ticker_builder.dart';

class CrosswordInfoWidget extends ConsumerWidget {
  const CrosswordInfoWidget({super.key});

  static final _percentage = NumberFormat.decimalPercentPattern(
    locale: 'es_PY',
    decimalDigits: 2,
  );

  static String _time(Duration duration) => duration.inSeconds == 0
      ? '${duration.inMilliseconds} ms'
      : duration.formatted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(providers.displayInfoProvider);
    final size = ref.watch(providers.sizeProvider);
    final workers = ref.watch(providers.workerCountProvider);
    final start = ref.watch(providers.startTimeProvider);
    final end = ref.watch(providers.endTimeProvider);
    final remaining = ref.watch(providers.expectedRemainingTimeProvider);

    return Align(
      alignment: Alignment.bottomRight,
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuadrícula: ${size.label}'),
                Text('Máximo de trabajadores: ${workers.count}'),
                Text('Palabras colocadas: ${info.wordsInGridCount}'),
                Text('Palabras candidatas: ${info.candidateWordsCount}'),
                Text('Cruces por explorar: ${info.locationsToExploreCount}'),
                Text('Posiciones descartadas: ${info.knownBadLocationsCount}'),
                Text(
                  'Ocupación: ${_percentage.format(info.gridFilledPercentage / 100)}',
                ),
                if (start == null)
                  const Text('Cargando el diccionario…')
                else if (end != null)
                  Text('Tiempo final: ${_time(end.difference(start))}')
                else ...[
                  TickerBuilder(
                    builder: (_) => Text(
                      'Tiempo transcurrido: ${_time(DateTime.now().difference(start))}',
                    ),
                  ),
                  Text(
                    'Tiempo restante estimado: ${remaining > Duration.zero ? _time(remaining) : '—'}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
