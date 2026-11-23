import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';
import 'package:intl/intl.dart';

part 'model.g.dart';

abstract class Location implements Built<Location, LocationBuilder> {
  int get x;
  int get y;

  static Serializer<Location> get serializer => _$locationSerializer;

  Location._();

  factory Location([void Function(LocationBuilder)? updates]) = _$Location;

  factory Location.at(int x, int y) {
    return Location((b) {
      b.x = x;
      b.y = y;
    });
  }

  Location get left => leftOffset(1);
  Location get right => rightOffset(1);
  Location get up => upOffset(1);
  Location get down => downOffset(1);

  Location leftOffset(int n) => Location.at(x - n, y);
  Location rightOffset(int n) => Location.at(x + n, y);
  Location upOffset(int n) => Location.at(x, y - n);
  Location downOffset(int n) => Location.at(x, y + n);

  String prettyPrint() => '($x, $y)';
}

enum Direction {
  across,
  down;

  Location offsetFrom(Location start, int offset) => this == Direction.across
      ? start.rightOffset(offset)
      : start.downOffset(offset);

  @override
  String toString() => name;
}

abstract class CrosswordWord
    implements Built<CrosswordWord, CrosswordWordBuilder> {
  String get word;
  Location get location;
  Direction get direction;

  static Serializer<CrosswordWord> get serializer => _$crosswordWordSerializer;

  CrosswordWord._();

  factory CrosswordWord([void Function(CrosswordWordBuilder)? updates]) =
      _$CrosswordWord;

  factory CrosswordWord.word({
    required String word,
    required Location location,
    required Direction direction,
  }) {
    return CrosswordWord((b) {
      b.word = word;
      b.location.replace(location);
      b.direction = direction;
    });
  }

  static int locationComparator(CrosswordWord a, CrosswordWord b) {
    final fila = a.location.y.compareTo(b.location.y);
    if (fila != 0) return fila;

    final columna = a.location.x.compareTo(b.location.x);
    if (columna != 0) return columna;

    return a.direction.index.compareTo(b.direction.index);
  }
}

abstract class CrosswordCharacter
    implements Built<CrosswordCharacter, CrosswordCharacterBuilder> {
  String get character;
  CrosswordWord? get acrossWord;
  CrosswordWord? get downWord;

  static Serializer<CrosswordCharacter> get serializer =>
      _$crosswordCharacterSerializer;

  CrosswordCharacter._();

  factory CrosswordCharacter([
    void Function(CrosswordCharacterBuilder)? updates,
  ]) = _$CrosswordCharacter;

  factory CrosswordCharacter.character({
    required String character,
    CrosswordWord? acrossWord,
    CrosswordWord? downWord,
  }) {
    return CrosswordCharacter((b) {
      b.character = character;
      b.acrossWord = acrossWord?.toBuilder();
      b.downWord = downWord?.toBuilder();
    });
  }
}

abstract class Crossword implements Built<Crossword, CrosswordBuilder> {
  int get width;
  int get height;
  BuiltList<CrosswordWord> get words;

  // Las casillas se calculan a partir de las palabras al construir el tablero.
  @BuiltValueField(serialize: false, compare: false)
  BuiltMap<Location, CrosswordCharacter> get characters;

  static Serializer<Crossword> get serializer => _$crosswordSerializer;

  Crossword._();

  factory Crossword([void Function(CrosswordBuilder)? updates]) = _$Crossword;

  factory Crossword.crossword({required int width, required int height}) {
    return Crossword((b) {
      b.width = width;
      b.height = height;
    });
  }

