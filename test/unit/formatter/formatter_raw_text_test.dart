import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/formatter_visitor.dart';

void main() {
  group('Formatter raw text elements (script/style/textarea)', () {
    late BladeParser parser;
    late FormatterVisitor formatter;

    setUp(() {
      parser = BladeParser();
      formatter = FormatterVisitor(FormatterConfig());
    });

    String format(String input) {
      final result = parser.parse(input);
      return formatter.format(result.ast!);
    }

    group('script tag indentation preservation', () {
      test('preserves relative indentation of nested JS inside script', () {
        final input = '''<script>
    (function() {
        const x = 1;

        if (x) {
            console.log(x);
        }
    })();
</script>''';
        final output = format(input);
        // The nested structure should be preserved
        expect(output, contains('    (function() {'));
        expect(output, contains('        const x = 1;'));
        expect(output, contains('        if (x) {'));
        expect(output, contains('            console.log(x);'));
        expect(output, contains('        }'));
        expect(output, contains('    })();'));
      });

      test('re-indents script content to match surrounding indent level', () {
        final input = '''<div>
    <script>
        (function() {
            const x = 1;
        })();
    </script>
</div>''';
        final output = format(input);
        // Script tag should be indented inside div
        expect(output, contains('    <script>'));
        // JS content should preserve its relative indentation
        // The base indent of content is 8 spaces, current indent is 8 (2 levels × 4)
        expect(output, contains('        (function() {'));
        expect(output, contains('            const x = 1;'));
        expect(output, contains('        })();'));
        expect(output, contains('    </script>'));
      });

      test('preserves script with Blade echo inside', () {
        final input = '''<script>
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
        final output = format(input);
        // The script tag itself should be present
        expect(output, contains('<script>'));
        expect(output, contains('</script>'));
        // Blade echo inside script should be preserved
        expect(output, contains('{{ \$appearance ?? "system" }}'));
      });

      test('handles empty script tag', () {
        final output = format('<script></script>');
        expect(output.trim(), equals('<script></script>'));
      });

      test('handles script with single line content', () {
        final output = format('<script>alert(1);</script>');
        expect(output, contains('alert(1);'));
        expect(output, contains('<script>'));
        expect(output, contains('</script>'));
      });

      test('handles script with src attribute (no content)', () {
        final output = format('<script src="/app.js"></script>');
        expect(output, contains('<script src="/app.js">'));
        expect(output, contains('</script>'));
      });

      test('kitchen sink example from screenshot preserves indentation', () {
        final input = '''<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">

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
</head>
<body class="font-sans antialiased">
    @inertia
</body>
</html>''';
        final output = format(input);
        // Script content should have preserved relative indentation
        // Inside <head> (indent 1) > <script> content (indent 2 base)
        expect(output, contains('(function() {'));
        // Nested levels should be deeper than the function wrapper
        final lines = output.split('\n');
        final functionLine = lines.firstWhere((l) => l.contains('(function() {'));
        final constLine = lines.firstWhere((l) => l.contains("const appearance"));
        final ifLine = lines.firstWhere((l) => l.contains('if (appearance'));
        final prefersLine = lines.firstWhere((l) => l.contains('const prefersDark'));

        // Each nesting level should have more indentation
        final functionIndent = functionLine.length - functionLine.trimLeft().length;
        final constIndent = constLine.length - constLine.trimLeft().length;
        final ifIndent = ifLine.length - ifLine.trimLeft().length;
        final prefersIndent = prefersLine.length - prefersLine.trimLeft().length;

        expect(constIndent, greaterThan(functionIndent),
            reason: 'const should be indented more than function');
        expect(ifIndent, greaterThan(functionIndent),
            reason: 'if should be indented more than function');
        expect(prefersIndent, greaterThan(ifIndent),
            reason: 'prefersDark should be indented more than if');
      });

      test('is idempotent for script with nested JS', () {
        final input = '''<script>
    (function() {
        const x = 1;
        if (x) {
            console.log(x);
        }
    })();
</script>''';
        final first = format(input);
        final second = format(first);
        expect(first, equals(second),
            reason: 'Script formatting should be idempotent');
      });

      test('is idempotent for script nested inside elements', () {
        final input = '''<div>
    <script>
        const x = 1;
        if (x) {
            console.log(x);
        }
    </script>
</div>''';
        final first = format(input);
        final second = format(first);
        expect(first, equals(second),
            reason: 'Nested script formatting should be idempotent');
      });
    });

    group('style tag indentation preservation', () {
      test('preserves relative indentation of CSS inside style', () {
        final input = '''<style>
    .container {
        display: flex;
        align-items: center;
    }

    .container .child {
        margin: 0 auto;
    }
</style>''';
        final output = format(input);
        expect(output, contains('.container {'));
        expect(output, contains('    display: flex;'));
        expect(output, contains('    align-items: center;'));
        expect(output, contains('.container .child {'));
      });

      test('preserves nested style tag indentation', () {
        final input = '''<head>
    <style>
        body {
            margin: 0;
        }
    </style>
</head>''';
        final output = format(input);
        expect(output, contains('    <style>'));
        expect(output, contains('body {'));
        expect(output, contains('    margin: 0;'));
        expect(output, contains('    </style>'));
      });

      test('is idempotent for style tags', () {
        final input = '''<style>
    .foo {
        color: red;
    }
    .bar {
        color: blue;
    }
</style>''';
        final first = format(input);
        final second = format(first);
        expect(first, equals(second),
            reason: 'Style formatting should be idempotent');
      });

      test('handles empty style tag', () {
        final output = format('<style></style>');
        expect(output.trim(), equals('<style></style>'));
      });
    });

    group('textarea tag indentation preservation', () {
      test('preserves textarea content exactly', () {
        final input = '''<textarea>
Line 1
    Indented line 2
        Double indented line 3
</textarea>''';
        final output = format(input);
        expect(output, contains('Line 1'));
        expect(output, contains('    Indented line 2'));
        expect(output, contains('        Double indented line 3'));
      });

      test('is idempotent for textarea', () {
        final input = '''<textarea>
Some text
    Indented text
</textarea>''';
        final first = format(input);
        final second = format(first);
        expect(first, equals(second),
            reason: 'Textarea formatting should be idempotent');
      });
    });

    group('edge cases', () {
      test('script with no indentation in content', () {
        final input = '''<script>
var x = 1;
var y = 2;
</script>''';
        final output = format(input);
        expect(output, contains('var x = 1;'));
        expect(output, contains('var y = 2;'));
      });

      test('script with tab indentation', () {
        final input = '<script>\n\tfunction foo() {\n\t\treturn 1;\n\t}\n</script>';
        final output = format(input);
        // Should preserve relative indentation structure
        final lines = output.split('\n');
        final funcLine = lines.firstWhere((l) => l.contains('function foo'));
        final returnLine = lines.firstWhere((l) => l.contains('return 1'));
        final funcIndent = funcLine.length - funcLine.trimLeft().length;
        final returnIndent = returnLine.length - returnLine.trimLeft().length;
        expect(returnIndent, greaterThan(funcIndent),
            reason: 'return should be indented more than function');
      });

      test('script with mixed content and blank lines', () {
        final input = '''<script>
    // First block
    const a = 1;

    // Second block
    const b = 2;
</script>''';
        final output = format(input);
        expect(output, contains('// First block'));
        expect(output, contains('const a = 1;'));
        expect(output, contains('// Second block'));
        expect(output, contains('const b = 2;'));
      });

      test('multiple script tags in same document', () {
        final input = '''<script>
    const a = 1;
    if (a) {
        console.log(a);
    }
</script>
<script>
    const b = 2;
    if (b) {
        console.log(b);
    }
</script>''';
        final output = format(input);
        // Both scripts should have preserved indentation
        expect(output, contains('const a = 1;'));
        expect(output, contains('const b = 2;'));
        // Both should have nested if blocks
        final lines = output.split('\n');
        final logLines = lines.where((l) => l.contains('console.log')).toList();
        expect(logLines.length, equals(2));
        for (final logLine in logLines) {
          final indent = logLine.length - logLine.trimLeft().length;
          expect(indent, greaterThan(0),
              reason: 'console.log should be indented inside if block');
        }
      });

      test('script inside blade directive', () {
        final input = '''@if(\$showScript)
    <script>
        const x = 1;
        if (x) {
            doSomething();
        }
    </script>
@endif''';
        final output = format(input);
        expect(output, contains('<script>'));
        expect(output, contains('</script>'));
        // Verify relative indentation is preserved
        final lines = output.split('\n');
        final constLine = lines.firstWhere((l) => l.contains('const x'));
        final doLine = lines.firstWhere((l) => l.contains('doSomething'));
        final constIndent = constLine.length - constLine.trimLeft().length;
        final doIndent = doLine.length - doLine.trimLeft().length;
        expect(doIndent, greaterThan(constIndent),
            reason: 'doSomething should be nested deeper than const');
      });

      test('style inside blade component', () {
        final input = '''<x-layout>
    <style>
        .foo {
            color: red;
        }
    </style>
</x-layout>''';
        final output = format(input);
        expect(output, contains('<style>'));
        expect(output, contains('</style>'));
        final lines = output.split('\n');
        final selectorLine = lines.firstWhere((l) => l.contains('.foo {'));
        final propertyLine = lines.firstWhere((l) => l.contains('color: red'));
        final selectorIndent = selectorLine.length - selectorLine.trimLeft().length;
        final propertyIndent = propertyLine.length - propertyLine.trimLeft().length;
        expect(propertyIndent, greaterThan(selectorIndent),
            reason: 'CSS property should be indented inside selector');
      });

      test('pre tag preserves content exactly', () {
        final input = '''<pre>
    code here
        indented
    back
</pre>''';
        final output = format(input);
        // Pre tags should also preserve content
        expect(output, contains('    code here'));
        expect(output, contains('        indented'));
        expect(output, contains('    back'));
      });

      test('script with deeply nested JS preserves all levels', () {
        final input = '''<script>
    function outer() {
        function middle() {
            function inner() {
                return true;
            }
        }
    }
</script>''';
        final output = format(input);
        final lines = output.split('\n');
        final outerLine = lines.firstWhere((l) => l.contains('function outer'));
        final middleLine = lines.firstWhere((l) => l.contains('function middle'));
        final innerLine = lines.firstWhere((l) => l.contains('function inner'));
        final returnLine = lines.firstWhere((l) => l.contains('return true'));

        final outerIndent = outerLine.length - outerLine.trimLeft().length;
        final middleIndent = middleLine.length - middleLine.trimLeft().length;
        final innerIndent = innerLine.length - innerLine.trimLeft().length;
        final returnIndent = returnLine.length - returnLine.trimLeft().length;

        expect(middleIndent, greaterThan(outerIndent));
        expect(innerIndent, greaterThan(middleIndent));
        expect(returnIndent, greaterThan(innerIndent));
      });

      test('non-raw-text elements still format normally', () {
        final input = '''<div>
                  <p>text</p>
                          <span>more</span>
        </div>''';
        final output = format(input);
        // Normal elements should still be reformatted/re-indented
        expect(output, contains('    <p>text</p>'));
        expect(output, contains('    <span>more</span>'));
      });
    });
  });
}
