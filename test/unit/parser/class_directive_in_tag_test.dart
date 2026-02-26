import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Regression test for https://github.com/HelgeSverre/dart-blade-parser/pull/2#issuecomment-3965099669
/// Multiline @class([...]) with conditional array syntax inside HTML tags
/// was previously causing "Expected > or /> to close tag" parse errors.
void main() {
  group('@class directive in HTML tag head', () {
    late BladeParser parser;
    late BladeFormatter formatter;

    setUp(() {
      parser = BladeParser();
      formatter = BladeFormatter();
    });

    test('multiline @class with conditional array parses without errors', () {
      final input = r'''<div
    @class([
        'tw-items-center tw-border tw-self-start',
        'tw-bg-red-50 tw-border-red-200' => $opportunity->isClosingSoon(),
        'tw-bg-gray-200 tw-text-gray-900' => ! $opportunity->isClosingSoon(),
    ])
>
    Deadline: {{ $opportunity->human_closing_date }}
</div>''';

      final result = parser.parse(input);
      expect(result.errors, isEmpty,
          reason: '@class([...]) in tag head should not produce parse errors');
      expect(result.ast, isNotNull);
    });

    test('multiline @class in tag head produces correct AST structure', () {
      final input = r'''<div
    @class([
        'base-class',
        'active' => $isActive,
    ])
>
    Content
</div>''';

      final result = parser.parse(input);
      expect(result.errors, isEmpty);

      // Should have an HtmlElementNode for the div
      final elements = result.ast!.children.whereType<HtmlElementNode>();
      expect(elements, isNotEmpty, reason: 'Should parse <div> as HtmlElementNode');

      final div = elements.first;
      expect(div.tagName, equals('div'));

      // The @class directive should be captured in the tag head
      expect(div.attributes, isNotEmpty,
          reason: '@class should be captured as an attribute');
    });

    test('multiline @class formats without error and is idempotent', () {
      final input = r'''<div
    @class([
        'tw-items-center tw-border',
        'tw-bg-red-50' => $isClosingSoon,
        'tw-bg-gray-200' => ! $isClosingSoon,
    ])
>
    Deadline: {{ $date }}
</div>''';

      final formatted = formatter.format(input);
      expect(formatted, contains('@class'));
      expect(formatted, contains('tw-items-center'));

      // Idempotent
      final secondPass = formatter.format(formatted);
      expect(secondPass, equals(formatted),
          reason: 'Formatting should be idempotent');
    });

    test('simple @class in single line parses correctly', () {
      final input =
          r'''<html @class(['dark' => $isDark])>content</html>''';

      final result = parser.parse(input);
      expect(result.errors, isEmpty);
    });
  });
}
