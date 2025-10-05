import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Component Attribute Parsing', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parse component with single string attribute', () {
      final result = parser.parse('<x-alert type="error">Message</x-alert>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.name, equals('alert'));
      expect(component.attributes.length, equals(1));
      expect(component.attributes.containsKey('type'), isTrue);

      final typeAttr = component.attributes['type']!;
      expect(typeAttr.name, equals('type'));
      expect(typeAttr.value, equals('error'));
    });

    test('Parse component with multiple attributes', () {
      final result = parser.parse('<x-button size="lg" variant="primary" disabled>Click</x-button>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes.length, equals(3));

      // String attributes
      expect(component.attributes['size']!.value, equals('lg'));
      expect(component.attributes['variant']!.value, equals('primary'));

      // Boolean attribute
      expect(component.attributes.containsKey('disabled'), isTrue);
      expect(component.attributes['disabled']!.value, isNull); // No value for boolean attrs
    });

    test('Parse component with Alpine.js shorthand attributes', () {
      final result = parser.parse('<x-modal @click="close" :open="isOpen">Content</x-modal>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;

      // Alpine.js @event shorthand
      expect(component.attributes.containsKey('@click'), isTrue);
      final clickAttr = component.attributes['@click']!;
      expect(clickAttr, isA<AlpineAttribute>());
      expect(clickAttr.value, equals('close'));

      // Alpine.js :bind shorthand
      expect(component.attributes.containsKey(':open'), isTrue);
      final openAttr = component.attributes[':open']!;
      expect(openAttr, isA<AlpineAttribute>());
      expect(openAttr.value, equals('isOpen'));
    });

    test('Parse component with x-data Alpine attribute', () {
      final result = parser.parse('<x-dropdown x-data="{ open: false }">Menu</x-dropdown>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes.containsKey('x-data'), isTrue);

      final xDataAttr = component.attributes['x-data']!;
      expect(xDataAttr, isA<AlpineAttribute>());
      expect(xDataAttr.value, equals('{ open: false }'));
    });

    test('Parse component with Livewire wire: attributes', () {
      final result = parser.parse('<x-form wire:submit="save" wire:model="form.email">Submit</x-form>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.attributes.containsKey('wire:submit'), isTrue);
      final submitAttr = component.attributes['wire:submit']!;
      expect(submitAttr, isA<LivewireAttribute>());
      expect(submitAttr.value, equals('save'));

      expect(component.attributes.containsKey('wire:model'), isTrue);
      final modelAttr = component.attributes['wire:model']!;
      expect(modelAttr, isA<LivewireAttribute>());
      expect(modelAttr.value, equals('form.email'));
    });

    test('Parse component with mixed attribute types', () {
      final result = parser.parse('''
        <x-card
          class="shadow-lg"
          x-show="visible"
          wire:loading.delay
          @click.prevent="handleClick"
          dismissible>
          Content
        </x-card>
      ''');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes.length, equals(5));

      // Standard attribute
      expect(component.attributes['class']!.value, equals('shadow-lg'));

      // Alpine directive
      expect(component.attributes['x-show'], isA<AlpineAttribute>());

      // Livewire with modifier
      expect(component.attributes['wire:loading.delay'], isA<LivewireAttribute>());

      // Alpine event with modifier
      expect(component.attributes['@click.prevent'], isA<AlpineAttribute>());

      // Boolean attribute
      expect(component.attributes.containsKey('dismissible'), isTrue);
    });

    test('Parse self-closing component with attributes', () {
      final result = parser.parse('<x-icon name="star" size="24" />');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.isSelfClosing, isTrue);
      expect(component.attributes.length, equals(2));
      expect(component.attributes['name']!.value, equals('star'));
      expect(component.attributes['size']!.value, equals('24'));
    });

    test('Parse component with quoted attribute containing spaces', () {
      final result = parser.parse('<x-alert message="This is a long message">Alert</x-alert>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes['message']!.value, equals('This is a long message'));
    });

    test('Parse component with single-quoted attributes', () {
      final result = parser.parse("<x-button text='Click me'>Button</x-button>");

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes['text']!.value, equals('Click me'));
    });

    test('Parse component with attributes containing special characters', () {
      final result = parser.parse('<x-input pattern="[A-Za-z0-9]+" placeholder="Enter code...">Input</x-input>');

      expect(result.isSuccess, isTrue);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.attributes['pattern']!.value, equals('[A-Za-z0-9]+'));
      expect(component.attributes['placeholder']!.value, equals('Enter code...'));
    });

    test('Component attributes appear in JSON output', () {
      final result = parser.parse('<x-alert type="warning" dismissible>Alert</x-alert>');

      expect(result.isSuccess, isTrue);

      final json = result.ast!.toJson();
      final component = json['children'][0];

      expect(component['type'], equals('component'));
      expect(component['name'], equals('alert'));
      expect(component['attributes'], isA<Map>());
      expect(component['attributes']['type'], isNotNull);
      expect(component['attributes']['type']['name'], equals('type'));
      expect(component['attributes']['type']['value'], equals('warning'));
      expect(component['attributes']['dismissible'], isNotNull);
    });
  });
}
