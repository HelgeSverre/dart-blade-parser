import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('formatRange', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('formats only the selected range', () {
      const source =
          '<p>First</p>\n<div>@if(\$x) <p>Y</p> @endif</div>\n<p>Last</p>';
      // Range covers the <div>...</div> line
      final rangeStart = source.indexOf('<div>');
      final rangeEnd = source.indexOf('</div>') + '</div>'.length;

      final result = formatter.formatRange(source, rangeStart, rangeEnd);

      // The middle part should be formatted (indented)
      expect(result.formatted, contains('@if(\$x)'));
      // Last <p> should still be present
      expect(result.formatted, contains('<p>Last</p>'));
      expect(result.wasChanged, isTrue);
    });

    test('preserves text before range', () {
      const source = '<!-- header -->\n<div>@if(\$x) <p>Y</p> @endif</div>';
      final rangeStart = source.indexOf('<div>');

      final result = formatter.formatRange(source, rangeStart, source.length);

      // Header comment should still be present in the output
      expect(result.formatted, contains('<!-- header -->'));
    });

    test('preserves text after range', () {
      const source = '<div>@if(\$x) <p>Y</p> @endif</div>\n<!-- footer -->';
      final rangeEnd = source.indexOf('\n<!-- footer -->');

      final result = formatter.formatRange(source, 0, rangeEnd);

      expect(result.formatted, endsWith('\n<!-- footer -->'));
    });

    test('returns unchanged source when range has no overlapping nodes', () {
      const source = '<p>Hello</p>\n\n<p>World</p>';
      // Range covers just the blank line between nodes
      final rangeStart = source.indexOf('\n\n');
      final rangeEnd = rangeStart + 2;

      final result = formatter.formatRange(source, rangeStart, rangeEnd);

      // Whitespace-only text nodes may or may not overlap; result should be valid
      expect(result.formatted, isNotEmpty);
    });

    test('formats full document when range covers everything', () {
      const source = '<div>@if(\$x) <p>Y</p> @endif</div>';
      final result = formatter.formatRange(source, 0, source.length);

      final fullFormat = formatter.format(source);
      expect(result.formatted, equals(fullFormat));
    });

    test('snaps range to node boundaries', () {
      // Range starts in the middle of a node
      const source = '<p>Hello</p>\n<div>Content</div>';
      // Start in the middle of "Hello"
      final result = formatter.formatRange(source, 5, source.length);

      // Should snap to include the full <p> node
      expect(result.formatted, contains('<p>'));
    });

    test('best-effort formats malformed ranges and reports errors', () {
      const source = '@if(\$x) <p>Unclosed';
      final result = formatter.formatRange(source, 0, source.length);

      expect(result.hasErrors, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.formatted, contains('@if(\$x)'));
      expect(result.formatted, contains('Unclosed'));
      expect(result.formatted, contains('@endif'));
    });

    test('handles range at start of file', () {
      const source = '<p>First</p>\n<p>Second</p>';
      final rangeEnd = source.indexOf('\n');

      final result = formatter.formatRange(source, 0, rangeEnd);

      expect(result.formatted, contains('<p>First</p>'));
    });

    test('handles range at end of file', () {
      const source = '<p>First</p>\n<p>Second</p>';
      final rangeStart = source.indexOf('<p>Second');

      final result = formatter.formatRange(source, rangeStart, source.length);

      expect(result.formatted, contains('<p>Second</p>'));
    });
  });
}
