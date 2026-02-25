import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Regression test for the bug reported where:
/// 1. @class directive inside HTML tags was being broken/mangled
/// 2. Blade expressions {{ }} inside <script> blocks were not working
void main() {
  group('Formatter: @class directive and script block regression', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('@class directive in html tag is preserved', () {
      const input =
          '<html lang="en" @class([\'dark\' => (\$appearance ?? \'system\') == \'dark\'])></html>';
      final result = formatter.format(input);

      // @class directive should be preserved intact
      expect(result, contains('@class'));
      expect(result, contains("'dark'"));
      // The @class(...) should NOT be broken across lines
      expect(
        result,
        isNot(contains('@class dark')),
        reason: '@class should not be split from its expression',
      );
    });

    test('script block with Blade echo preserves content correctly', () {
      const input = '''<script>
    (function() {
        const appearance = '{{ \$appearance ?? "system" }}';
        if (appearance === "system") {
            const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
            if (prefersDark) {
                document.documentElement.classList.add("dark");
            }
        }
    })();
</script>''';

      final result = formatter.format(input);

      // The {{ }} expression should be preserved
      expect(
        result,
        contains('{{ \$appearance ?? "system" }}'),
        reason: 'Blade echo inside script should be preserved',
      );
      // The script content should not be mangled
      expect(result, contains('appearance === "system"'));
      expect(result, contains('classList.add("dark")'));
    });

    test('full template from bug report formats correctly', () {
      const input = '''<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" @class(['dark' => (\$appearance ?? 'system') == 'dark'])>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        {{-- Inline script to detect system dark mode preference and apply it immediately --}}
        <script>
            (function() {
                const appearance = '{{ \$appearance ?? "system" }}';
                if (appearance === "system") {
                    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                    if (prefersDark) {
                        document.documentElement.classList.add("dark");
                    }
                }
            })();
        </script>
        @vite('resources/sass/app.scss')
        <title inertia>{{ config('app.name', 'Laravel') }}</title>
        <link href="/favicon.svg" rel="icon" type="image/svg+xml">
        @inertiaHead
    </head>
    <body class="font-sans antialiased">
        @inertia
    </body>
</html>''';

      final result = formatter.format(input);

      // @class should be intact on the same line as <html>
      expect(
        result,
        contains('@class'),
        reason: '@class directive should be preserved',
      );

      // @class should NOT be broken into "@class dark" and expression on next line
      expect(
        result,
        isNot(contains('@class dark')),
        reason: '@class should not be separated from its expression',
      );

      // Script content should contain Blade echo
      expect(
        result,
        contains('\$appearance'),
        reason: 'Blade expression in script should be preserved',
      );

      // The script should not mangle JS comparison operators
      expect(
        result,
        contains('appearance === "system"'),
        reason: 'JS code in script should be preserved',
      );
    });
  });
}
