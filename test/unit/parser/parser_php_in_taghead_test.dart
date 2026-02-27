import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/node.dart';

/// Tests for PHP blocks in tag heads (e.g., <?php if(...): ?> ... <?php endif; ?>)
void main() {
  group('PHP blocks in tag heads', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('simple PHP block in tag head is preserved with correct count', () {
      const source =
          '<input <?php if (isset(\$name)): ?> name="{{ \$name }}" <?php endif; ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;
      expect(html.tagHead, isNotEmpty);

      final phpBlocks = html.tagHead.whereType<TagHeadPhpBlock>().toList();
      expect(phpBlocks, hasLength(2), reason: 'Should have opening and closing PHP blocks');
      expect(phpBlocks[0].content, equals('<?php if (isset(\$name)): ?>'));
      expect(phpBlocks[1].content, equals('<?php endif; ?>'));
    });

    test('attributes between PHP blocks are preserved', () {
      const source =
          '<input <?php if (isset(\$name)): ?> name="test" <?php endif; ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;

      final attrs = html.tagHead.whereType<TagHeadAttribute>().toList();
      expect(attrs, hasLength(1));
      expect(attrs.first.name, equals('name'));
    });

    test('mixed PHP and Blade directives in tag head', () {
      const source =
          '<input <?php if (\$mask): ?> x-mask="{{ \$mask }}" @elseif (\$other) x-other="{{ \$other }}" <?php endif; ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;

      final phpBlocks = html.tagHead.whereType<TagHeadPhpBlock>().toList();
      final directives = html.tagHead.whereType<TagHeadDirective>().toList();

      expect(phpBlocks, hasLength(2), reason: 'opening and closing PHP blocks');
      expect(phpBlocks[0].content, contains('if'));
      expect(phpBlocks[1].content, contains('endif'));
      expect(directives, isNotEmpty, reason: 'Should have directive items');
      expect(directives.any((d) => d.name == 'elseif'), isTrue);
    });

    test('PHP block in component tag head is preserved', () {
      const source =
          '<x-input <?php if (\$required): ?> required <?php endif; ?> />';
      final result = parser.parse(source);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .first;
      expect(component.tagHead, isNotEmpty);

      final phpBlocks =
          component.tagHead.whereType<TagHeadPhpBlock>().toList();
      expect(phpBlocks, hasLength(2));
      expect(phpBlocks[0].content, equals('<?php if (\$required): ?>'));
      expect(phpBlocks[1].content, equals('<?php endif; ?>'));
    });

    test('PHP short echo tag in tag head', () {
      const source = '<input <?= \$required ? "required" : "" ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;

      final phpBlocks = html.tagHead.whereType<TagHeadPhpBlock>().toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.content, startsWith('<?='));
      expect(phpBlocks.first.content, endsWith('?>'));
    });

    test('formatter round-trips PHP blocks in tag heads', () {
      const source =
          '<input <?php if (\$x): ?> name="test" <?php endif; ?>>';
      final formatter = BladeFormatter();
      final formatted = formatter.format(source);

      // PHP blocks should survive formatting
      expect(formatted, contains('<?php if (\$x): ?>'));
      expect(formatted, contains('<?php endif; ?>'));
      expect(formatted, contains('name='));
    });
  });
}
