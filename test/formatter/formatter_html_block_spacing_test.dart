import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlBlockSpacing config', () {
    group('HtmlBlockSpacing.betweenBlocks (default)', () {
      final formatter = BladeFormatter();

      test('adds blank line between block-level siblings', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, contains('<div>A</div>\n\n<div>B</div>'));
      });
    });

    group('HtmlBlockSpacing.none', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          htmlBlockSpacing: HtmlBlockSpacing.none,
        ),
      );

      test('no blank line between block-level siblings', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, '<div>A</div>\n<div>B</div>\n');
      });
    });

    group('HtmlBlockSpacing.preserve', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          htmlBlockSpacing: HtmlBlockSpacing.preserve,
        ),
      );

      test('preserves blank line when present in source', () {
        const input = '<div>A</div>\n\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, contains('<div>A</div>\n\n<div>B</div>'));
      });

      test('does not insert blank line when absent from source', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, '<div>A</div>\n<div>B</div>\n');
      });
    });
  });
}
