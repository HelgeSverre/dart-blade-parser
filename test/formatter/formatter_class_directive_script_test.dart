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

    test('@class directive in html tag is preserved exactly', () {
      const input =
          '<html lang="en" @class([\'dark\' => (\$appearance ?? \'system\') == \'dark\'])></html>';
      final result = formatter.format(input);

      expect(
        result,
        equals(
          '<html lang="en" @class([\'dark\' => (\$appearance ?? \'system\') == \'dark\'])></html>\n',
        ),
      );
    });

    test('script block with Blade echo preserves content exactly', () {
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

      expect(
        result,
        equals('''<script>
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
'''),
      );
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

      expect(
        result,
        equals('''<!DOCTYPE html>
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
</html>
'''),
      );
    });

    test('formatter is idempotent for script with Blade comment', () {
      const input = '''<script>
    const config = {!! json_encode(\$config) !!};
    {{-- TODO: remove this --}}
    const x = 1;
</script>''';

      final pass1 = formatter.format(input);
      final pass2 = formatter.format(pass1);
      final pass3 = formatter.format(pass2);

      expect(pass2, equals(pass1), reason: 'Second pass should equal first');
      expect(pass3, equals(pass2), reason: 'Third pass should equal second');
    });

    test('multiple Blade expression types in script block', () {
      const input = '''<script>
    const config = {!! json_encode(\$config) !!};
    const name = '{{ \$name }}';
    {{-- TODO: remove this --}}
    const items = {!! \$items !!};
</script>''';

      final result = formatter.format(input);

      expect(
        result,
        equals('''<script>
    const config = {!! json_encode(\$config) !!};
    const name = '{{ \$name }}';
    {{-- TODO: remove this --}}
    const items = {!! \$items !!};
</script>
'''),
      );
    });

    test('style block with Blade echo', () {
      const input = '''<style>
    body { color: {{ \$color }}; }
    .dark { background: {{ \$bgColor }}; }
</style>''';

      final result = formatter.format(input);

      expect(
        result,
        equals('''<style>
    body { color: {{ \$color }}; }
    .dark { background: {{ \$bgColor }}; }
</style>
'''),
      );
    });

    test('@class with attribute wrapping', () {
      const input =
          '<div class="base" id="el" data-controller="component" data-action="click->component#toggle" @class([\'active\' => \$isActive, \'hidden\' => \$isHidden]) wire:model="name">Content</div>';

      final result = formatter.format(input);

      // Should wrap and keep @class intact
      expect(result, contains("@class(['active' => \$isActive"));
      expect(result, isNot(contains('@class=')));
    });
  });
}