  bool get valid {
    if (width <= 0 || height <= 0) return false;
    final seenWords = <String>{};
    for (final entry in words) {
      if (entry.word.isEmpty || !seenWords.add(entry.word)) return false;
      for (final (offset, letter) in entry.word.characters.indexed) {
        final location = entry.direction.offsetFrom(entry.location, offset);
        final cell = characters[location];
        if (cell == null || cell.character != letter) return false;
        final owner = entry.direction == Direction.across
            ? cell.acrossWord
            : cell.downWord;
        if (owner != entry) return false;
      }
    }

    for (final item in characters.entries) {
      final p = item.key;
      final cell = item.value;
      if (p.x < 0 || p.x >= width || p.y < 0 || p.y >= height) return false;
      if (cell.acrossWord == null && cell.downWord == null) return false;
      final right = characters[p.right];
      if (right != null &&
          (cell.acrossWord == null || cell.acrossWord != right.acrossWord)) {
        return false;
      }
      final below = characters[p.down];
      if (below != null &&
          (cell.downWord == null || cell.downWord != below.downWord)) {
        return false;
      }
    }

    // Una sola red: desde la primera letra se puede llegar a todas las demás.
    if (characters.isEmpty) return true;
    final first = characters.keys.first;
    final reached = <Location>{first};
    final pending = [first];
    while (pending.isNotEmpty) {
      final p = pending.removeLast();
      for (final neighbor in [p.left, p.right, p.up, p.down]) {
        if (characters.containsKey(neighbor) && reached.add(neighbor)) {
          pending.add(neighbor);
        }
      }
    }
    return reached.length == characters.length;
  }

  Crossword? addWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    final letters = word.characters;
    if (letters.isEmpty || words.any((entry) => entry.word == word)) {
      return null;
    }
    final last = direction.offsetFrom(location, letters.length - 1);
    if (location.x < 0 ||
        location.y < 0 ||
        last.x >= width ||
        last.y >= height) {
      return null;
    }
    if (characters.containsKey(direction.offsetFrom(location, -1)) ||
        characters.containsKey(direction.offsetFrom(last, 1))) {
      return null;
    }

    final across = direction == Direction.across;
    var crosses = false;
    for (final (offset, letter) in letters.indexed) {
      final p = direction.offsetFrom(location, offset);
      final cell = characters[p];
      if (cell == null) {
        if (characters.containsKey(across ? p.up : p.left) ||
            characters.containsKey(across ? p.down : p.right)) {
          return null;
        }
      } else {
        if (cell.character != letter ||
            (across ? cell.acrossWord : cell.downWord) != null) {
          return null;
        }
        crosses = true;
      }
    }
    if (words.isNotEmpty && !crosses) return null;
    final entry = CrosswordWord.word(
      word: word,
      location: location,
      direction: direction,
    );
    final next = rebuild((b) => b.words.add(entry));
    return next.valid ? next : null;
  }

  @BuiltValueHook(finalizeBuilder: true)
  static void _fillCharacters(CrosswordBuilder b) {
    b.characters.clear();
    for (final entry in b.words.build()) {
      final horizontal = entry.direction == Direction.across;
      for (final (offset, letter) in entry.word.characters.indexed) {
        final cell = horizontal
            ? entry.location.rightOffset(offset)
            : entry.location.downOffset(offset);
        final previous = b.characters[cell];
        b.characters[cell] = CrosswordCharacter.character(
          character: previous?.character ?? letter,
          acrossWord: horizontal ? entry : previous?.acrossWord,
          downWord: horizontal ? previous?.downWord : entry,
        );
      }
    }
  }

  String prettyPrintCrossword() {
    final rows = <String>[];
    for (var y = 0; y < height; y++) {
      final row = StringBuffer();
      for (var x = 0; x < width; x++) {
        row.write(characters[Location.at(x, y)]?.character ?? '.');
      }
      rows.add(row.toString());
    }
    return rows.join('\n');
  }
}

abstract class WorkQueue implements Built<WorkQueue, WorkQueueBuilder> {
  Crossword get crossword;
  BuiltMap<Location, Direction> get locationsToTry;
  BuiltSet<Location> get badLocations;
  BuiltSet<String> get candidateWords;
  bool get isCompleted => locationsToTry.isEmpty || candidateWords.isEmpty;

  static Serializer<WorkQueue> get serializer => _$workQueueSerializer;

  WorkQueue._();

  factory WorkQueue([void Function(WorkQueueBuilder)? updates]) = _$WorkQueue;

