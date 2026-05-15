import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter - directiveParenthesisSpacing', () {
    BladeFormatter formatterWith(DirectiveParenthesisSpacing spacing) {
      return BladeFormatter(
        config: FormatterConfig(directiveParenthesisSpacing: spacing),
      );
    }

    group('issue #16: auth/can/env directives respect spacing config', () {
      // Pre-fix, only the control-structure subset (if, foreach, while, ...)
      // honoured the spacing config. @can, @auth, @env etc. always rendered
      // compact regardless of the setting.
      const directivesWithExpression = [
        'can',
        'cannot',
        'canany',
        'auth',
        'guest',
        'env',
        'production',
        'session',
        'context',
        'hasSection',
        'sectionMissing',
        'fragment',
      ];

      for (final name in directivesWithExpression) {
        test('@$name spaced config adds space before parenthesis', () {
          final input = '@$name(\'x\')\n<p>Body</p>\n@end$name';
          final formatted =
              formatterWith(DirectiveParenthesisSpacing.spaced).format(input);
          expect(formatted, contains('@$name (\'x\')'),
              reason: 'spaced mode must put a space between @$name and (');
        });

        test('@$name compact config removes space before parenthesis', () {
          final input = '@$name (\'x\')\n<p>Body</p>\n@end$name';
          final formatted =
              formatterWith(DirectiveParenthesisSpacing.compact).format(input);
          expect(formatted, contains('@$name(\'x\')'),
              reason: 'compact mode must remove the space');
          expect(formatted, isNot(contains('@$name (\'x\')')));
        });

        // Note: preserve mode is documented as "keep original" but the parser
        // trims expression tokens at _extractExpression, so the leading space
        // is lost before the formatter ever sees it. Round-tripping the
        // original spacing under preserve is a separate parser issue.
      }
    });

    group('control structure directives still work', () {
      test('@if respects spaced config', () {
        final formatted = formatterWith(DirectiveParenthesisSpacing.spaced)
            .format('@if(\$x)\n<p>Y</p>\n@endif');
        expect(formatted, contains('@if (\$x)'));
      });

      test('@foreach respects compact config', () {
        final formatted = formatterWith(DirectiveParenthesisSpacing.compact)
            .format('@foreach (\$items as \$item)\n<p>X</p>\n@endforeach');
        expect(formatted, contains('@foreach(\$items as \$item)'));
      });
    });
  });
}
