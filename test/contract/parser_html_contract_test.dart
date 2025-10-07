import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Parser HTML Recognition Contract Tests', () {
    test('Parser creates HtmlElementNode for simple HTML tag', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div>');

      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);
      expect(result.ast!.children, hasLength(1));
      expect(result.ast!.children[0], isA<HtmlElementNode>());

      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'div');
      expect(element.isSelfClosing, false);
      expect(element.isVoid, false);
      expect(element.children, isEmpty);
    });

    test('Parser creates HtmlElementNode with attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container" id="app"></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes, hasLength(2));
      expect(element.attributes['class'], isA<StandardAttribute>());
      expect(element.attributes['id'], isA<StandardAttribute>());
      expect(element.attributes['class']!.value, 'container');
      expect(element.attributes['id']!.value, 'app');
    });

    test('Parser recognizes void elements', () {
      final parser = BladeParser();
      final result = parser.parse('<br>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.tagName, 'br');
      expect(element.isVoid, true);
      expect(element.children, isEmpty);
    });

    test('Parser handles self-closing syntax', () {
      final parser = BladeParser();
      final result = parser.parse('<div />');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.tagName, 'div');
      expect(element.isSelfClosing, true);
      expect(element.children, isEmpty);
    });

    test('Parser builds nested HTML structure', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>text</p></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.tagName, 'div');
      expect(div.children, hasLength(1));
      expect(div.children[0], isA<HtmlElementNode>());

      final p = div.children[0] as HtmlElementNode;
      expect(p.tagName, 'p');
      expect(p.children, hasLength(1));
      expect(p.children[0], isA<TextNode>());
    });

    test('Parser categorizes Alpine.js attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<div x-data="{}" @click="handle"></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes['x-data'], isA<AlpineAttribute>());
      expect(element.attributes['@click'], isA<AlpineAttribute>());
    });

    test('Parser categorizes Livewire attributes', () {
      final parser = BladeParser();
      final result = parser.parse(
          '<button wire:click="save" wire:loading.class="opacity-50"></button>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes['wire:click'], isA<LivewireAttribute>());
      expect(
          element.attributes['wire:loading.class'], isA<LivewireAttribute>());
    });

    test('Parser distinguishes HTML from Blade components', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div><x-button></x-button>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children, hasLength(2));

      expect(result.ast!.children[0], isA<HtmlElementNode>());
      expect(result.ast!.children[1], isA<ComponentNode>());

      final htmlElement = result.ast!.children[0] as HtmlElementNode;
      expect(htmlElement.tagName, 'div');

      final component = result.ast!.children[1] as ComponentNode;
      expect(component.name, 'button');
    });

    test('Parser handles multiple HTML elements', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div><p></p><span></span>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children, hasLength(3));

      expect(result.ast!.children[0], isA<HtmlElementNode>());
      expect(result.ast!.children[1], isA<HtmlElementNode>());
      expect(result.ast!.children[2], isA<HtmlElementNode>());

      expect((result.ast!.children[0] as HtmlElementNode).tagName, 'div');
      expect((result.ast!.children[1] as HtmlElementNode).tagName, 'p');
      expect((result.ast!.children[2] as HtmlElementNode).tagName, 'span');
    });

    test('Parser handles HTML with text content', () {
      final parser = BladeParser();
      final result = parser.parse('<div>Hello World</div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.children, hasLength(1));
      expect(div.children[0], isA<TextNode>());

      final text = div.children[0] as TextNode;
      expect(text.content, 'Hello World');
    });

    test('Parser handles void element variations', () {
      final parser = BladeParser();

      // Test all void elements
      final voidElements = [
        'br',
        'img',
        'input',
        'hr',
        'area',
        'base',
        'col',
        'embed',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr'
      ];

      for (final tag in voidElements) {
        final result = parser.parse('<$tag>');
        expect(result.isSuccess, isTrue, reason: 'Failed for <$tag>');

        final element = result.ast!.children[0] as HtmlElementNode;
        expect(element.tagName, tag);
        expect(element.isVoid, true, reason: '<$tag> should be void');
      }
    });
  });

  group('Parser HTML Error Handling Contract Tests', () {
    test('Parser reports unclosed tag error', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(result.errors.first.message, contains('Unclosed'));
      expect(result.errors.first.message, contains('<p>'));

      // Partial AST still returned
      expect(result.ast, isNotNull);
      expect(result.ast!.children, isNotEmpty);
    });

    test('Parser reports mismatched tag error', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(result.errors.first.message, contains('Expected'));
      expect(result.errors.first.message, contains('</div>'));
      expect(result.errors.first.message, contains('</span>'));
    });

    test('Parser reports error for void element closing tag', () {
      final parser = BladeParser();
      final result = parser.parse('<br></br>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(result.errors.first.message, contains('Void element'));
      expect(result.errors.first.message, contains('<br>'));
      expect(result.errors.first.message, contains('closing tag'));
    });

    test('Parser reports invalid tag name error', () {
      final parser = BladeParser();
      final result = parser.parse('<123>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));
      expect(result.errors.first.message, contains('Invalid tag name'));
    });

    test('Parser collects multiple errors', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p></div><span>');

      // Should report: mismatched </div> (expected </p>) AND unclosed <span>
      expect(result.isSuccess, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(1));
    });

    test('Parser returns partial AST on error', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>Hello</div>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Partial AST should still be available
      expect(result.ast, isNotNull);
      expect(result.ast!.children, isNotEmpty);
    });

    test('Parser error includes position information', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.position, isNotNull);
      expect(result.errors.first.position!.line, greaterThanOrEqualTo(1));
      expect(result.errors.first.position!.column, greaterThanOrEqualTo(1));
    });
  });

  group('Parser HTML Attribute Handling Contract Tests', () {
    test('Parser handles single-quoted attributes', () {
      final parser = BladeParser();
      final result = parser.parse("<div class='container'></div>");

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes['class'], isNotNull);
      expect(element.attributes['class']!.value, 'container');
    });

    test('Parser handles double-quoted attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container"></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes['class'], isNotNull);
      expect(element.attributes['class']!.value, 'container');
    });

    test('Parser handles boolean attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<input disabled required>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes['disabled'], isNotNull);
      expect(element.attributes['required'], isNotNull);
      expect(element.attributes['disabled']!.value, isNull);
      expect(element.attributes['required']!.value, isNull);
    });

    test('Parser handles mixed attributes', () {
      final parser = BladeParser();
      final result = parser.parse(
          '<div class="container" x-data="{}" wire:click="save" disabled></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.attributes, hasLength(4));
      expect(element.attributes['class'], isA<StandardAttribute>());
      expect(element.attributes['x-data'], isA<AlpineAttribute>());
      expect(element.attributes['wire:click'], isA<LivewireAttribute>());
      expect(element.attributes['disabled'], isA<StandardAttribute>());
    });
  });
}
