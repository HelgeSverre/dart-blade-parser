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

    test('simple PHP block in tag head is preserved', () {
      const source =
          '<input <?php if (isset(\$name)): ?> name="{{ \$name }}" <?php endif; ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;
      // tagHead should contain the PHP blocks and the attribute
      expect(html.tagHead, isNotEmpty);

      final phpBlocks = html.tagHead.whereType<TagHeadPhpBlock>().toList();
      expect(phpBlocks.length, greaterThanOrEqualTo(1));
      expect(phpBlocks.first.content, contains('if'));
    });

    test('mixed PHP and Blade directives in tag head', () {
      const source =
          '<input <?php if (\$mask): ?> x-mask="{{ \$mask }}" @elseif (\$other) x-other="{{ \$other }}" <?php endif; ?>>';
      final result = parser.parse(source);

      final html = result.ast!.children
          .whereType<HtmlElementNode>()
          .first;

      // Should have both PHP blocks and Blade directives in tagHead
      final phpBlocks = html.tagHead.whereType<TagHeadPhpBlock>().toList();
      final directives = html.tagHead.whereType<TagHeadDirective>().toList();

      expect(phpBlocks, isNotEmpty, reason: 'Should have PHP block items');
      expect(directives, isNotEmpty, reason: 'Should have directive items');
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
      expect(phpBlocks, isNotEmpty);
    });
  });
}
