import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Component children/slot duplication', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('component with only children should not duplicate into default slot', () {
      final result = parser.parse('<x-alert>Hello world</x-alert>');
      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;

      // A default slot should be created with the children
      expect(component.slots.containsKey('default'), isTrue);
      expect(component.slots['default']!.children, isNotEmpty);

      // Children should be empty since content was moved to the default slot
      expect(
        component.children,
        isEmpty,
        reason: 'Children should be empty when content is in default slot',
      );

      // Verify no duplication: content is ONLY in the default slot
      final hasChildrenAndSlot = component.children.isNotEmpty &&
          component.slots['default']!.children.isNotEmpty;
      expect(
        hasChildrenAndSlot,
        isFalse,
        reason: 'Content should be in children OR default slot, not both',
      );
    });

    test('component with named slots should have children separate from slots', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:header>Title</x-slot:header>
          <p>Body content</p>
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;

      // Named slot 'header' should exist
      expect(component.slots.containsKey('header'), isTrue);

      // Non-slot children (like <p>) should only be in children, not duplicated
      final nonSlotChildren = component.children.where((c) => c is! SlotNode);
      expect(nonSlotChildren, isNotEmpty);
    });
  });
}
