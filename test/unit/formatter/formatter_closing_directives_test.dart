import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/formatter_visitor.dart';

void main() {
  group('Formatter closing directives', () {
    late BladeParser parser;
    late FormatterVisitor formatter;

    setUp(() {
      parser = BladeParser();
      formatter = FormatterVisitor(FormatterConfig());
    });

    String format(String input) {
      final result = parser.parse(input);
      return formatter.format(result.ast!);
    }

    test('pushOnce directive preserves closing tag', () {
      final output = format('@pushOnce("scripts")\n<script>alert(1)</script>\n@endPushOnce');
      expect(output, contains('@endpushOnce'));
    });

    test('prependOnce directive preserves closing tag', () {
      final output = format('@prependOnce("styles")\n<link>\n@endPrependOnce');
      expect(output, contains('@endprependOnce'));
    });

    test('pushIf directive preserves closing tag', () {
      final output = format('@pushIf(true, "scripts")\n<script></script>\n@endPushIf');
      expect(output, contains('@endpushIf'));
    });

    test('fragment directive preserves closing tag', () {
      final output = format('@fragment\ncontent\n@endfragment');
      expect(output, contains('@endfragment'));
    });

    test('error directive preserves closing tag', () {
      final output = format('@error("name")\n<span>Error</span>\n@enderror');
      expect(output, contains('@enderror'));
    });

    test('session directive preserves closing tag', () {
      final output = format('@session("status")\n<div>Status</div>\n@endsession');
      expect(output, contains('@endsession'));
    });

    test('component directive preserves closing tag', () {
      final output = format('@component("alert")\nContent\n@endcomponent');
      expect(output, contains('@endcomponent'));
    });

    test('isset directive preserves closing tag', () {
      final output = format('@isset(\$var)\nContent\n@endisset');
      expect(output, contains('@endisset'));
    });
  });
}
