import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for attribute sorting features.
void main() {
  group('Attribute Sorting', () {
    group('AttributeSort.none (default)', () {
      test('preserves original attribute order', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.none),
        );

        const input =
            '<div data-value="1" class="container" id="main">Content</div>';
        final result = formatter.format(input);

        // Order should be preserved: data-value, class, id
        final dataIndex = result.indexOf('data-value');
        final classIndex = result.indexOf('class=');
        final idIndex = result.indexOf('id=');

        expect(dataIndex, lessThan(classIndex));
        expect(classIndex, lessThan(idIndex));
      });

      test('preserves order for components', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.none),
        );

        const input =
            '<x-alert dismissible type="success" message="Done">Content</x-alert>';
        final result = formatter.format(input);

        final dismissibleIndex = result.indexOf('dismissible');
        final typeIndex = result.indexOf('type=');
        final messageIndex = result.indexOf('message=');

        expect(dismissibleIndex, lessThan(typeIndex));
        expect(typeIndex, lessThan(messageIndex));
      });
    });

    group('AttributeSort.alphabetical', () {
      test('sorts attributes alphabetically', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input =
            '<div data-value="1" class="container" id="main">Content</div>';
        final result = formatter.format(input);

        // Order should be: class, data-value, id
        final classIndex = result.indexOf('class=');
        final dataIndex = result.indexOf('data-value');
        final idIndex = result.indexOf('id=');

        expect(classIndex, lessThan(dataIndex));
        expect(dataIndex, lessThan(idIndex));
      });

      test('sorts case-insensitively', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input = '<div Zebra="z" apple="a" Banana="b">Content</div>';
        final result = formatter.format(input);

        // Order should be: apple, Banana, Zebra (case-insensitive)
        final appleIndex = result.indexOf('apple=');
        final bananaIndex = result.indexOf('Banana=');
        final zebraIndex = result.indexOf('Zebra=');

        expect(appleIndex, lessThan(bananaIndex));
        expect(bananaIndex, lessThan(zebraIndex));
      });

      test('sorts component attributes alphabetically', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input =
            '<x-button wire:click="save" class="btn" type="submit">Click</x-button>';
        final result = formatter.format(input);

        final classIndex = result.indexOf('class=');
        final typeIndex = result.indexOf('type=');
        final wireIndex = result.indexOf('wire:click');

        expect(classIndex, lessThan(typeIndex));
        expect(typeIndex, lessThan(wireIndex));
      });

      test('handles mixed attribute types', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input =
            '<div x-data="{ open: false }" @click="toggle" :class="active" wire:model="name" data-id="1" id="main">Content</div>';
        final result = formatter.format(input);

        // All should be sorted alphabetically: :class, @click, data-id, id, wire:model, x-data
        final colonClassIndex = result.indexOf(':class=');
        final atClickIndex = result.indexOf('@click=');
        final dataIdIndex = result.indexOf('data-id=');
        final idIndex = result.indexOf('id=');
        final wireModelIndex = result.indexOf('wire:model=');
        final xDataIndex = result.indexOf('x-data=');

        expect(colonClassIndex, lessThan(atClickIndex));
        expect(atClickIndex, lessThan(dataIdIndex));
        expect(dataIdIndex, lessThan(idIndex));
        expect(idIndex, lessThan(wireModelIndex));
        expect(wireModelIndex, lessThan(xDataIndex));
      });
    });

    group('AttributeSort.byType', () {
      test('sorts standard HTML attributes first', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<div data-id="1" class="container" wire:model="name" id="main">Content</div>';
        final result = formatter.format(input);

        // Order should be: class, id (standard), data-id (data), wire:model (livewire)
        final classIndex = result.indexOf('class=');
        final idIndex = result.indexOf('id=');
        final dataIdIndex = result.indexOf('data-id=');
        final wireModelIndex = result.indexOf('wire:model=');

        expect(classIndex, lessThan(idIndex));
        expect(idIndex, lessThan(dataIdIndex));
        expect(dataIdIndex, lessThan(wireModelIndex));
      });

      test('sorts Alpine.js attributes after data attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<div x-show="open" data-id="1" id="main" @click="toggle">Content</div>';
        final result = formatter.format(input);

        // Order: id (standard), data-id (data), @click, x-show (alpine)
        final idIndex = result.indexOf('id=');
        final dataIdIndex = result.indexOf('data-id=');
        final atClickIndex = result.indexOf('@click=');
        final xShowIndex = result.indexOf('x-show=');

        expect(idIndex, lessThan(dataIdIndex));
        expect(dataIdIndex, lessThan(atClickIndex));
        // @click and x-show are both Alpine, sorted alphabetically within category
        expect(atClickIndex, lessThan(xShowIndex));
      });

      test('sorts Livewire attributes after Alpine attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<input wire:model="email" x-data="{ focused: false }" type="email" data-test="input">';
        final result = formatter.format(input);

        // Order: type (standard), data-test (data), x-data (alpine), wire:model (livewire)
        final typeIndex = result.indexOf('type=');
        final dataTestIndex = result.indexOf('data-test=');
        final xDataIndex = result.indexOf('x-data=');
        final wireModelIndex = result.indexOf('wire:model=');

        expect(typeIndex, lessThan(dataTestIndex));
        expect(dataTestIndex, lessThan(xDataIndex));
        expect(xDataIndex, lessThan(wireModelIndex));
      });

      test('sorts alphabetically within same category', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<div name="test" type="text" id="main" class="form">Content</div>';
        final result = formatter.format(input);

        // All are standard HTML, should be sorted alphabetically: class, id, name, type
        final classIndex = result.indexOf('class=');
        final idIndex = result.indexOf('id=');
        final nameIndex = result.indexOf('name=');
        final typeIndex = result.indexOf('type=');

        expect(classIndex, lessThan(idIndex));
        expect(idIndex, lessThan(nameIndex));
        expect(nameIndex, lessThan(typeIndex));
      });

      test('handles all attribute categories', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<div custom-attr="other" wire:loading="true" :bind="value" data-id="1" id="main">Content</div>';
        final result = formatter.format(input);

        // Order: id (standard), data-id (data), :bind (alpine), wire:loading (livewire), custom-attr (other)
        final idIndex = result.indexOf('id=');
        final dataIdIndex = result.indexOf('data-id=');
        final bindIndex = result.indexOf(':bind=');
        final wireLoadingIndex = result.indexOf('wire:loading=');
        final customAttrIndex = result.indexOf('custom-attr=');

        expect(idIndex, lessThan(dataIdIndex));
        expect(dataIdIndex, lessThan(bindIndex));
        expect(bindIndex, lessThan(wireLoadingIndex));
        expect(wireLoadingIndex, lessThan(customAttrIndex));
      });

      test('handles boolean attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input =
            '<input wire:loading disabled type="checkbox" checked required>';
        final result = formatter.format(input);

        // Standard: checked, disabled, required, type
        // Livewire: wire:loading
        final checkedIndex = result.indexOf('checked');
        final disabledIndex = result.indexOf('disabled');
        final requiredIndex = result.indexOf('required');
        final typeIndex = result.indexOf('type=');
        final wireLoadingIndex = result.indexOf('wire:loading');

        // All standard attributes should come before wire:
        expect(checkedIndex, lessThan(wireLoadingIndex));
        expect(disabledIndex, lessThan(wireLoadingIndex));
        expect(requiredIndex, lessThan(wireLoadingIndex));
        expect(typeIndex, lessThan(wireLoadingIndex));
      });

      test('maintains consistent sort for complex components', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );

        const input = '''
<x-button
wire:click="save"
x-on:click="close"
data-testid="save-btn"
class="btn btn-primary"
type="submit"
disabled>
Save
</x-button>
''';
        final result = formatter.format(input);

        // Order: class, disabled, type (standard), data-testid (data), x-on:click (alpine), wire:click (livewire)
        final classIndex = result.indexOf('class=');
        final disabledIndex = result.indexOf('disabled');
        final typeIndex = result.indexOf('type=');
        final dataTestidIndex = result.indexOf('data-testid=');
        final xOnClickIndex = result.indexOf('x-on:click=');
        final wireClickIndex = result.indexOf('wire:click=');

        expect(classIndex, lessThan(disabledIndex));
        expect(disabledIndex, lessThan(typeIndex));
        expect(typeIndex, lessThan(dataTestidIndex));
        expect(dataTestidIndex, lessThan(xOnClickIndex));
        expect(xOnClickIndex, lessThan(wireClickIndex));
      });
    });

    group('Sorting with wrapping', () {
      test('sorts before wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            attributeSort: AttributeSort.alphabetical,
            wrapAttributes: WrapAttributes.always,
          ),
        );

        const input = '<div zebra="z" apple="a" mango="m">Content</div>';
        final result = formatter.format(input);

        // Should be sorted: apple, mango, zebra
        final appleIndex = result.indexOf('apple=');
        final mangoIndex = result.indexOf('mango=');
        final zebraIndex = result.indexOf('zebra=');

        expect(appleIndex, lessThan(mangoIndex));
        expect(mangoIndex, lessThan(zebraIndex));

        // And should be wrapped
        expect(result, contains('<div\n'));
      });

      test('byType sorting with auto wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            attributeSort: AttributeSort.byType,
            wrapAttributes: WrapAttributes.auto,
            maxLineLength: 40,
          ),
        );

        const input =
            '<div wire:model="name" class="container" data-id="1" id="main">Content</div>';
        final result = formatter.format(input);

        // Should be sorted by type and wrapped
        expect(result, contains('<div\n'));

        // Check order
        final classIndex = result.indexOf('class=');
        final idIndex = result.indexOf('id=');
        final dataIdIndex = result.indexOf('data-id=');
        final wireModelIndex = result.indexOf('wire:model=');

        expect(classIndex, lessThan(idIndex));
        expect(idIndex, lessThan(dataIdIndex));
        expect(dataIdIndex, lessThan(wireModelIndex));
      });
    });

    group('Edge cases', () {
      test('handles empty attributes', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input = '<div>Content</div>';
        final result = formatter.format(input);

        expect(result.trim(), '<div>Content</div>');
      });

      test('handles single attribute', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input = '<div class="container">Content</div>';
        final result = formatter.format(input);

        expect(result.trim(), '<div class="container">Content</div>');
      });

      test('handles void elements', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input = '<input type="text" name="email" id="email-input">';
        final result = formatter.format(input);

        // Should be sorted: id, name, type
        final idIndex = result.indexOf('id=');
        final nameIndex = result.indexOf('name=');
        final typeIndex = result.indexOf('type=');

        expect(idIndex, lessThan(nameIndex));
        expect(nameIndex, lessThan(typeIndex));
      });

      test('handles slot attributes', () {
        final formatter = BladeFormatter(
          config:
              const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );

        const input = '''
<x-card>
<x-slot:header title="Header" class="bg-blue">
<h2>Title</h2>
</x-slot>
</x-card>
''';
        final result = formatter.format(input);

        // Should be sorted: class, title
        final classIndex = result.indexOf('class=');
        final titleIndex = result.indexOf('title=');

        expect(classIndex, lessThan(titleIndex));
      });
    });

    group('Config from map', () {
      test('parses attributeSort from map', () {
        final configNone = FormatterConfig.fromMap({'attribute_sort': 'none'});
        expect(configNone.attributeSort, AttributeSort.none);

        final configAlpha =
            FormatterConfig.fromMap({'attribute_sort': 'alphabetical'});
        expect(configAlpha.attributeSort, AttributeSort.alphabetical);

        final configByType =
            FormatterConfig.fromMap({'attribute_sort': 'by_type'});
        expect(configByType.attributeSort, AttributeSort.byType);
      });

      test('defaults to none for invalid value', () {
        final config = FormatterConfig.fromMap({'attribute_sort': 'invalid'});
        expect(config.attributeSort, AttributeSort.none);
      });

      test('toMap includes attributeSort', () {
        const config = FormatterConfig(attributeSort: AttributeSort.byType);
        final map = config.toMap();

        expect(map['attribute_sort'], 'by_type');
      });
    });
  });
}
