import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Formatter Idempotency', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    /// Helper to test idempotency for a given input
    void expectIdempotent(String input, {String? description}) {
      final formatted1 = formatter.format(input);
      final formatted2 = formatter.format(formatted1);

      expect(
        formatted2,
        formatted1,
        reason: 'Formatter should be idempotent: format(format(x)) == format(x)'
            '${description != null ? " ($description)" : ""}',
      );
    }

    group('basic structures', () {
      test('simple echo', () {
        expectIdempotent('<div>{{ \$user }}</div>');
      });

      test('directive', () {
        expectIdempotent('@if(\$x)\n<p>test</p>\n@endif');
      });

      test('nested directives', () {
        expectIdempotent(
            '@if(\$a)\n@if(\$b)\n<p>deep</p>\n@endif\n@endif');
      });

      test('component', () {
        expectIdempotent('<x-alert>Hello</x-alert>');
      });

      test('component with slots', () {
        expectIdempotent('''
<x-card>
    <x-slot:header>
        <h2>Title</h2>
    </x-slot>
    <p>Content</p>
</x-card>
''');
      });
    });

    group('mixed content', () {
      test('HTML and Blade mixed', () {
        expectIdempotent('''
<div class="container">
    @foreach(\$items as \$item)
        <div class="item">
            <h3>{{ \$item->title }}</h3>
            <p>{{ \$item->description }}</p>
        </div>
    @endforeach
</div>
''');
      });

      test('deeply nested', () {
        expectIdempotent('''
<div>
    @if(\$user)
        @if(\$user->isAdmin())
            @foreach(\$permissions as \$permission)
                <span>{{ \$permission->name }}</span>
            @endforeach
        @endif
    @endif
</div>
''');
      });
    });

    group('all existing test fixtures', () {
      test('formats all valid fixtures idempotently', () {
        final fixturesDir = Directory('test/fixtures/valid');

        if (!fixturesDir.existsSync()) {
          print('Fixtures directory not found, skipping fixture tests');
          return;
        }

        final bladeFiles = fixturesDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.blade.php'))
            .toList();

        print('Testing ${bladeFiles.length} fixture files for idempotency');

        for (final file in bladeFiles) {
          final content = file.readAsStringSync();
          final relativePath = file.path.replaceFirst(
            '${Directory.current.path}/',
            '',
          );

          try {
            expectIdempotent(content, description: relativePath);
          } catch (e) {
            fail('Idempotency failed for $relativePath: $e');
          }
        }
      });
    });

    group('edge cases', () {
      test('empty file', () {
        expectIdempotent('');
      });

      test('only whitespace', () {
        const input = '   \n\n   ';
        final formatted = formatter.format(input);
        // Empty or whitespace-only files should produce minimal output
        expect(formatted, isIn(['', '\n']));
      });

      test('comments', () {
        expectIdempotent('{{-- Comment --}}');
        expectIdempotent('<!-- HTML Comment -->');
      });

      test('raw echo', () {
        expectIdempotent('<div>{!! \$html !!}</div>');
      });

      test('void elements', () {
        expectIdempotent('<img src="test.jpg">');
        expectIdempotent('<br>');
        expectIdempotent('<input type="text">');
      });

      test('self-closing component', () {
        expectIdempotent('<x-button label="Click" />');
      });
    });

    group('whitespace handling', () {
      test('preserves meaningful whitespace', () {
        const input = '<span>Hello</span> <span>World</span>';
        final formatted1 = formatter.format(input);
        final formatted2 = formatter.format(formatted1);

        expect(formatted2, formatted1);
        // Should preserve the space between spans
        expect(formatted1, contains('Hello'));
        expect(formatted1, contains('World'));
      });

      test('normalizes excessive whitespace', () {
        const input = '<div>   \n\n\n   {{ \$user }}   \n\n   </div>';
        final formatted1 = formatter.format(input);
        final formatted2 = formatter.format(formatted1);

        expect(formatted2, formatted1);
      });
    });

    group('configuration variations', () {
      test('2-space indent is idempotent', () {
        final formatter2 = BladeFormatter(
          config: const FormatterConfig(indentSize: 2),
        );

        const input = '@if(\$x)\n<p>test</p>\n@endif';
        final formatted1 = formatter2.format(input);
        final formatted2 = formatter2.format(formatted1);

        expect(formatted2, formatted1);
        expect(formatted1, contains('  <p>test</p>'));
      });

      test('tab indent is idempotent', () {
        final tabFormatter = BladeFormatter(
          config: const FormatterConfig(indentStyle: IndentStyle.tabs),
        );

        const input = '@if(\$x)\n<p>test</p>\n@endif';
        final formatted1 = tabFormatter.format(input);
        final formatted2 = tabFormatter.format(formatted1);

        expect(formatted2, formatted1);
        expect(formatted1, contains('\t<p>test</p>'));
      });

    });
  });
}
