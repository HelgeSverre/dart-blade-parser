import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Forelse Empty Position Tests', () {
    test('@forelse empty clause has correct start position', () {
      final parser = BladeParser();
      final result = parser.parse(
          '@forelse(\$items as \$item)\n  {{ \$item }}\n@empty\n  <p>No items</p>\n@endforelse');

      final forelse = result.ast!.children.whereType<DirectiveNode>().first;
      final emptyDirective = forelse.children
          .whereType<DirectiveNode>()
          .firstWhere((d) => d.name == 'empty');

      // The @empty directive should NOT have the same start position as @forelse
      expect(emptyDirective.startPosition, isNot(equals(forelse.startPosition)),
          reason:
              '@empty should have its own position, not @forelse position');
    });
  });
}
