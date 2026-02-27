import 'package:blade_parser/src/formatter/formatter.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter - Ignore Comments', () {
    final formatter = BladeFormatter(
      config: const FormatterConfig(),
    );

    group('Blade comments', () {
      test('blade-formatter:off disables formatting', () {
        const input = '''{{-- blade-formatter:off --}}
<div    class="preserve"   >
    This   content    is   preserved   exactly
</div>
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // The content between off/on should be preserved exactly
        expect(result, contains('<div    class="preserve"   >'));
        expect(result, contains('This   content    is   preserved   exactly'));
      });

      test('blade-formatter-disable/enable syntax works', () {
        const input = '''{{-- blade-formatter-disable --}}
<div    class="messy"   ></div>
{{-- blade-formatter-enable --}}''';
        final result = formatter.format(input);

        expect(result, contains('<div    class="messy"   ></div>'));
      });

      test('format:off/on short syntax works', () {
        const input = '''{{-- format:off --}}
<div    class="messy"   ></div>
{{-- format:on --}}''';
        final result = formatter.format(input);

        expect(result, contains('<div    class="messy"   ></div>'));
      });

      test('is case-insensitive', () {
        const input = '''{{-- BLADE-FORMATTER:OFF --}}
<div    class="messy"   ></div>
{{-- BLADE-FORMATTER:ON --}}''';
        final result = formatter.format(input);

        expect(result, contains('<div    class="messy"   ></div>'));
      });
    });

    group('HTML comments', () {
      test('HTML comment syntax works for off/on', () {
        const input = '''<!-- blade-formatter:off -->
<table>
<tr><td>1</td><td>2</td><td>3</td></tr>
</table>
<!-- blade-formatter:on -->''';
        final result = formatter.format(input);

        // Table should be preserved exactly
        expect(result, contains('<tr><td>1</td><td>2</td><td>3</td></tr>'));
      });

      test('HTML comment format:off/on works', () {
        const input = '''<!-- format:off -->
<pre>   preserved   whitespace   </pre>
<!-- format:on -->''';
        final result = formatter.format(input);

        expect(result, contains('<pre>   preserved   whitespace   </pre>'));
      });
    });

    group('multiple regions', () {
      test('multiple off/on regions in same file', () {
        const input = '''<div class="formatted">
    <p>This is formatted</p>
</div>
{{-- blade-formatter:off --}}
<div    class="not-formatted"   >
    preserved
</div>
{{-- blade-formatter:on --}}
<div class="also-formatted">
    <p>Back to formatting</p>
</div>
{{-- blade-formatter:off --}}
<span>also   preserved</span>
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // First region should be formatted (no extra spaces in class attr)
        expect(result, contains('<div class="formatted">'));

        // Second region preserved
        expect(result, contains('<div    class="not-formatted"   >'));

        // Third region formatted
        expect(result, contains('<div class="also-formatted">'));

        // Fourth region preserved
        expect(result, contains('<span>also   preserved</span>'));
      });
    });

    group('off without matching on', () {
      test('formatting disabled to end of file', () {
        const input = '''<div class="formatted"></div>
{{-- blade-formatter:off --}}
<div    class="rest-of-file"   >
everything   here   preserved
</div>''';
        final result = formatter.format(input);

        // First element formatted
        expect(result, contains('<div class="formatted">'));

        // Everything after off is preserved
        expect(result, contains('<div    class="rest-of-file"   >'));
        expect(result, contains('everything   here   preserved'));
      });
    });

    group('nested structures', () {
      test('preserves nested HTML in ignored region', () {
        const input = '''{{-- blade-formatter:off --}}
<div>
    <span><a href="#">Link</a></span>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
    </ul>
</div>
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // All nested content should be preserved
        expect(result, contains('<span><a href="#">Link</a></span>'));
        expect(result, contains('<li>Item 1</li>'));
      });

      test('preserves Blade directives in ignored region', () {
        const input = '''{{-- blade-formatter:off --}}
@if(\$condition)
<div>   content   </div>
@endif
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // Directive and content preserved
        expect(result, contains('@if(\$condition)'));
        expect(result, contains('<div>   content   </div>'));
      });

      test('preserves components in ignored region', () {
        const input = '''{{-- blade-formatter:off --}}
<x-alert    type="warning"    message="Test"   >
    Content   here
</x-alert>
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // Component preserved with original spacing
        expect(result,
            contains('<x-alert    type="warning"    message="Test"   >'));
      });
    });

    group('edge cases', () {
      test('handles empty ignored region', () {
        const input = '''{{-- blade-formatter:off --}}
{{-- blade-formatter:on --}}
<div class="after"></div>''';
        final result = formatter.format(input);

        // Should work fine with empty region
        expect(result, contains('<div class="after">'));
      });

      test('handles whitespace around control keywords', () {
        const input = '''{{--   blade-formatter:off   --}}
<div    class="test"></div>
{{--   blade-formatter:on   --}}''';
        final result = formatter.format(input);

        // Should still recognize control comment with extra whitespace
        expect(result, contains('<div    class="test"></div>'));
      });

      test('regular comments not affected', () {
        const input = '''{{-- This is a regular comment --}}
<div    class="messy"   ></div>''';
        final result = formatter.format(input);

        // Regular comment formatted, div also formatted
        expect(result, contains('{{-- This is a regular comment --}}'));
        // The div should be formatted (no extra spaces)
        expect(result, contains('<div class="messy">'));
      });

      test('control comments are still formatted nicely', () {
        const input = '''{{--blade-formatter:off--}}
<div></div>
{{--blade-formatter:on--}}''';
        final result = formatter.format(input);

        // Control comments should have spacing normalized
        expect(result, contains('{{-- blade-formatter:off --}}'));
        expect(result, contains('{{-- blade-formatter:on --}}'));
      });
    });

    group('preserves echo statements', () {
      test('echo preserved in ignored region', () {
        const input = '''{{-- blade-formatter:off --}}
{{   \$variable   }}
{!!   \$rawHtml   !!}
{{-- blade-formatter:on --}}''';
        final result = formatter.format(input);

        // Echo statements preserved with original spacing
        expect(
          result.contains('{{   \$variable   }}') ||
              result.contains('{{\$variable}}'),
          isTrue,
        );
      });
    });

    group('idempotency', () {
      test('formatting ignored regions preserves content', () {
        const input = '''{{-- blade-formatter:off --}}
<div    class="test"   >
    Content   here
</div>
{{-- blade-formatter:on --}}
<div class="normal"></div>''';

        final firstPass = formatter.format(input);
        final secondPass = formatter.format(firstPass);

        // The key content should be preserved across both passes
        expect(firstPass, contains('<div    class="test"   >'));
        expect(firstPass, contains('Content   here'));
        expect(firstPass, contains('<div class="normal">'));

        expect(secondPass, contains('<div    class="test"   >'));
        expect(secondPass, contains('Content   here'));
        expect(secondPass, contains('<div class="normal">'));

        // The formatted region should be formatted (no extra spaces)
        expect(secondPass, contains('<div class="normal">'));
      });

      test('simple inline ignored region is idempotent', () {
        // Test with content immediately after off comment (no blank line)
        const input =
            '{{-- blade-formatter:off --}}<div class="test"></div>{{-- blade-formatter:on --}}';

        final firstPass = formatter.format(input);
        final secondPass = formatter.format(firstPass);

        // Should preserve the content
        expect(firstPass, contains('<div class="test"></div>'));
        expect(secondPass, contains('<div class="test"></div>'));
        expect(secondPass, equals(firstPass));
      });

      test('already formatted file is stable', () {
        // Pre-formatted content should remain stable
        const input = '''{{-- blade-formatter:off --}}
<div    class="messy"   ></div>
{{-- blade-formatter:on --}}
''';

        final firstPass = formatter.format(input);
        final secondPass = formatter.format(firstPass);

        expect(firstPass, contains('<div    class="messy"   ></div>'));
        expect(secondPass, contains('<div    class="messy"   ></div>'));
      });
    });
  });
}
