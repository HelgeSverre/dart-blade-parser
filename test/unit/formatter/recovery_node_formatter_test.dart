import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter RecoveryNode output', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('stray closer inside element is preserved in output', () {
      // Parser should handle </bogus> gracefully, formatter preserves content
      const input = '<div><span>Text</bogus>More</span></div>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('Text'));
      expect(result.formatted, contains('More'));
    });

    test('unclosed directive at EOF preserves content and reports error', () {
      const input = '@if(\$x)\n    <p>Hello</p>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('@if'));
      expect(result.formatted, contains('<p>Hello</p>'));
    });

    test('recovery node content round-trips verbatim', () {
      // Malformed input with stray closer — format twice, same output
      const input = '<div>Text</bogus>More</div>';
      final pass1 = formatter.format(input);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1), reason: 'recovery output must be idempotent');
    });

    group('integration: parse + format with recovery', () {
      test('stray closer in element formats and re-formats identically', () {
        const input = '<div>Text</bogus>More</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('unclosed @if formats and re-formats identically', () {
        const input = '@if(\$x)\n    <p>Hello</p>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('multiple recovery sites in one template are all idempotent', () {
        const input = '<div></bogus></baz>Text</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('ancestor-close recovery is idempotent', () {
        const input = '<div><span>Text</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('stray closer content appears in formatted output', () {
        const input = '<div>Hello</bogus>World</div>';
        final result = formatter.formatWithResult(input);
        expect(result.hasErrors, isTrue);
        expect(result.formatted, contains('</bogus>'));
        expect(result.formatted, contains('Hello'));
        expect(result.formatted, contains('World'));
      });

      test('unclosed @foreach is idempotent', () {
        const input = '@foreach(\$items as \$item)\n<li>{{ \$item }}</li>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });
    });
  });
}
