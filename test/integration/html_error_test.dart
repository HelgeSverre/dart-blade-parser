import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('HTML Error Scenario Integration Tests', () {
    // Quickstart scenario #11
    test('Unclosed tag error scenario', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>Some content');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Check error message content
      final errorMessages = result.errors.map((e) => e.message).join(' ');
      expect(errorMessages, contains('Unclosed'));

      // Partial AST should still be available
      expect(result.ast, isNotNull);
      final div = result.ast!.children.whereType<HtmlElementNode>().firstOrNull;
      expect(div, isNotNull);
      expect(div!.tagName, 'div');
    });

    // Quickstart scenario #12
    test('Mismatched tags error scenario', () {
      final parser = BladeParser();
      final result = parser.parse('<div><span></div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Check for expected/found mismatch message
      final errorMessages = result.errors.map((e) => e.message).join(' ');
      expect(errorMessages, contains('Expected'));

      // Partial AST available
      expect(result.ast, isNotNull);
    });

    // Quickstart scenario #13
    test('Void element with closing tag error scenario', () {
      final parser = BladeParser();
      final result = parser.parse('<br></br>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      final errorMessages = result.errors.map((e) => e.message).join(' ');
      expect(errorMessages, contains('Void element'));
      expect(errorMessages, contains('closing tag'));
    });

    test('Multiple unclosed tags collected', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p><span>Text');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Partial AST still useful
      expect(result.ast, isNotNull);
    });

    test('Invalid tag name starting with digit', () {
      final parser = BladeParser();
      final result = parser.parse('<123>content</123>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      final errorMessages = result.errors.map((e) => e.message).join(' ');
      expect(errorMessages, contains('Invalid tag name'));
    });

    test('Void element with children error', () {
      final parser = BladeParser();
      final result = parser.parse('<img><div>child</div></img>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Multiple errors in complex document', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          <p>Unclosed paragraph
          <span></div>
          <br></br>
        </div>
      ''');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Multiple errors should be collected
      expect(result.errors.length, greaterThanOrEqualTo(1));
    });

    test('Nested mismatched tags', () {
      final parser = BladeParser();
      final result = parser.parse('<div><section><p></section></p></div>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Unclosed tag at end of document', () {
      final parser = BladeParser();
      final result = parser.parse('<div><header>Header content</header>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      final errorMessages = result.errors.map((e) => e.message).join(' ');
      expect(errorMessages, contains('Unclosed'));
      expect(errorMessages, contains('<div>'));
    });

    test('Error with position information', () {
      final parser = BladeParser();
      final result = parser.parse('<div></span>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(greaterThanOrEqualTo(1)));

      final error = result.errors.first;
      expect(error.position, isNotNull);
      expect(error.position!.line, greaterThanOrEqualTo(1));
      expect(error.position!.column, greaterThanOrEqualTo(1));
      expect(error.position!.offset, greaterThanOrEqualTo(0));
    });

    test('Partial AST preserves valid nodes before error', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          <p>Valid paragraph</p>
          <section>Unclosed section
          <span>
        </div>
      ''');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Should still have some valid structure
      expect(result.ast, isNotNull);
      final div = result.ast!.children.whereType<HtmlElementNode>().firstOrNull;
      expect(div, isNotNull);
    });

    test('Error recovery continues parsing after error', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div></span>
        <p>This should still be parsed</p>
      ''');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);

      // Parser should continue and parse the <p> tag
      expect(result.ast, isNotNull);
    });

    test('Mixed Blade and HTML errors', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          @if(\$test)
            <p>Unclosed paragraph
          @endif
        </div>
      ''');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Empty tag name error', () {
      final parser = BladeParser();
      final result = parser.parse('<>content</>');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Void element self-closing is valid', () {
      final parser = BladeParser();
      final result = parser.parse('<br />');

      // This should NOT be an error
      expect(result.isSuccess, isTrue);

      final br = result.ast!.children.whereType<HtmlElementNode>().first;
      expect(br.isVoid, true);
      expect(br.isSelfClosing, true);
    });
  });
}
