import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for line wrapping and multi-line attribute formatting features.
void main() {
  group('Line Wrapping and Multi-line Attributes', () {
    group('WrapAttributes.auto (default)', () {
      test('does not wrap short attribute lists', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 80),
        );

        const input = '<div class="container" id="main">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('<div class="container" id="main">'));
      });

      test('wraps long attribute lists exceeding maxLineLength', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 60),
        );

        const input =
            '<div class="very-long-class-name" id="main-container" data-value="123">Content</div>';
        final result = formatter.format(input);

        // Should wrap to multiple lines
        expect(result, contains('<div\n'));
        expect(result, contains('class="very-long-class-name"'));
        expect(result, contains('id="main-container"'));
      });

      test('wraps component attributes when line is too long', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 60),
        );

        const input =
            '<x-alert type="success" message="Operation completed successfully" dismissible>Content</x-alert>';
        final result = formatter.format(input);

        // Should wrap to multiple lines
        expect(result, contains('<x-alert\n'));
        expect(result, contains('type="success"'));
        expect(result, contains('message="Operation completed successfully"'));
      });

      test('respects indentation when wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 60,
            indentSize: 4,
          ),
        );

        const input = '''
<div>
<input type="text" class="form-control" id="username" placeholder="Enter username">
</div>
''';
        final result = formatter.format(input);

        // Attributes should be indented relative to parent
        expect(result, contains('    <input\n'));
        expect(result, contains('        type="text"'));
      });

      test('does not wrap void elements unnecessarily', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 80),
        );

        const input = '<input type="text" name="email">';
        final result = formatter.format(input);

        expect(result.trim(), '<input type="text" name="email">');
      });

      test('wraps self-closing components', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 50),
        );

        const input =
            '<x-icon name="check" class="text-green-500" size="lg" />';
        final result = formatter.format(input);

        expect(result, contains('<x-icon\n'));
        expect(result, contains(' />'));
      });
    });

    group('WrapAttributes.always', () {
      test('wraps even short attribute lists', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input = '<div class="container" id="main">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('<div\n'));
        expect(result, contains('    class="container"'));
        expect(result, contains('    id="main">'));
      });

      test('does not wrap single attribute', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input = '<div class="container">Content</div>';
        final result = formatter.format(input);

        // Single attribute should stay on same line
        expect(result.trim(), '<div class="container">Content</div>');
      });

      test('wraps component attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input = '<x-button type="submit" class="btn">Click</x-button>';
        final result = formatter.format(input);

        expect(result, contains('<x-button\n'));
        expect(result, contains('type="submit"'));
        expect(result, contains('class="btn">'));
      });
    });

    group('WrapAttributes.never', () {
      test('never wraps regardless of line length', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            wrapAttributes: WrapAttributes.never,
            maxLineLength: 20,
          ),
        );

        const input =
            '<div class="very-long-class-name-that-exceeds-max-line-length" id="main" data-value="123">Content</div>';
        final result = formatter.format(input);

        // Should stay on single line
        expect(result, isNot(contains('<div\n')));
        expect(
            result,
            contains(
                '<div class="very-long-class-name-that-exceeds-max-line-length" id="main" data-value="123">'));
      });
    });

    group('Indentation with wrapping', () {
      test('maintains correct indentation for nested elements', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 50,
            indentSize: 4,
          ),
        );

        const input = '''
<div>
<section>
<input type="text" class="form-control" placeholder="Enter value" required>
</section>
</div>
''';
        final result = formatter.format(input);

        // Check proper nesting
        expect(result, contains('<div>'));
        expect(result, contains('    <section>'));
        expect(result, contains('        <input\n'));
        expect(result, contains('            type="text"'));
      });

      test('uses tabs when configured', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 50,
            indentStyle: IndentStyle.tabs,
            wrapAttributes: WrapAttributes.always,
          ),
        );

        const input = '<div class="container" id="main">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('\tclass="container"'));
        expect(result, contains('\tid="main">'));
      });
    });

    group('Edge cases', () {
      test('handles elements with no attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input = '<div>Content</div>';
        final result = formatter.format(input);

        expect(result.trim(), '<div>Content</div>');
      });

      test('handles boolean attributes when wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input = '<input type="checkbox" checked disabled required>';
        final result = formatter.format(input);

        expect(result, contains('checked'));
        expect(result, contains('disabled'));
        expect(result, contains('required'));
      });

      test('preserves attribute values with special characters', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 50,
          ),
        );

        const input =
            '<div data-config=\'{"key": "value"}\' class="container">Content</div>';
        final result = formatter.format(input);

        expect(result, isNotEmpty);
      });

      test('handles Blade echo in attributes', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input =
            '<div class="{{ \$class }}" id="item-{{ \$id }}">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('class="{{ \$class }}"'));
        expect(result, contains('id="item-{{ \$id }}"'));
      });

      test('handles Alpine.js attributes when wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input =
            '<div x-data="{ open: false }" @click="toggle" :class="{ active: open }">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('x-data="{ open: false }"'));
        expect(result, contains('@click="toggle"'));
        expect(result, contains(':class="{ active: open }">'));
      });

      test('handles wire: attributes when wrapping', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );

        const input =
            '<input type="text" wire:model="name" wire:loading.class="opacity-50">';
        final result = formatter.format(input);

        expect(result, contains('wire:model="name"'));
        expect(result, contains('wire:loading.class="opacity-50">'));
      });
    });

    group('maxLineLength configurations', () {
      test('respects maxLineLength of 80', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 80),
        );

        // This should be under 80 characters
        const shortInput = '<div class="short" id="a">Content</div>';
        final shortResult = formatter.format(shortInput);
        expect(shortResult, isNot(contains('<div\n')));

        // This should exceed 80 characters with indentation
        const longInput =
            '<div class="a-very-long-class-name" id="another-long-id" data-value="some-value">Content</div>';
        final longResult = formatter.format(longInput);
        expect(longResult, contains('<div\n'));
      });

      test('respects maxLineLength of 120', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 120),
        );

        // This should be under 120 characters
        const input =
            '<div class="a-very-long-class-name" id="another-long-id" data-value="some-value">Content</div>';
        final result = formatter.format(input);

        expect(result, isNot(contains('<div\n')));
      });

      test('respects maxLineLength of 40', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(maxLineLength: 40),
        );

        // This input should exceed 40 characters when including tag, attrs, and closing
        const input =
            '<div class="container" id="main" data-value="test">Content</div>';
        final result = formatter.format(input);

        // Should wrap at 40 characters
        expect(result, contains('<div\n'));
      });
    });

    group('Interaction with other formatting options', () {
      test('wrapping works with directive spacing', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 50,
            directiveSpacing: DirectiveSpacing.betweenBlocks,
          ),
        );

        const input = '''
@if(\$condition)
<div class="a-long-class-name" id="container" data-value="test">Content</div>
@endif
''';
        final result = formatter.format(input);

        expect(result, contains('@if(\$condition)'));
        expect(result, contains('<div\n'));
        expect(result, contains('@endif'));
      });

      test('wrapping works with slot formatting', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            maxLineLength: 50,
            slotFormatting: SlotFormatting.compact,
          ),
        );

        const input = '''
<x-card>
<x-slot:header class="bg-blue-500 text-white font-bold">
<h2>Title</h2>
</x-slot>
</x-card>
''';
        final result = formatter.format(input);

        expect(result, contains('<x-slot:header'));
      });
    });
  });
}
