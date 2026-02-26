import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Parser error hint casing for camelCase directives', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('unclosed @pushOnce suggests @endPushOnce (not @endpushOnce)', () {
      final result = parser.parse('@pushOnce("scripts") <script></script>');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endPushOnce'));
      expect(error.hint, isNot(contains('@endpushOnce')));
    });

    test('unclosed @prependOnce suggests @endPrependOnce', () {
      final result =
          parser.parse('@prependOnce("styles") <link rel="stylesheet">');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endPrependOnce'));
      expect(error.hint, isNot(contains('@endprependOnce')));
    });

    test('unclosed @pushIf suggests @endPushIf (not @endpushIf)', () {
      final result =
          parser.parse(r'@pushIf($shouldPush, "scripts") <script></script>');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endPushIf'));
      expect(error.hint, isNot(contains('@endpushIf')));
    });

    test('unclosed @teleport suggests @endTeleport (not @endteleport)', () {
      final result = parser.parse('@teleport("body") <div>Modal</div>');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endTeleport'));
      expect(error.hint, isNot(contains('@endteleport')));
    });

    test('unclosed @persist suggests @endPersist (not @endpersist)', () {
      final result = parser.parse('@persist("player") <div>Player</div>');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endPersist'));
      expect(error.hint, isNot(contains('@endpersist')));
    });

    test('unclosed @hasStack suggests @endif (not @endhasStack)', () {
      final result = parser.parse('@hasStack("scripts") <ul></ul>');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endif'));
      expect(error.hint, isNot(contains('@endhasStack')));
    });

    test('unclosed lowercase @if still suggests @endif', () {
      final result = parser.parse(r'@if($test) Hello');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endif'));
    });

    test('unclosed @foreach still suggests @endforeach', () {
      final result =
          parser.parse(r'@foreach($items as $item) {{ $item }}');
      expect(result.errors, isNotEmpty);
      final error = result.errors.first;
      expect(error.hint, contains('@endforeach'));
    });
  });
}
