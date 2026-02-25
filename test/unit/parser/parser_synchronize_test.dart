import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Parser Synchronize Recovery Tests', () {
    test('synchronize recovers at @for directive', () {
      final parser = BladeParser();
      // Broken template: error token followed by @for
      final result = parser.parse(
          '@unknownBrokenStuff @for(\$i = 0; \$i < 5; \$i++) {{ \$i }} @endfor');
      // Should still parse the @for
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'for'), isTrue,
          reason: 'Parser should recover at @for');
    });

    test('synchronize recovers at @while directive', () {
      final parser = BladeParser();
      final result = parser
          .parse('@unknownBrokenStuff @while(\$x) {{ \$x }} @endwhile');
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'while'), isTrue,
          reason: 'Parser should recover at @while');
    });

    test('synchronize recovers at @section directive', () {
      final parser = BladeParser();
      final result = parser.parse(
          '@unknownBrokenStuff @section("content") hello @endsection');
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'section'), isTrue,
          reason: 'Parser should recover at @section');
    });
  });
}
