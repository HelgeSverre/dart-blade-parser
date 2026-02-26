import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Parser Synchronize Recovery Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('synchronize recovers at @for directive', () {
      final result = parser.parse(
          r'@unknownBrokenStuff @for($i = 0; $i < 5; $i++) {{ $i }} @endfor');
      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      final forDirective = directives.firstWhere((d) => d.name == 'for');

      expect(forDirective.name, equals('for'));
      expect(forDirective.expression, isNotNull);
      expect(forDirective.expression, contains(r'$i'));
      expect(forDirective.children, isNotEmpty,
          reason: 'Block directive @for should capture its children');
    });

    test('synchronize recovers at @while directive', () {
      final result = parser
          .parse(r'@unknownBrokenStuff @while($x) {{ $x }} @endwhile');
      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      final whileDirective = directives.firstWhere((d) => d.name == 'while');

      expect(whileDirective.name, equals('while'));
      expect(whileDirective.expression, isNotNull);
      expect(whileDirective.expression, contains(r'$x'));
      expect(whileDirective.children, isNotEmpty,
          reason: 'Block directive @while should capture its children');
    });

    test('synchronize recovers at @section directive', () {
      final result = parser.parse(
          '@unknownBrokenStuff @section("content") hello @endsection');
      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      final sectionDirective =
          directives.firstWhere((d) => d.name == 'section');

      expect(sectionDirective.name, equals('section'));
      expect(sectionDirective.expression, isNotNull);
      expect(sectionDirective.expression, contains('content'));
      expect(sectionDirective.children, isNotEmpty,
          reason: 'Block directive @section should capture its children');
      expect(sectionDirective.closedBy, equals('endsection'));
    });
  });
}
