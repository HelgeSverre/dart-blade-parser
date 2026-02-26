import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // Issue #1: ?> inside PHP strings/comments should not close the block
  // =========================================================================
  group('Issue #1: ?> inside PHP strings', () {
    test('?> inside double-quoted string should not close block', () {
      final tokens =
          BladeLexer('<?php echo "end ?>"; ?>').tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?php echo "end ?>"; ?>');
    });

    test('?> inside single-quoted string should not close block', () {
      final tokens =
          BladeLexer("<?php echo 'end ?>'; ?>").tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, "<?php echo 'end ?>'; ?>");
    });

    test('?> inside // line comment DOES close block (real PHP behavior)', () {
      // In real PHP, ?> closes the PHP block even inside // comments.
      // This is correct behavior — not a bug.
      final tokens =
          BladeLexer('<?php // close ?> here\n\$x = 1; ?>').tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      // PHP closes at the first ?> even inside //, so we get 2 blocks
      // or 1 block ending at the first ?>. Either way, not 1 full block.
      expect(phpTokens.first.value, '<?php // close ?>');
    });

    test('?> inside /* */ block comment should not close block', () {
      final tokens =
          BladeLexer('<?php /* close ?> here */ \$x = 1; ?>').tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
    });
  });

}
