import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('XML namespace attributes', () {
    test('xmlns:xlink parsed as standard attribute', () {
      final parser = BladeParser();
      final result = parser
          .parse('<svg xmlns:xlink="http://www.w3.org/1999/xlink"></svg>');

      expect(result.isSuccess, isTrue,
          reason: 'Expected parse success but got ${result.errors}');
      final svg = result.ast!.children.first as HtmlElementNode;

      expect(svg.attributes.containsKey('xmlns:xlink'), isTrue);
      expect(svg.attributes['xmlns:xlink'], isA<StandardAttribute>());
      expect(svg.attributes['xmlns:xlink']!.value,
          equals('http://www.w3.org/1999/xlink'));
    });
  });
}
