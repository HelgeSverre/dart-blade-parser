import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('EditorConfig Parser', () {
    group('Basic parsing', () {
      test('parses empty config', () {
        final config = EditorConfig.parse('');
        expect(config.sections, isEmpty);
        expect(config.isRoot, isFalse);
      });

      test('parses root declaration', () {
        final config = EditorConfig.parse('root = true');
        expect(config.isRoot, isTrue);
      });

      test('parses root declaration case-insensitive', () {
        final config = EditorConfig.parse('ROOT = TRUE');
        expect(config.isRoot, isTrue);
      });

      test('ignores comments with #', () {
        final config = EditorConfig.parse('''
# This is a comment
root = true
# Another comment
''');
        expect(config.isRoot, isTrue);
        expect(config.sections, isEmpty);
      });

      test('ignores comments with ;', () {
        final config = EditorConfig.parse('''
; This is a comment
root = true
''');
        expect(config.isRoot, isTrue);
      });

      test('parses single section', () {
        final config = EditorConfig.parse('''
[*]
indent_style = space
indent_size = 4
''');
        expect(config.sections.length, equals(1));
        expect(config.sections[0].pattern, equals('*'));
        expect(config.sections[0].properties['indent_style'], equals('space'));
        expect(config.sections[0].properties['indent_size'], equals('4'));
      });

      test('parses multiple sections', () {
        final config = EditorConfig.parse('''
[*]
indent_style = space
indent_size = 4

[*.blade.php]
indent_size = 2

[*.js]
indent_style = tab
''');
        expect(config.sections.length, equals(3));
        expect(config.sections[0].pattern, equals('*'));
        expect(config.sections[1].pattern, equals('*.blade.php'));
        expect(config.sections[2].pattern, equals('*.js'));
      });

      test('normalizes property keys to lowercase', () {
        final config = EditorConfig.parse('''
[*]
INDENT_STYLE = space
Indent_Size = 4
TAB_WIDTH = 2
''');
        expect(config.sections[0].properties['indent_style'], equals('space'));
        expect(config.sections[0].properties['indent_size'], equals('4'));
        expect(config.sections[0].properties['tab_width'], equals('2'));
      });
    });

    group('Pattern matching', () {
      test('matches wildcard [*]', () {
        final section = EditorConfigSection(
          pattern: '*',
          properties: {'indent_size': '4'},
        );
        expect(section.matches('test.blade.php'), isTrue);
        expect(section.matches('anything.txt'), isTrue);
      });

      test('matches extension pattern *.blade.php', () {
        final section = EditorConfigSection(
          pattern: '*.blade.php',
          properties: {'indent_size': '2'},
        );
        expect(section.matches('test.blade.php'), isTrue);
        expect(section.matches('layout.blade.php'), isTrue);
        expect(section.matches('test.php'), isFalse);
        expect(section.matches('test.blade'), isFalse);
      });

      test('matches simple extension *.js', () {
        final section = EditorConfigSection(
          pattern: '*.js',
          properties: {},
        );
        expect(section.matches('app.js'), isTrue);
        expect(section.matches('test.ts'), isFalse);
      });

      test('matches exact filename', () {
        final section = EditorConfigSection(
          pattern: 'Makefile',
          properties: {},
        );
        expect(section.matches('Makefile'), isTrue);
        expect(section.matches('makefile'), isFalse);
        expect(section.matches('Makefile.txt'), isFalse);
      });

      test('matches brace alternatives {*.html,*.blade.php}', () {
        final section = EditorConfigSection(
          pattern: '{*.html,*.blade.php}',
          properties: {},
        );
        expect(section.matches('test.html'), isTrue);
        expect(section.matches('layout.blade.php'), isTrue);
        expect(section.matches('test.css'), isFalse);
      });
    });

    group('getProperties', () {
      test('returns merged properties for matching sections', () {
        final config = EditorConfig.parse('''
[*]
indent_style = space
indent_size = 4

[*.blade.php]
indent_size = 2
''');
        final props = config.getProperties('test.blade.php');
        expect(props['indent_style'], equals('space'));
        expect(props['indent_size'], equals('2')); // Overridden by more specific section
      });

      test('returns empty map for non-matching file', () {
        final config = EditorConfig.parse('''
[*.js]
indent_size = 2
''');
        final props = config.getProperties('test.blade.php');
        // Only wildcard [*] matches, but there isn't one
        expect(props, isEmpty);
      });

      test('later sections override earlier ones', () {
        final config = EditorConfig.parse('''
[*]
indent_size = 4

[*.php]
indent_size = 3

[*.blade.php]
indent_size = 2
''');
        final props = config.getProperties('layout.blade.php');
        expect(props['indent_size'], equals('2'));
      });
    });

    group('Real-world examples', () {
      test('typical Laravel project editorconfig', () {
        final config = EditorConfig.parse('''
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.blade.php]
indent_size = 2
''');
        expect(config.isRoot, isTrue);

        final bladeProps = config.getProperties('welcome.blade.php');
        expect(bladeProps['charset'], equals('utf-8'));
        expect(bladeProps['indent_style'], equals('space'));
        expect(bladeProps['indent_size'], equals('2')); // Override from *.blade.php

        final mdProps = config.getProperties('README.md');
        expect(mdProps['indent_size'], equals('4'));
        expect(mdProps['trim_trailing_whitespace'], equals('false'));
      });

      test('tabs configuration', () {
        final config = EditorConfig.parse('''
[*]
indent_style = tab
tab_width = 4
''');
        final props = config.getProperties('test.blade.php');
        expect(props['indent_style'], equals('tab'));
        expect(props['tab_width'], equals('4'));
      });
    });
  });
}
