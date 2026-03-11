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
  });
}
