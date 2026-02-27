import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('SlotNameStyle', () {
    group('colon (default)', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotNameStyle: SlotNameStyle.colon),
      );

      test('keeps colon syntax as-is', () {
        const input = '<x-card><x-slot:header><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot:header>'));
      });

      test('converts attribute syntax to colon syntax', () {
        const input =
            '<x-card><x-slot name="header"><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot:header>'));
        expect(result, isNot(contains('name="header"')));
      });
    });

    group('attribute', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotNameStyle: SlotNameStyle.attribute),
      );

      test('converts colon syntax to attribute syntax', () {
        const input = '<x-card><x-slot:header><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot name="header"'));
        expect(result, isNot(contains('<x-slot:header')));
      });

      test('keeps attribute syntax as-is', () {
        const input =
            '<x-card><x-slot name="header"><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot name="header"'));
        expect(result, isNot(contains('<x-slot:header')));
      });

      test('preserves extra attributes when converting from colon', () {
        const input =
            '<x-card><x-slot:header class="font-bold"><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot name="header"'));
        expect(result, contains('class="font-bold"'));
      });

      test('preserves extra attributes with attribute syntax', () {
        const input =
            '<x-card><x-slot name="header" class="font-bold"><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot name="header"'));
        expect(result, contains('class="font-bold"'));
      });
    });

    group('preserve', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(slotNameStyle: SlotNameStyle.preserve),
      );

      test('preserves colon syntax', () {
        const input = '<x-card><x-slot:header><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot:header>'));
      });

      test('preserves attribute syntax', () {
        const input =
            '<x-card><x-slot name="header"><h2>Title</h2></x-slot></x-card>';
        final result = formatter.format(input);
        expect(result, contains('<x-slot name="header"'));
        expect(result, isNot(contains('<x-slot:header')));
      });
    });

    group('config serialization', () {
      test('fromMap parses slot_name_style', () {
        final config =
            FormatterConfig.fromMap({'slot_name_style': 'attribute'});
        expect(config.slotNameStyle, SlotNameStyle.attribute);
      });

      test('fromMap parses preserve', () {
        final config = FormatterConfig.fromMap({'slot_name_style': 'preserve'});
        expect(config.slotNameStyle, SlotNameStyle.preserve);
      });

      test('fromMap defaults to colon for unknown value', () {
        final config = FormatterConfig.fromMap({'slot_name_style': 'unknown'});
        expect(config.slotNameStyle, SlotNameStyle.colon);
      });

      test('toMap includes slot_name_style', () {
        const config = FormatterConfig(slotNameStyle: SlotNameStyle.attribute);
        final map = config.toMap();
        expect(map['slot_name_style'], 'attribute');
      });

      test('default config uses colon', () {
        const config = FormatterConfig();
        expect(config.slotNameStyle, SlotNameStyle.colon);
      });
    });
  });
}
