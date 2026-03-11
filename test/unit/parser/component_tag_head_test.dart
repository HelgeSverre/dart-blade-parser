import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Component tagHead', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('tagHead is empty when no directives are present', () {
      final result = parser.parse(
        '<x-alert type="error" class="mt-4">Message</x-alert>',
      );
      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.tagHead, isEmpty);
    });

    test('@class alone does not populate tagHead (attribute directive)', () {
      const input = '<x-icon name="bell" @class([\'animate\' => \$x]) />';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      // @class is an attribute directive, not structural — no tagHead
      expect(component.tagHead, isEmpty);
      // But the attribute is still recorded
      expect(component.attributes.containsKey('@class'), isTrue);
    });

    test('@if/@endif populates tagHead on component', () {
      const input = '''<x-button
    type="submit"
    @if(\$loading)
        disabled
    @endif
>Save</x-button>''';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isNotEmpty);
      // type attr, @if directive, disabled attr, @endif directive
      expect(component.tagHead.length, equals(4));

      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('type'));

      expect(component.tagHead[1], isA<TagHeadDirective>());
      expect((component.tagHead[1] as TagHeadDirective).name, equals('if'));

      expect(component.tagHead[2], isA<TagHeadAttribute>());
      expect(
        (component.tagHead[2] as TagHeadAttribute).name,
        equals('disabled'),
      );

      expect(component.tagHead[3], isA<TagHeadDirective>());
      expect(
        (component.tagHead[3] as TagHeadDirective).name,
        equals('endif'),
      );
    });

    test('mixed @if and @class in component tag head', () {
      const input = '''<x-button
    type="submit"
    @if(\$loading)
        wire:loading.attr="disabled"
        wire:target="save"
    @endif
    @class(['btn', 'btn-lg' => \$large])
>Save</x-button>''';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isNotEmpty);
      // type, @if, wire:loading.attr, wire:target, @endif, @class
      expect(component.tagHead.length, equals(6));

      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('type'));

      expect(component.tagHead[1], isA<TagHeadDirective>());
      expect((component.tagHead[1] as TagHeadDirective).name, equals('if'));

      expect(component.tagHead[4], isA<TagHeadDirective>());
      expect(
        (component.tagHead[4] as TagHeadDirective).name,
        equals('endif'),
      );

      expect(component.tagHead[5], isA<TagHeadAttribute>());
      expect(
        (component.tagHead[5] as TagHeadAttribute).name,
        equals('@class'),
      );
    });

    test('self-closing component with @if preserves tagHead', () {
      const input =
          '<x-icon name="bell" @if(\$animate) class="animate-bounce" @endif />';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.isSelfClosing, isTrue);
      expect(component.tagHead, isNotEmpty);
      expect(component.tagHead.length, equals(4));

      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('name'));

      expect(component.tagHead[1], isA<TagHeadDirective>());
      expect((component.tagHead[1] as TagHeadDirective).name, equals('if'));

      expect(component.tagHead[2], isA<TagHeadAttribute>());
      expect(
        (component.tagHead[2] as TagHeadAttribute).name,
        equals('class'),
      );

      expect(component.tagHead[3], isA<TagHeadDirective>());
      expect(
        (component.tagHead[3] as TagHeadDirective).name,
        equals('endif'),
      );
    });

    test('component without structural directives has empty tagHead', () {
      const input =
          '<x-modal x-data="{ open: false }" wire:model="showModal">Content</x-modal>';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isEmpty);
      expect(component.attributes, isNotEmpty);
    });

    test('component preserves malformed tag-head chunks', () {
      const input = '<x-alert type="error" ??? data-x="1" />';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, hasLength(3));
      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect(component.tagHead[1], isA<TagHeadRaw>());
      expect((component.tagHead[1] as TagHeadRaw).content, '???');
      expect(component.tagHead[2], isA<TagHeadAttribute>());
      expect(component.attributes.containsKey('data-x'), isTrue);
    });

    test('attributes map is populated alongside tagHead', () {
      const input = '''<x-data-table
    :columns="\$columns"
    :rows="\$rows"
    @if(\$paginated)
        :per-page="\$perPage"
    @endif
>Content</x-data-table>''';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      // Attributes map has all attributes regardless of tagHead
      expect(component.attributes.containsKey(':columns'), isTrue);
      expect(component.attributes.containsKey(':rows'), isTrue);
      expect(component.attributes.containsKey(':per-page'), isTrue);

      // tagHead has the ordered items including directives
      expect(component.tagHead, isNotEmpty);
      expect(component.tagHead.length, equals(5));
    });

    test('component from fixture: structural_directives_in_tags.blade.php', () {
      // Matches the <x-button> example in the edge case fixture
      const input = '''<x-button
    type="submit"
    @if(\$loading)
        wire:loading.attr="disabled"
        wire:target="save"
    @endif
    @class(['btn', 'btn-lg' => \$large])
>
    Save
</x-button>''';
      final result = parser.parse(input);
      expect(result.ast, isNotNull);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.name, equals('button'));
      expect(component.tagHead, isNotEmpty);
      expect(component.attributes.containsKey('type'), isTrue);
      expect(component.attributes.containsKey('wire:loading.attr'), isTrue);
      expect(component.attributes.containsKey('wire:target'), isTrue);
      expect(component.attributes.containsKey('@class'), isTrue);
    });

    test('component from fixture: data-table with conditional :per-page', () {
      const input = '''<x-data-table
    :columns="\$columns"
    :rows="\$rows"
    :sortable="true"
    :searchable="true"
    wire:model.live="search"
    @if(\$paginated)
        :per-page="\$perPage"
    @endif
>
    <x-slot:empty>
        <p>No records found.</p>
    </x-slot>
</x-data-table>''';
      final result = parser.parse(input);
      expect(result.ast, isNotNull);

      final component = result.ast!.children.whereType<ComponentNode>().first;
      expect(component.name, equals('data-table'));
      expect(component.tagHead, isNotEmpty);
      // Verify conditional attribute is captured
      expect(component.attributes.containsKey(':per-page'), isTrue);
      // Verify slots still work
      expect(component.slots.containsKey('empty'), isTrue);
    });

    test('echo expression triggers tagHead population', () {
      const input =
          '<x-alert type="error" {{ \$attributes->class(["mt-4"]) }}>Message</x-alert>';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isNotEmpty);
      expect(component.tagHead.length, equals(2));

      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('type'));

      expect(component.tagHead[1], isA<TagHeadAttribute>());
      expect(
        (component.tagHead[1] as TagHeadAttribute).name,
        equals('{{ \$attributes->class(["mt-4"]) }}'),
      );
    });

    test('raw echo expression triggers tagHead population', () {
      const input =
          '<x-alert type="error" {!! \$attributes !!}>Message</x-alert>';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isNotEmpty);
      expect(component.tagHead.length, equals(2));

      expect(component.tagHead[0], isA<TagHeadAttribute>());
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('type'));

      expect(component.tagHead[1], isA<TagHeadAttribute>());
      expect(
        (component.tagHead[1] as TagHeadAttribute).name,
        equals('{!! \$attributes !!}'),
      );
    });

    test('echo without structural directives still preserves order', () {
      const input = '''<x-button
    type="submit"
    {{ \$attributes->merge(['class' => 'btn']) }}
    disabled
>Save</x-button>''';
      final result = parser.parse(input);
      final component = result.ast!.children.whereType<ComponentNode>().first;

      expect(component.tagHead, isNotEmpty);
      expect(component.tagHead.length, equals(3));

      // Order is preserved: type, echo, disabled
      expect((component.tagHead[0] as TagHeadAttribute).name, equals('type'));
      expect(
        (component.tagHead[1] as TagHeadAttribute).name,
        contains('\$attributes'),
      );
      expect(
          (component.tagHead[2] as TagHeadAttribute).name, equals('disabled'));
    });
  });
}
