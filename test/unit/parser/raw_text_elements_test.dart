import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for raw text elements (script, style)
/// These tests EXPOSE bugs - raw text content is incorrectly parsed as HTML
void main() {
  group('Raw Text Elements Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Script with comparison operators should not parse < as tag', () {
      final result = parser.parse('''
        <script>
          if (x < 10 && y > 5) {
            alert('test');
          }
        </script>
      ''');

      // Current bug: Tries to parse '< 10' as HTML tag, will fail
      expect(
        result.isSuccess,
        isTrue,
        reason: 'Script with < and > should parse successfully',
      );

      final script = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'script');

      expect(script, isNotNull);

      // Script content should be RAW TEXT, not parsed
      // Should have ONE text child containing the entire script
      final textChildren = script.children.whereType<TextNode>();
      expect(
        textChildren,
        isNotEmpty,
        reason: 'Script should have text content',
      );

      final scriptContent = textChildren.map((t) => t.content).join();
      expect(
        scriptContent,
        contains('x < 10'),
        reason: 'Script should preserve < literally',
      );
      expect(
        scriptContent,
        contains('y > 5'),
        reason: 'Script should preserve > literally',
      );

      // Should NOT have any HTML children inside script
      final htmlChildren = script.children.whereType<HtmlElementNode>();
      expect(
        htmlChildren,
        isEmpty,
        reason: 'Script content should not be parsed as HTML',
      );
    });

    test('Style with CSS selectors should not parse > as tag', () {
      final result = parser.parse('''
        <style>
          div > p { color: red; }
          a + span { margin: 0; }
        </style>
      ''');

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Style with > and + should parse successfully',
      );

      final style = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'style');

      expect(style, isNotNull);

      // Style content should be raw text
      final textChildren = style.children.whereType<TextNode>();
      expect(textChildren, isNotEmpty);

      final styleContent = textChildren.map((t) => t.content).join();
      expect(
        styleContent,
        contains('div > p'),
        reason: 'Style should preserve > literally',
      );

      // Should NOT parse as HTML
      final htmlChildren = style.children.whereType<HtmlElementNode>();
      expect(
        htmlChildren,
        isEmpty,
        reason: 'Style content should not be parsed as HTML',
      );
    });

    test('Script with template literals containing HTML', () {
      final result = parser.parse('''
        <script>
          const html = `<div>test</div>`;
          console.log(html);
        </script>
      ''');

      expect(result.isSuccess, isTrue);

      final script = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'script');

      // Should NOT parse the <div> inside the template literal
      final textChildren = script.children.whereType<TextNode>();
      final scriptContent = textChildren.map((t) => t.content).join();

      expect(
        scriptContent,
        contains('<div>test</div>'),
        reason: 'HTML inside template literal should be preserved as text',
      );

      // No nested div element should exist
      final nestedDivs = script.children.whereType<HtmlElementNode>().where(
        (e) => e.tagName == 'div',
      );
      expect(
        nestedDivs,
        isEmpty,
        reason: 'Template literal HTML should not be parsed',
      );
    });

    test('Script with closing tag in string literal', () {
      final result = parser.parse('''
        <script>
          const str = "</script>";
          console.log(str);
          alert('more code');
        </script>
      ''');

      // This is tricky: HTML5 spec requires special handling
      // Naive implementation will close at first </script>
      expect(
        result.isSuccess,
        isTrue,
        reason: 'Should handle </script> in string correctly',
      );

      final script = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'script');

      final textChildren = script.children.whereType<TextNode>();
      final scriptContent = textChildren.map((t) => t.content).join();

      // Should contain the full script, including the alert after the string
      expect(
        scriptContent,
        contains('alert'),
        reason: 'Should not prematurely close at </script> in string',
      );
    });

    test('Style followed by regular HTML', () {
      final result = parser.parse('''
        <style>
          body { margin: 0; }
        </style>
        <div class="content">Text</div>
      ''');

      expect(result.isSuccess, isTrue);

      final elements = result.ast!.children
          .whereType<HtmlElementNode>()
          .toList();

      expect(
        elements.length,
        greaterThanOrEqualTo(2),
        reason: 'Should have style and div as separate elements',
      );

      final style = elements.firstWhere((e) => e.tagName == 'style');
      final div = elements.firstWhere((e) => e.tagName == 'div');

      expect(style, isNotNull);
      expect(div, isNotNull);

      // Style and div should be siblings, not nested
      final styleTextContent = style.children
          .whereType<TextNode>()
          .map((t) => t.content)
          .join();
      expect(styleTextContent, contains('margin: 0'));
      expect(
        styleTextContent,
        isNot(contains('<div')),
        reason: 'Div should not be inside style',
      );
    });

    test('Script with multiple < and > operators', () {
      final result = parser.parse('''
        <script>
          if (a < b && c > d && e <= f && g >= h) {
            x = (y < 100) ? "low" : "high";
          }
        </script>
      ''');

      expect(result.isSuccess, isTrue);

      final script = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'script');

      final textChildren = script.children.whereType<TextNode>();
      final scriptContent = textChildren.map((t) => t.content).join();

      expect(scriptContent, contains('a < b'));
      expect(scriptContent, contains('c > d'));
      expect(scriptContent, contains('e <= f'));
      expect(scriptContent, contains('g >= h'));

      // Should not parse any HTML
      expect(script.children.whereType<HtmlElementNode>(), isEmpty);
    });

    test('Style with complex selectors', () {
      final result = parser.parse('''
        <style>
          nav > ul > li > a { text-decoration: none; }
          p ~ span { color: blue; }
          div + div { margin-top: 1em; }
        </style>
      ''');

      expect(result.isSuccess, isTrue);

      final style = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'style');

      final textChildren = style.children.whereType<TextNode>();
      final styleContent = textChildren.map((t) => t.content).join();

      expect(styleContent, contains('nav > ul > li > a'));
      expect(styleContent, contains('p ~ span'));
      expect(styleContent, contains('div + div'));

      expect(
        style.children.whereType<HtmlElementNode>(),
        isEmpty,
        reason: 'CSS should not be parsed as HTML',
      );
    });

    test('Nested script tags (edge case)', () {
      // HTML5 doesn't allow nested script tags, but parser should handle gracefully
      final result = parser.parse('''
        <script>
          document.write('<script src="other.js"><\\/script>');
        </script>
      ''');

      // Should handle the escaped closing tag
      expect(
        result.errors,
        isEmpty,
        reason: 'Should handle escaped script tags in content',
      );
    });

    test('Script in HTML document structure', () {
      final result = parser.parse('''
        <html>
          <head>
            <script>
              if (x < 10) { alert('low'); }
            </script>
          </head>
          <body>
            <p>Content</p>
          </body>
        </html>
      ''');

      expect(result.isSuccess, isTrue);

      // Navigate to script
      final html = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
        (e) => e.tagName == 'html',
      );

      final head = html.children.whereType<HtmlElementNode>().firstWhere(
        (e) => e.tagName == 'head',
      );

      final script = head.children.whereType<HtmlElementNode>().firstWhere(
        (e) => e.tagName == 'script',
      );

      expect(script, isNotNull);

      final scriptContent = script.children
          .whereType<TextNode>()
          .map((t) => t.content)
          .join();

      expect(scriptContent, contains('x < 10'));

      // Script should not have HTML children
      expect(script.children.whereType<HtmlElementNode>(), isEmpty);
    });

    test('Empty script and style tags', () {
      final result = parser.parse('''
        <script></script>
        <style></style>
      ''');

      expect(result.isSuccess, isTrue);

      final elements = result.ast!.children.whereType<HtmlElementNode>();

      final script = elements.firstWhere((e) => e.tagName == 'script');
      final style = elements.firstWhere((e) => e.tagName == 'style');

      expect(script, isNotNull);
      expect(style, isNotNull);

      // Can be empty or have empty text node
      expect(script.children, isNotNull);
      expect(style.children, isNotNull);
    });
  });
}
