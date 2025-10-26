import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for component slots (<x-slot:name> and <x-slot name="...">)
/// These tests EXPOSE bugs - slots are not currently parsed
void main() {
  group('Component Slots Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Named slot with colon syntax should create SlotNode', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:header>Card Title</x-slot:header>
          Card body content
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      // Find the component
      final component =
          result.ast!.children.whereType<ComponentNode>().firstWhere(
                (c) => c.name == 'card',
                orElse: () => throw Exception('x-card component not found'),
              );

      // CRITICAL: Component should have a 'header' slot
      // Current bug: Slots not recognized, likely treated as nested component
      expect(
        component.slots.containsKey('header'),
        isTrue,
        reason: '<x-slot:header> should create a slot named "header"',
      );

      final headerSlot = component.slots['header'];
      expect(headerSlot, isNotNull);
      expect(headerSlot, isA<SlotNode>());
      expect(headerSlot!.name, equals('header'));

      // Slot should have text content
      final textChildren = headerSlot.children.whereType<TextNode>();
      expect(textChildren.any((t) => t.content.contains('Card Title')), isTrue);
    });

    test('Named slot with attribute syntax should create SlotNode', () {
      final result = parser.parse('''
        <x-card>
          <x-slot name="footer">Footer content</x-slot>
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'card');

      // Should have 'footer' slot
      expect(
        component.slots.containsKey('footer'),
        isTrue,
        reason: '<x-slot name="footer"> should create slot',
      );

      final footerSlot = component.slots['footer'];
      expect(footerSlot, isNotNull);
      expect(footerSlot!.name, equals('footer'));
    });

    test('Multiple slots in component', () {
      final result = parser.parse('''
        <x-layout>
          <x-slot:header>Page Header</x-slot:header>
          <x-slot:footer>Page Footer</x-slot:footer>
          <p>Main body content</p>
        </x-layout>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'layout');

      // Should have 2 named slots
      expect(
        component.slots.length,
        equals(2),
        reason: 'Should have header and footer slots',
      );

      expect(component.slots.containsKey('header'), isTrue);
      expect(component.slots.containsKey('footer'), isTrue);

      // Should also have default content (the <p> tag)
      final nonSlotChildren = component.children
          .where((c) => c is! SlotNode)
          .whereType<HtmlElementNode>();
      expect(
        nonSlotChildren,
        isNotEmpty,
        reason: 'Non-slot content should be in component children',
      );
    });

    test('Slot with attributes', () {
      final result = parser.parse('''
        <x-alert>
          <x-slot:title class="font-bold" id="alert-title">Important</x-slot:title>
        </x-alert>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'alert');

      final titleSlot = component.slots['title'];
      expect(titleSlot, isNotNull);

      // Slot should have attributes
      expect(
        titleSlot!.attributes,
        isNotEmpty,
        reason: 'Slot should preserve its attributes',
      );

      expect(titleSlot.attributes.containsKey('class'), isTrue);
      expect(titleSlot.attributes['class']!.value, equals('font-bold'));

      expect(titleSlot.attributes.containsKey('id'), isTrue);
      expect(titleSlot.attributes['id']!.value, equals('alert-title'));
    });

    test('Slot with nested HTML content', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:header>
            <h1>Main Title</h1>
            <p class="subtitle">A description</p>
          </x-slot:header>
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'card');

      final headerSlot = component.slots['header'];
      expect(headerSlot, isNotNull);

      // Slot should have HTML children
      final htmlChildren = headerSlot!.children.whereType<HtmlElementNode>();
      expect(
        htmlChildren.length,
        greaterThanOrEqualTo(2),
        reason: 'Should have h1 and p elements',
      );

      final h1 = htmlChildren.firstWhere((e) => e.tagName == 'h1');
      expect(h1, isNotNull);

      final p = htmlChildren.firstWhere((e) => e.tagName == 'p');
      expect(p, isNotNull);
      expect(p.attributes.containsKey('class'), isTrue);
    });

    test('Slot with Blade directives inside', () {
      final result = parser.parse('''
        <x-list>
          <x-slot:items>
            @foreach(\$items as \$item)
              <li>{{ \$item }}</li>
            @endforeach
          </x-slot:items>
        </x-list>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'list');

      final itemsSlot = component.slots['items'];
      expect(itemsSlot, isNotNull);

      // Slot should contain the @foreach directive
      final directives = itemsSlot!.children.whereType<DirectiveNode>();
      expect(
        directives.any((d) => d.name == 'foreach'),
        isTrue,
        reason: 'Slot should contain Blade directives',
      );
    });

    test('Empty slot', () {
      final result = parser.parse('''
        <x-modal>
          <x-slot:actions></x-slot:actions>
        </x-modal>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'modal');

      expect(component.slots.containsKey('actions'), isTrue);

      final actionsSlot = component.slots['actions'];
      expect(actionsSlot, isNotNull);
      expect(
        actionsSlot!.children,
        isEmpty,
        reason: 'Empty slot should have no children',
      );
    });

    test('Slot closing tag must match opening', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:header>Content</x-slot:footer>
        </x-card>
      ''');

      // Should report error for mismatched slot tags
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Mismatched slot tags should produce error',
      );

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('header') ||
            e.message.toLowerCase().contains('footer') ||
            e.message.toLowerCase().contains('mismatch'),
      );

      expect(
        hasMismatchError,
        isTrue,
        reason: 'Error should mention mismatched slot tags',
      );
    });

    test('Default slot (unnamed content)', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:header>Header</x-slot:header>
          <p>This is default slot content</p>
          <x-slot:footer>Footer</x-slot:footer>
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'card');

      // Named slots
      expect(component.slots.length, equals(2));

      // Default content (the <p> tag) should be in component children,
      // not in slots map
      final defaultContent = component.children
          .where((c) => c is! SlotNode)
          .whereType<HtmlElementNode>();

      expect(
        defaultContent.any((e) => e.tagName == 'p'),
        isTrue,
        reason: 'Default content should be in component children',
      );
    });

    test('Self-closing slot should work', () {
      final result = parser.parse('''
        <x-card>
          <x-slot:divider />
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'card');

      expect(
        component.slots.containsKey('divider'),
        isTrue,
        reason: 'Self-closing slot should be recognized',
      );

      final dividerSlot = component.slots['divider'];
      expect(dividerSlot, isNotNull);
      expect(
        dividerSlot!.children,
        isEmpty,
        reason: 'Self-closing slot should be empty',
      );
    });
  });
}
