import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('SlotSpacing', () {
    const input = '<x-card>'
        '<x-slot:header><h2>Title</h2></x-slot>'
        '<p>Content</p>'
        '<x-slot:footer><button>Action</button></x-slot>'
        '</x-card>';

    group('none', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.none),
      );

      test('no blank lines around slots', () {
        final result = formatter.format(input);
        expect(result, isNot(contains('</x-slot>\n\n')));
        // Slot closing should be immediately followed by next element
        final lines = result.split('\n');
        for (var i = 0; i < lines.length - 1; i++) {
          if (lines[i].trim() == '</x-slot>') {
            expect(lines[i + 1].trim(), isNotEmpty,
                reason: 'No blank line after slot');
          }
        }
      });
    });

    group('after', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.after),
      );

      test('blank line after slot closing tag', () {
        final result = formatter.format(input);
        // After </x-slot> there should be a blank line before <p>
        expect(result, contains('</x-slot>\n\n'));
      });

      test('blank line appears after header slot before footer slot', () {
        final result = formatter.format(input);
        // In after mode, the blank line after header slot naturally
        // appears before the footer slot as well
        final lines = result.split('\n');
        for (var i = 0; i < lines.length - 1; i++) {
          if (lines[i].trim() == '</x-slot>' &&
              i + 2 < lines.length &&
              lines[i + 2].trim().startsWith('<x-slot:footer')) {
            expect(lines[i + 1].trim(), isEmpty,
                reason: 'Blank line after header slot');
          }
        }
      });
    });

    group('before', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.before),
      );

      test('blank line before slot opening tag', () {
        final result = formatter.format(input);
        // Before second slot there should be a blank line
        final lines = result.split('\n');
        for (var i = 1; i < lines.length; i++) {
          if (lines[i].trim().startsWith('<x-slot:footer')) {
            expect(lines[i - 1].trim(), isEmpty,
                reason: 'Blank line before slot in before mode');
          }
        }
      });

      test('no blank line after slot closing tag', () {
        final result = formatter.format(input);
        // After first </x-slot> followed by <p>, no blank line
        final lines = result.split('\n');
        for (var i = 0; i < lines.length - 1; i++) {
          if (lines[i].trim() == '</x-slot>' &&
              i + 1 < lines.length &&
              lines[i + 1].trim().startsWith('<p>')) {
            expect(lines[i + 1].trim(), isNotEmpty,
                reason: 'No blank line after slot in before mode');
          }
        }
      });
    });

    group('around', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.around),
      );

      test('blank lines both before and after slots', () {
        final result = formatter.format(input);
        // After </x-slot> there should be a blank line
        expect(result, contains('</x-slot>\n\n'));

        // Before second slot there should be a blank line
        final lines = result.split('\n');
        for (var i = 1; i < lines.length; i++) {
          if (lines[i].trim().startsWith('<x-slot:footer')) {
            expect(lines[i - 1].trim(), isEmpty,
                reason: 'Blank line before slot in around mode');
          }
        }
      });
    });

    group('slot followed by slot', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.after),
      );

      test('blank line between sibling slots', () {
        const siblingSlots = '<x-card>'
            '<x-slot:header><h2>Title</h2></x-slot>'
            '<x-slot:footer><button>OK</button></x-slot>'
            '</x-card>';
        final result = formatter.format(siblingSlots);
        // After first slot, blank line before second slot
        expect(result, contains('</x-slot>\n\n'));
      });
    });

    group('slot followed by directive', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.after),
      );

      test('blank line between slot and directive', () {
        const slotDirective = '<x-card>'
            '<x-slot:header><h2>Title</h2></x-slot>'
            '@if(true)<p>Yes</p>@endif'
            '</x-card>';
        final result = formatter.format(slotDirective);
        expect(result, contains('</x-slot>\n\n'));
      });
    });

    group('slot followed by HTML element', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotSpacing: SlotSpacing.after),
      );

      test('blank line between slot and HTML element', () {
        const slotHtml = '<x-card>'
            '<x-slot:header><h2>Title</h2></x-slot>'
            '<div>Content</div>'
            '</x-card>';
        final result = formatter.format(slotHtml);
        expect(result, contains('</x-slot>\n\n'));
      });
    });

    group('config serialization', () {
      test('fromMap parses slot_spacing', () {
        final config = FormatterConfig.fromMap({'slot_spacing': 'around'});
        expect(config.slotSpacing, SlotSpacing.around);
      });

      test('fromMap defaults to after for unknown value', () {
        final config = FormatterConfig.fromMap({'slot_spacing': 'unknown'});
        expect(config.slotSpacing, SlotSpacing.after);
      });

      test('toMap includes slot_spacing', () {
        const config = FormatterConfig(slotSpacing: SlotSpacing.before);
        final map = config.toMap();
        expect(map['slot_spacing'], 'before');
      });

      test('default config uses after', () {
        const config = FormatterConfig();
        expect(config.slotSpacing, SlotSpacing.after);
      });
    });
  });
}
