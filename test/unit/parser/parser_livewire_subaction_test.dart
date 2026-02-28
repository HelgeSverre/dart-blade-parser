@Tags(['livewire'])
library;

import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Livewire sub-action parsing', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('wire: attributes with colon sub-attributes', () {
      test('wire:sort:item parses action="sort" subAction="item"', () {
        final result =
            parser.parse('<li wire:sort:item="{{ \$id }}">text</li>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:item'] as LivewireAttribute;

        expect(attr.action, equals('sort'));
        expect(attr.subAction, equals('item'));
        expect(attr.modifiers, isEmpty);
        expect(attr.value, contains('\$id'));
      });

      test('wire:sort:handle parses as boolean attribute with subAction', () {
        final result = parser.parse('<div wire:sort:handle>::</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:handle'] as LivewireAttribute;

        expect(attr.action, equals('sort'));
        expect(attr.subAction, equals('handle'));
        expect(attr.modifiers, isEmpty);
        expect(attr.value, isNull);
      });

      test('wire:sort:group parses subAction', () {
        final result =
            parser.parse('<ul wire:sort:group="cards">items</ul>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:group'] as LivewireAttribute;

        expect(attr.action, equals('sort'));
        expect(attr.subAction, equals('group'));
        expect(attr.value, equals('cards'));
      });

      test('wire:sort:group-id parses hyphenated subAction', () {
        final result = parser
            .parse('<ul wire:sort:group-id="{{ \$col->id }}">items</ul>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:group-id'] as LivewireAttribute;

        expect(attr.action, equals('sort'));
        expect(attr.subAction, equals('group-id'));
      });

      test('wire:sort:ignore parses subAction', () {
        final result =
            parser.parse('<div wire:sort:ignore>buttons</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:ignore'] as LivewireAttribute;

        expect(attr.action, equals('sort'));
        expect(attr.subAction, equals('ignore'));
      });

      test('wire:bind:class parses action="bind" subAction="class"', () {
        final result = parser.parse(
            '<input wire:bind:class="isError && \'text-red\'">');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:bind:class'] as LivewireAttribute;

        expect(attr.action, equals('bind'));
        expect(attr.subAction, equals('class'));
        expect(attr.modifiers, isEmpty);
      });

      test('wire:bind:disabled parses subAction', () {
        final result =
            parser.parse('<button wire:bind:disabled="isArchived">Go</button>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:bind:disabled'] as LivewireAttribute;

        expect(attr.action, equals('bind'));
        expect(attr.subAction, equals('disabled'));
      });

      test('wire:intersect:enter parses subAction', () {
        final result = parser.parse(
            '<div wire:intersect:enter="trackView">content</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:intersect:enter'] as LivewireAttribute;

        expect(attr.action, equals('intersect'));
        expect(attr.subAction, equals('enter'));
        expect(attr.modifiers, isEmpty);
      });

      test('wire:intersect:leave parses subAction', () {
        final result = parser.parse(
            '<div wire:intersect:leave="pauseVideo">content</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:intersect:leave'] as LivewireAttribute;

        expect(attr.action, equals('intersect'));
        expect(attr.subAction, equals('leave'));
      });

      test('wire:navigate:scroll parses subAction', () {
        final result = parser.parse(
            '<div wire:navigate:scroll>scrollable</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:navigate:scroll'] as LivewireAttribute;

        expect(attr.action, equals('navigate'));
        expect(attr.subAction, equals('scroll'));
      });
    });

    group('sub-actions combined with modifiers', () {
      test('wire:intersect:enter.once parses subAction and modifier', () {
        final result = parser.parse(
            '<div wire:intersect:enter.once="loadMore">content</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:intersect:enter.once'] as LivewireAttribute;

        expect(attr.action, equals('intersect'));
        expect(attr.subAction, equals('enter'));
        expect(attr.modifiers, equals(['once']));
      });

      test(
          'wire:intersect:enter.once.half.margin.100px parses multiple modifiers',
          () {
        final result = parser.parse(
            '<div wire:intersect:enter.once.half.margin.100px="load">x</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:intersect:enter.once.half.margin.100px']
            as LivewireAttribute;

        expect(attr.action, equals('intersect'));
        expect(attr.subAction, equals('enter'));
        expect(attr.modifiers, equals(['once', 'half', 'margin', '100px']));
      });
    });

    group('plain wire: attributes retain null subAction', () {
      test('wire:click has no subAction', () {
        final result =
            parser.parse('<button wire:click="save">Save</button>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:click'] as LivewireAttribute;

        expect(attr.action, equals('click'));
        expect(attr.subAction, isNull);
        expect(attr.modifiers, isEmpty);
      });

      test('wire:model.live.debounce.300ms has no subAction', () {
        final result = parser.parse(
            '<input wire:model.live.debounce.300ms="search">');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:model.live.debounce.300ms']
            as LivewireAttribute;

        expect(attr.action, equals('model'));
        expect(attr.subAction, isNull);
        expect(attr.modifiers, equals(['live', 'debounce', '300ms']));
      });

      test('wire:click.prevent has no subAction', () {
        final result = parser.parse(
            '<a wire:click.prevent="show" href="#">Link</a>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr =
            el.attributes['wire:click.prevent'] as LivewireAttribute;

        expect(attr.action, equals('click'));
        expect(attr.subAction, isNull);
        expect(attr.modifiers, equals(['prevent']));
      });

      test('wire:poll.5s.keep-alive has no subAction', () {
        final result = parser.parse(
            '<div wire:poll.5s.keep-alive="refresh">data</div>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:poll.5s.keep-alive']
            as LivewireAttribute;

        expect(attr.action, equals('poll'));
        expect(attr.subAction, isNull);
        expect(attr.modifiers, equals(['5s', 'keep-alive']));
      });
    });

    group('JSON serialization includes subAction', () {
      test('subAction appears in JSON when present', () {
        final result = parser.parse(
            '<li wire:sort:item="{{ \$id }}">text</li>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:sort:item'] as LivewireAttribute;
        final json = attr.toJson();

        expect(json['action'], equals('sort'));
        expect(json['subAction'], equals('item'));
      });

      test('subAction absent from JSON when null', () {
        final result =
            parser.parse('<button wire:click="save">Save</button>');
        expect(result.isSuccess, isTrue);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        final attr = el.attributes['wire:click'] as LivewireAttribute;
        final json = attr.toJson();

        expect(json['action'], equals('click'));
        expect(json.containsKey('subAction'), isFalse);
      });
    });
  });
}