  static WorkQueue from({
    required Crossword crossword,
    required Iterable<String> candidateWords,
    required Location startLocation,
  }) {
    final longest = crossword.width > crossword.height
        ? crossword.width
        : crossword.height;
    return WorkQueue((b) {
      b.crossword.replace(crossword);
      b.candidateWords.addAll(
        candidateWords.where(
          (word) => word.isNotEmpty && word.length <= longest,
        ),
      );
      for (final entry in crossword.words) {
        b.candidateWords.remove(entry.word);
      }
      if (crossword.words.isEmpty) {
        if (_inside(crossword, startLocation)) {
          b.locationsToTry[startLocation] = Direction.across;
        }
      } else {
        b.locationsToTry.addAll(_openLocations(crossword));
      }
    });
  }

  WorkQueue remove(Location location) => rebuild((b) {
    b.locationsToTry.remove(location);
    b.badLocations.add(location);
  });

  WorkQueue updateFrom(Crossword next) => rebuild((b) {
    b.crossword.replace(next);
    for (final entry in next.words) {
      if (candidateWords.contains(entry.word)) {
        b.candidateWords.remove(entry.word);
      }
    }
    b.locationsToTry.clear();
    for (final entry in _openLocations(next).entries) {
      if (!badLocations.contains(entry.key)) {
        b.locationsToTry[entry.key] = entry.value;
      }
    }
  });

  static bool _inside(Crossword board, Location p) =>
      p.x >= 0 && p.x < board.width && p.y >= 0 && p.y < board.height;

  static Map<Location, Direction> _openLocations(Crossword board) {
    final result = <Location, Direction>{};
    for (final entry in board.characters.entries) {
      final cell = entry.value;
      final direction = switch ((cell.acrossWord, cell.downWord)) {
        (null, CrosswordWord()) => Direction.across,
        (CrosswordWord(), null) => Direction.down,
        _ => null,
      };
      if (direction == null) continue;
      for (final delta in const [-1, 1]) {
        final step = direction.offsetFrom(entry.key, delta);
        if (!_inside(board, step)) continue;
        final across = direction == Direction.across;
        if (!board.characters.containsKey(across ? step.up : step.left) &&
            !board.characters.containsKey(across ? step.down : step.right)) {
          result[entry.key] = direction;
          break;
        }
      }
    }
    return result;
  }
}

abstract class DisplayInfo implements Built<DisplayInfo, DisplayInfoBuilder> {
  String get wordsInGridCount;
  String get candidateWordsCount;
  String get locationsToExploreCount;
  String get knownBadLocationsCount;
  double get gridFilledPercentage;

  static final _numbers = NumberFormat.decimalPattern('es_PY');
  static Serializer<DisplayInfo> get serializer => _$displayInfoSerializer;
  static final DisplayInfo empty = DisplayInfo(
    (b) => b
      ..wordsInGridCount = '0'
      ..candidateWordsCount = '0'
      ..locationsToExploreCount = '0'
      ..knownBadLocationsCount = '0'
      ..gridFilledPercentage = 0,
  );

  DisplayInfo._();
  factory DisplayInfo([void Function(DisplayInfoBuilder)? updates]) =
      _$DisplayInfo;

  factory DisplayInfo.from({required WorkQueue workQueue}) {
    final board = workQueue.crossword;
    final area = board.width * board.height;
    return DisplayInfo(
      (b) => b
        ..wordsInGridCount = _numbers.format(board.words.length)
        ..candidateWordsCount = _numbers.format(workQueue.candidateWords.length)
        ..locationsToExploreCount = _numbers.format(
          workQueue.locationsToTry.length,
        )
        ..knownBadLocationsCount = _numbers.format(
          workQueue.badLocations.length,
        )
        ..gridFilledPercentage = area == 0
            ? 0
            : 100 * board.characters.length / area,
    );
  }
}

class _DirectionSerializer implements PrimitiveSerializer<Direction> {
  @override
  Iterable<Type> get types => const [Direction];

  @override
  String get wireName => 'Direction';

  @override
  Object serialize(
    Serializers serializers,
    Direction value, {
    FullType specifiedType = FullType.unspecified,
  }) => value.name;

  @override
  Direction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Direction.values.byName(serialized as String);
}

@SerializersFor([
  Location,
  CrosswordWord,
  CrosswordCharacter,
  Crossword,
  WorkQueue,
  DisplayInfo,
])
final Serializers serializers =
    (_$serializers.toBuilder()..add(_DirectionSerializer())).build();
