import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('formatWithCursor', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('tracks cursor in plain text', () {
      // Cursor is in the middle of text "Hello"
      //                      01234
      const source = '<p>Hello</p>';
      final result = formatter.formatWithCursor(source, 5);

      expect(result.formatted, contains('Hello'));
      expect(result.cursorOffset, greaterThanOrEqualTo(0));
      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('tracks cursor at start of file', () {
      const source = '<div>Hello</div>';
      final result = formatter.formatWithCursor(source, 0);

      expect(result.cursorOffset, equals(0));
      expect(result.formatted, contains('<div>'));
    });

    test('tracks cursor at end of file', () {
      const source = '<div>Hello</div>';
      final result = formatter.formatWithCursor(source, source.length);

      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('cursor moves with indentation changes', () {
      // Unformatted: cursor is at the <p> inside the @if
      const source = '<div>@if(\$user) <p>Hello</p> @endif</div>';
      // Cursor at the '<' of <p>
      final pIndex = source.indexOf('<p>');
      final result = formatter.formatWithCursor(source, pIndex);

      // After formatting, <p> should be indented; cursor should be near it
      final formattedPIndex = result.formatted.indexOf('<p>');
      expect(formattedPIndex, greaterThan(-1));
      // Cursor should be at or near the <p> in formatted output
      expect(result.cursorOffset, greaterThanOrEqualTo(0));
      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('returns valid formatted output', () {
      const source = '<div>@if(\$user) <p>Hello</p> @endif</div>';
      final result = formatter.formatWithCursor(source, 10);

      // Output should match normal formatting
      final normalFormatted = formatter.format(source);
      expect(result.formatted, equals(normalFormatted));
    });

    test('handles cursor in echo expression', () {
      const source = '<p>{{ \$name }}</p>';
      final echoIndex = source.indexOf('{{');
      final result = formatter.formatWithCursor(source, echoIndex);

      expect(result.formatted, contains('{{ \$name }}'));
      expect(result.cursorOffset, greaterThanOrEqualTo(0));
      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('handles cursor between nodes', () {
      const source = '<p>A</p><p>B</p>';
      final result = formatter.formatWithCursor(source, 8);

      expect(result.cursorOffset, greaterThanOrEqualTo(0));
      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('cursor offset is clamped for out-of-bounds values', () {
      const source = '<p>Hello</p>';
      final result = formatter.formatWithCursor(source, 9999);

      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });

    test('cursor offset for negative value is clamped to 0', () {
      const source = '<p>Hello</p>';
      final result = formatter.formatWithCursor(source, -5);

      expect(result.cursorOffset, greaterThanOrEqualTo(0));
    });

    test('idempotent cursor tracking', () {
      const source = '<div>@if(\$x) <p>Y</p> @endif</div>';
      final firstResult = formatter.formatWithCursor(source, 15);
      final secondResult = formatter.formatWithCursor(
        firstResult.formatted,
        firstResult.cursorOffset,
      );

      expect(secondResult.formatted, equals(firstResult.formatted));
      expect(secondResult.cursorOffset, equals(firstResult.cursorOffset));
    });

    test('best-effort formats malformed input and keeps cursor valid', () {
      const source = '<div><span>Text</div></span>';
      final result = formatter.formatWithCursor(source, source.indexOf('Text'));

      expect(
          result.formatted, equals('<div><span>Text</span></div>\n</span>\n'));
      expect(result.hasErrors, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.cursorOffset, greaterThanOrEqualTo(0));
      expect(result.cursorOffset, lessThanOrEqualTo(result.formatted.length));
    });
  });
}
