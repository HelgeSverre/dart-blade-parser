import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Tag Name Normalization Unit Tests', () {
    test('Uppercase tag names normalized to lowercase', () {
      final parser = BladeParser();
      final result = parser.parse('<DIV></DIV>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'div');
    });

    test('Mixed case tag names normalized to lowercase', () {
      final parser = BladeParser();
      final result = parser.parse('<Div></Div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'div');
    });

    test('Case-insensitive tag matching', () {
      final parser = BladeParser();
      final result = parser.parse('<DIV></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'div');
    });

    test('All uppercase tags normalized', () {
      final parser = BladeParser();
      final result = parser.parse('<SPAN></SPAN>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'span');
    });
  });

  group('Tag Matching Unit Tests', () {
    test('Matching opening and closing tags', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'div');
    });

    test('Mismatched tags detected', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.message, contains('Expected'));
    });

    test('Nested matching tags', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p></p></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;
      expect(div.tagName, 'div');

      final p = div.children[0] as HtmlElementNode;
      expect(p.tagName, 'p');
    });

    test('Multiple nested matching', () {
      final parser = BladeParser();
      final result =
          parser.parse('<div><section><article></article></section></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;
      final section = div.children[0] as HtmlElementNode;
      final article = section.children[0] as HtmlElementNode;

      expect(div.tagName, 'div');
      expect(section.tagName, 'section');
      expect(article.tagName, 'article');
    });
  });

  group('Void Element Validation Unit Tests', () {
    test('All void elements recognized', () {
      final parser = BladeParser();
      final voidElements = [
        'area',
        'base',
        'br',
        'col',
        'embed',
        'hr',
        'img',
        'input',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr'
      ];

      for (final tag in voidElements) {
        final result = parser.parse('<$tag>');
        expect(result.isSuccess, isTrue,
            reason: '<$tag> should parse successfully');

        final element = result.ast!.children[0] as HtmlElementNode;
        expect(element.tagName, tag);
        expect(element.isVoid, true, reason: '<$tag> should be void');
      }
    });

    test('Void elements cannot have closing tag', () {
      final parser = BladeParser();
      final result = parser.parse('<br></br>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.message, contains('Void element'));
      expect(result.errors.first.message, contains('closing tag'));
    });

    test('Void elements can be self-closing', () {
      final parser = BladeParser();
      final result = parser.parse('<br />');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.isVoid, true);
      expect(element.isSelfClosing, true);
    });

    test('Void elements have no children', () {
      final parser = BladeParser();
      final result = parser.parse('<input type="text">');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.isVoid, true);
      expect(element.children, isEmpty);
    });
  });

  group('Attribute Quote Handling Unit Tests', () {
    test('Double-quoted attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container"></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.attributes['class']!.value, 'container');
    });

    test('Single-quoted attributes', () {
      final parser = BladeParser();
      final result = parser.parse("<div class='container'></div>");

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.attributes['class']!.value, 'container');
    });

    test('Mixed quote styles', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="foo" id=\'bar\'></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.attributes['class']!.value, 'foo');
      expect(element.attributes['id']!.value, 'bar');
    });

    test('Attributes with special characters', () {
      final parser = BladeParser();
      final result = parser.parse(
          '<div data-config="{&quot;key&quot;: &quot;value&quot;}"></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.attributes['data-config'], isNotNull);
    });
  });

  group('HTML vs Blade Component Distinction Unit Tests', () {
    test('Standard HTML element recognized', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children[0], isA<HtmlElementNode>());
    });

    test('Blade component with x- prefix recognized', () {
      final parser = BladeParser();
      final result = parser.parse('<x-button></x-button>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children[0], isA<ComponentNode>());
    });

    test('Multiple HTML elements not confused with components', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div><span></span><p></p>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children[0], isA<HtmlElementNode>());
      expect(result.ast!.children[1], isA<HtmlElementNode>());
      expect(result.ast!.children[2], isA<HtmlElementNode>());
    });

    test('Custom elements with hyphens are HTML elements', () {
      final parser = BladeParser();
      final result = parser.parse('<my-element></my-element>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children[0], isA<HtmlElementNode>());

      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.tagName, 'my-element');
    });
  });

  group('Multiple Error Collection Unit Tests', () {
    test('Multiple unclosed tags collected', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p><span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Mixed error types collected', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span><br></br>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Error positions are accurate', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));

      final error = result.errors.first;
      expect(error.position, isNotNull);
      expect(error.position!.line, greaterThanOrEqualTo(1));
      expect(error.position!.column, greaterThanOrEqualTo(1));
    });
  });

  group('Partial AST Generation Unit Tests', () {
    test('Partial AST returned on unclosed tag', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>Text');

      expect(result.isSuccess, isFalse);
      expect(result.ast, isNotNull);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstOrNull;
      expect(div, isNotNull);
      expect(div!.tagName, 'div');
    });

    test('Partial AST returned on mismatched tag', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p></div>');

      expect(result.isSuccess, isFalse);
      expect(result.ast, isNotNull);
    });

    test('Partial AST preserves valid nodes', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>Valid</p><span>');

      expect(result.isSuccess, isFalse);
      expect(result.ast, isNotNull);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstOrNull;
      expect(div, isNotNull);

      // Should have the valid <p> tag
      final p = div!.children.whereType<HtmlElementNode>().firstOrNull;
      expect(p, isNotNull);
      expect(p!.tagName, 'p');
    });
  });

  group('Position Tracking Unit Tests', () {
    test('startPosition captures opening tag location', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.startPosition, isNotNull);
      expect(element.startPosition.line, greaterThanOrEqualTo(1));
      expect(element.startPosition.column, greaterThanOrEqualTo(1));
      expect(element.startPosition.offset, greaterThanOrEqualTo(0));
    });

    test('endPosition captures closing tag location', () {
      final parser = BladeParser();
      final result = parser.parse('<div></div>');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.endPosition, isNotNull);
      expect(element.endPosition.line, greaterThanOrEqualTo(1));
      expect(element.endPosition.column,
          greaterThan(element.startPosition.column));
    });

    test('Position accuracy for nested elements', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p></p></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;
      final p = div.children[0] as HtmlElementNode;

      expect(p.startPosition.offset, greaterThan(div.startPosition.offset));
      expect(p.endPosition.offset, lessThan(div.endPosition.offset));
    });

    test('Self-closing position tracking', () {
      final parser = BladeParser();
      final result = parser.parse('<div />');

      expect(result.isSuccess, isTrue);
      final element = result.ast!.children[0] as HtmlElementNode;

      expect(element.startPosition, isNotNull);
      expect(element.endPosition, isNotNull);
      expect(element.endPosition.offset,
          greaterThan(element.startPosition.offset));
    });
  });
}
