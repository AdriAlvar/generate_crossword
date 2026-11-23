import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';

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

  factory CrosswordCharacter([void Function(CrosswordCharacterBuilder)? updates]) =
      _$CrosswordCharacter;

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

  Crossword addWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    final length = word.characters.length;
    final endX = location.x + (direction == Direction.across ? length : 1);
    final endY = location.y + (direction == Direction.down ? length : 1);
    if (length == 0 || location.x < 0 || location.y < 0 ||
        endX > width || endY > height) {
      throw ArgumentError('La palabra debe caber dentro del tablero.');
    }
    final entry = CrosswordWord.word(
      word: word,
      location: location,
      direction: direction,
    );
    return rebuild((b) => b.words.add(entry));
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

class _DirectionSerializer implements PrimitiveSerializer<Direction> {
  @override
  Iterable<Type> get types => const [Direction];

  @override
  String get wireName => 'Direction';

  @override
  Object serialize(Serializers serializers, Direction value,
          {FullType specifiedType = FullType.unspecified}) =>
      value.name;

  @override
  Direction deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Direction.values.byName(serialized as String);
}

@SerializersFor([Location, CrosswordWord, CrosswordCharacter, Crossword])
final Serializers serializers =
    (_$serializers.toBuilder()..add(_DirectionSerializer())).build();
