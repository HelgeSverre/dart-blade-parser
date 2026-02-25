import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Duplicate attribute handling', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('duplicate HTML attributes: last value wins', () {
      final result = parser.parse('<div class="first" class="second"></div>');
      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().first;
      // Map-based storage means only one 'class' key exists
      expect(div.attributes.length, equals(1));
      // The last occurrence wins
      expect(div.attributes['class']!.value, equals('second'));
    });

    test('duplicate component attributes: last value wins', () {
      final result = parser.parse('<x-alert type="info" type="danger" />');
      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes.length, equals(1));
      expect(component.attributes['type']!.value, equals('danger'));
    });

    test('different attribute names are preserved', () {
      final result =
          parser.parse('<div id="main" class="container" data-x="1"></div>');
      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().first;
      expect(div.attributes.length, equals(3));
      expect(div.attributes.containsKey('id'), isTrue);
      expect(div.attributes.containsKey('class'), isTrue);
      expect(div.attributes.containsKey('data-x'), isTrue);
    });
  });
}
