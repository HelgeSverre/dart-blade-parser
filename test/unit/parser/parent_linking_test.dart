import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Parent linking', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('document node has null parent', () {
      final result = parser.parse('<div>hello</div>');
      expect(result.ast!.parent, isNull);
    });

    test('top-level children have document as parent', () {
      final result = parser.parse('<div>hello</div>');
      for (final child in result.ast!.children) {
        expect(child.parent, equals(result.ast));
      }
    });

    test('nested directive children have directive as parent', () {
      final result = parser.parse('@if(\$cond)\nhello\n@endif');
      final directive = result.ast!.children.whereType<DirectiveNode>().first;

      for (final child in directive.children) {
        expect(child.parent, equals(directive));
      }
    });

    test('component children have component as parent', () {
      final result = parser.parse('<x-alert>Content</x-alert>');
      final component = result.ast!.children.whereType<ComponentNode>().first;

      // Check slot children
      for (final slot in component.slots.values) {
        for (final child in slot.children) {
          expect(child.parent, equals(slot));
        }
      }
    });

    test('html element children have element as parent', () {
      final result = parser.parse('<div><span>text</span></div>');
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      for (final child in div.children) {
        expect(child.parent, equals(div));
      }
    });
  });
}
