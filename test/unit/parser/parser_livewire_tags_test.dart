@Tags(['livewire'])
library;

import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Livewire tag parsing', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('<livewire:component> self-closing tags', () {
      test('parses <livewire:counter /> with full tag name', () {
        final result = parser.parse('<livewire:counter />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:counter'));
        expect(el.isSelfClosing, isTrue);
      });

      test('parses <livewire:post.create /> with dot namespace', () {
        final result = parser.parse('<livewire:post.create />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:post.create'));
        expect(el.isSelfClosing, isTrue);
      });

      test('parses <livewire:pages::post.create /> with namespace prefix',
          () {
        final result = parser.parse('<livewire:pages::post.create />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:pages::post.create'));
      });

      test('parses <livewire:database-notifications /> with hyphens', () {
        final result =
            parser.parse('<livewire:database-notifications />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:database-notifications'));
      });
    });

    group('<livewire:component> with attributes', () {
      test('parses with Blade expression attribute', () {
        final result = parser.parse(
            '<livewire:user-profile :user="\$user" />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:user-profile'));
        expect(el.attributes, isNotEmpty);
      });

      test('parses with wire:ref attribute', () {
        final result = parser.parse(
            '<livewire:modal wire:ref="modal" />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:modal'));
        expect(el.attributes.containsKey('wire:ref'), isTrue);
      });

      test('parses with lazy attribute', () {
        final result =
            parser.parse('<livewire:revenue lazy />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:revenue'));
      });

      test('parses with wire:key attribute', () {
        final result = parser.parse(
            '<livewire:user-card :user="\$user" wire:key="user-{{ \$user->id }}" />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:user-card'));
      });
    });

    group('<livewire:component> with children (slot content)', () {
      test('parses opening/closing pair with slot content', () {
        final result = parser.parse(
            '<livewire:modal wire:ref="modal"><p>content</p></livewire:modal>');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:modal'));
        expect(el.isSelfClosing, isFalse);
        expect(el.children, isNotEmpty);
      });

      test('parses closing tag with matching name', () {
        final result = parser.parse(
            '<livewire:sidebar>nav content</livewire:sidebar>');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final el = result.ast!.children.whereType<HtmlElementNode>().first;
        expect(el.tagName, equals('livewire:sidebar'));
      });
    });

    group('livewire tags in context', () {
      test('parses livewire tag inside layout', () {
        final result = parser.parse('''
<body>
    {{ \$slot }}
    <livewire:notifications />
    <livewire:database-notifications />
</body>
''');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final body = result.ast!.children.whereType<HtmlElementNode>().first;
        final livewireTags = body.children
            .whereType<HtmlElementNode>()
            .where((e) => e.tagName.startsWith('livewire:'))
            .toList();
        expect(livewireTags.length, equals(2));
        expect(livewireTags[0].tagName, equals('livewire:notifications'));
        expect(
            livewireTags[1].tagName, equals('livewire:database-notifications'));
      });
    });
  });
}
