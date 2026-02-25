import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('AttributeNode positions', () {
    test('StandardAttribute has source positions', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container">content</div>');

      final element = result.ast!.children.whereType<HtmlElementNode>().first;
      final attr = element.attributes['class']!;

      expect(attr.startPosition, isNotNull);
      expect(attr.endPosition, isNotNull);
      // class starts after '<div '
      expect(attr.startPosition.offset, greaterThan(0));
    });

    test('AlpineAttribute has source positions', () {
      final parser = BladeParser();
      final result =
          parser.parse('<div x-data="{ open: false }">content</div>');

      final element = result.ast!.children.whereType<HtmlElementNode>().first;
      final attr = element.attributes['x-data']!;

      expect(attr.startPosition, isNotNull);
      expect(attr.endPosition, isNotNull);
    });

    test('LivewireAttribute has source positions', () {
      final parser = BladeParser();
      final result =
          parser.parse('<button wire:click="save">Save</button>');

      final element = result.ast!.children.whereType<HtmlElementNode>().first;
      final attr = element.attributes['wire:click']!;

      expect(attr.startPosition, isNotNull);
      expect(attr.endPosition, isNotNull);
    });

    test('Component attribute has source positions', () {
      final parser = BladeParser();
      final result = parser.parse('<x-alert type="error">Msg</x-alert>');

      final component = result.ast!.children.whereType<ComponentNode>().first;
      final attr = component.attributes['type']!;

      expect(attr.startPosition, isNotNull);
      expect(attr.endPosition, isNotNull);
    });

    test('attribute positions are included in toJson', () {
      final parser = BladeParser();
      final result = parser.parse('<div id="test">content</div>');

      final element = result.ast!.children.whereType<HtmlElementNode>().first;
      final attr = element.attributes['id']!;
      final json = attr.toJson();

      expect(json.containsKey('position'), isTrue);
      expect(json['position']['start'], isNotNull);
      expect(json['position']['end'], isNotNull);
    });
  });
}
