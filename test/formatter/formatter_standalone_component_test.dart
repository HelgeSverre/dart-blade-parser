@Tags(['regression'])
library;

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Issue #18 follow-up: a self-closing component that is the sole child of an
/// element should preserve the author's block layout by default, and only
/// collapse onto the parent's line when [FormatterConfig.inlineSelfClosingComponents]
/// is enabled. Components in a text flow always stay inline.
void main() {
  final blockFormatter = BladeFormatter();
  final inlineFormatter = BladeFormatter(
    config: const FormatterConfig(inlineSelfClosingComponents: true),
  );

  group('standalone self-closing component: default (stay block)', () {
    test('sole child of anchor stays on its own line', () {
      const input = '<a href="x">\n    <x-component :y="\$y" />\n</a>';
      expect(
        blockFormatter.format(input),
        equals('<a href="x">\n    <x-component :y="\$y" />\n</a>\n'),
      );
    });

    test('sole child of div stays on its own line', () {
      const input = '<div>\n    <x-component :y="\$y" />\n</div>';
      expect(
        blockFormatter.format(input),
        equals('<div>\n    <x-component :y="\$y" />\n</div>\n'),
      );
    });

    test('two standalone components each keep their own line', () {
      const input = '<div>\n    <x-a />\n    <x-b />\n</div>';
      final out = blockFormatter.format(input);
      expect(out, contains('<x-a />'));
      expect(out, contains('<x-b />'));
      expect(out, isNot(contains('<x-a /><x-b />')));
    });

    test('is idempotent', () {
      const input = '<a href="x">\n    <x-component :y="\$y" />\n</a>';
      final first = blockFormatter.format(input);
      final second = blockFormatter.format(first);
      expect(second, equals(first));
    });
  });

  group('standalone self-closing component: opt-in collapse', () {
    test('sole child of anchor collapses inline', () {
      const input = '<a href="x">\n    <x-component :y="\$y" />\n</a>';
      expect(
        inlineFormatter.format(input),
        equals('<a href="x"><x-component :y="\$y" /></a>\n'),
      );
    });

    test('collapse is idempotent', () {
      const input = '<a href="x">\n    <x-component :y="\$y" />\n</a>';
      final first = inlineFormatter.format(input);
      final second = inlineFormatter.format(first);
      expect(second, equals(first));
    });
  });

  group('text-adjacent components always inline', () {
    test('component between text stays inline (default)', () {
      const input = 'Click <x-foo :bar="\$baz" /> here';
      expect(
        blockFormatter.format(input).trim(),
        equals('Click <x-foo :bar="\$baz" /> here'),
      );
    });

    test('component between text inside <p> stays inline (default)', () {
      const input = '<p>Click <x-foo :bar="\$baz" /> here</p>';
      expect(
        blockFormatter.format(input),
        contains('Click <x-foo :bar="\$baz" /> here'),
      );
    });

    test('component between text stays inline (opt-in mode too)', () {
      const input = 'Click <x-foo :bar="\$baz" /> here';
      expect(
        inlineFormatter.format(input).trim(),
        equals('Click <x-foo :bar="\$baz" /> here'),
      );
    });
  });

  group('config plumbing', () {
    test('defaults to false', () {
      expect(const FormatterConfig().inlineSelfClosingComponents, isFalse);
    });

    test('round-trips through fromMap/toMap', () {
      const cfg = FormatterConfig(inlineSelfClosingComponents: true);
      final restored = FormatterConfig.fromMap(cfg.toMap());
      expect(restored.inlineSelfClosingComponents, isTrue);
    });

    test('fromMap reads the inline_self_closing_components key', () {
      final cfg =
          FormatterConfig.fromMap({'inline_self_closing_components': true});
      expect(cfg.inlineSelfClosingComponents, isTrue);
    });
  });
}
