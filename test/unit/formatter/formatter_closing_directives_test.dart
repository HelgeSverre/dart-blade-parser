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

    void expectIdempotent(String input, {String? reason}) {
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: reason ?? 'Formatting should be idempotent');
    }

    test('pushOnce preserves tags and is idempotent', () {
      final input =
          '@pushOnce("scripts")\n    <script>alert(1)</script>\n@endPushOnce';
      final output = format(input);
      expect(output, contains('@pushOnce'));
      expect(output, contains('@endPushOnce'));
      expect(output, contains('alert(1)'));
      expectIdempotent(input);
    });

    test('prependOnce preserves tags and is idempotent', () {
      final input =
          '@prependOnce("styles")\n    <link>\n@endPrependOnce';
      final output = format(input);
      expect(output, contains('@prependOnce'));
      expect(output, contains('@endPrependOnce'));
      expectIdempotent(input);
    });

    test('pushIf preserves tags and is idempotent', () {
      final input =
          '@pushIf(true, "scripts")\n    <script></script>\n@endPushIf';
      final output = format(input);
      expect(output, contains('@pushIf'));
      expect(output, contains('@endPushIf'));
      expect(output, isNot(contains('@endPushOnce')),
          reason: '@pushIf must not produce @endPushOnce');
      expectIdempotent(input);
    });

    test('fragment preserves tags and is idempotent', () {
      final input = '@fragment("user-list")\n    content\n@endfragment';
      final output = format(input);
      expect(output, contains('@fragment'));
      expect(output, contains('@endfragment'));
      expect(output, contains('content'));
      expectIdempotent(input);
    });

    test('error preserves tags and is idempotent', () {
      final input =
          '@error("name")\n    <span>Error</span>\n@enderror';
      final output = format(input);
      expect(output, contains('@error'));
      expect(output, contains('@enderror'));
      expect(output, contains('Error'));
      expectIdempotent(input);
    });

    test('session preserves tags and is idempotent', () {
      final input =
          '@session("status")\n    <div>Status</div>\n@endsession';
      final output = format(input);
      expect(output, contains('@session'));
      expect(output, contains('@endsession'));
      expect(output, contains('Status'));
      expectIdempotent(input);
    });

    test('component preserves tags and is idempotent', () {
      final input = '@component("alert")\n    Content\n@endcomponent';
      final output = format(input);
      expect(output, contains('@component'));
      expect(output, contains('@endcomponent'));
      expect(output, contains('Content'));
      expectIdempotent(input);
    });

    test('isset preserves tags and is idempotent', () {
      final input = '@isset(\$var)\n    Content\n@endisset';
      final output = format(input);
      expect(output, contains('@isset'));
      expect(output, contains('@endisset'));
      expect(output, contains('Content'));
      expectIdempotent(input);
    });

    test('empty with else formats both branches and is idempotent', () {
      final input =
          '@empty(\$items)\n<p>None</p>\n@else\n<p>Has items</p>\n@endempty';
      final output = format(input);
      expect(output, contains('@empty'));
      expect(output, contains('@else'));
      expect(output, contains('@endempty'));
      expect(output, contains('None'));
      expect(output, contains('Has items'));
      expectIdempotent(input);
    });

    test('forelse with @empty does not emit @endempty', () {
      final input =
          '@forelse(\$items as \$item)\n<li>{{ \$item }}</li>\n@empty\n<p>None</p>\n@endforelse';
      final output = format(input);
      expect(output, contains('@forelse'));
      expect(output, contains('@empty'));
      expect(output, contains('@endforelse'));
      expect(output, isNot(contains('@endempty')),
          reason: '@empty inside @forelse must not produce @endempty');
      expectIdempotent(input);
    });

    test('forelse with @empty(\$expr) does not emit @endempty', () {
      final input =
          '@forelse(\$items as \$item)\n<li>{{ \$item }}</li>\n@empty(\$items)\n<p>None</p>\n@endforelse';
      final output = format(input);
      expect(output, contains('@empty'));
      expect(output, contains('@endforelse'));
      expect(output, isNot(contains('@endempty')),
          reason: '@empty(\$expr) inside @forelse must not produce @endempty');
      expectIdempotent(input);
    });

    test('standalone @empty emits @endempty', () {
      final input = '@empty(\$items)\n    <p>None</p>\n@endempty';
      final output = format(input);
      expect(output, contains('@empty'));
      expect(output, contains('@endempty'));
      expect(output, isNot(contains('@endforelse')));
      expectIdempotent(input);
    });

    test('isset with else formats both branches and is idempotent', () {
      final input =
          '@isset(\$user)\n<p>{{ \$user->name }}</p>\n@else\n<p>Guest</p>\n@endisset';
      final output = format(input);
      expect(output, contains('@isset'));
      expect(output, contains('@else'));
      expect(output, contains('@endisset'));
      expectIdempotent(input);
    });

    test('slot preserves tags and is idempotent', () {
      final input = '@slot("header")\n    <h1>Title</h1>\n@endslot';
      final output = format(input);
      expect(output, contains('@slot'));
      expect(output, contains('@endslot'));
      expect(output, contains('Title'));
      expectIdempotent(input);
    });

    test('context preserves tags and is idempotent', () {
      final input =
          '@context("canonical")\n    <link href="{{ \$value }}" rel="canonical">\n@endcontext';
      final output = format(input);
      expect(output, contains('@context'));
      expect(output, contains('@endcontext'));
      expectIdempotent(input);
    });

    test('hasStack closes with @endif and is idempotent', () {
      final input =
          '@hasStack("scripts")\n    <ul>@stack("scripts")</ul>\n@endif';
      final output = format(input);
      expect(output, contains('@hasStack'));
      expect(output, contains('@endif'));
      expect(output, isNot(contains('@endhasStack')),
          reason: '@hasStack closes with @endif per Laravel docs');
      expectIdempotent(input);
    });

    test('teleport preserves tags and is idempotent', () {
      final input =
          '@teleport("body")\n    <div>Modal</div>\n@endTeleport';
      final output = format(input);
      expect(output, contains('@teleport'));
      expect(output, contains('@endTeleport'));
      expect(output, isNot(contains('@endteleport')),
          reason: '@endTeleport must preserve camelCase');
      expect(output, contains('Modal'));
      expectIdempotent(input);
    });

    test('persist preserves tags and is idempotent', () {
      final input =
          '@persist("player")\n    <div>Player</div>\n@endPersist';
      final output = format(input);
      expect(output, contains('@persist'));
      expect(output, contains('@endPersist'));
      expect(output, isNot(contains('@endpersist')),
          reason: '@endPersist must preserve camelCase');
      expect(output, contains('Player'));
      expectIdempotent(input);
    });

    test('section closed by @stop is idempotent', () {
      final input = '@section("content")\n    <p>Content</p>\n@stop';
      final output = format(input);
      expect(output, contains('@section'));
      expect(output, contains('@stop'));
      expect(output, contains('Content'));
      expectIdempotent(input);
    });

    test('section closed by @append is idempotent', () {
      final input = '@section("sidebar")\n    <nav>Nav</nav>\n@append';
      final output = format(input);
      expect(output, contains('@section'));
      expect(output, contains('@append'));
      expect(output, contains('Nav'));
      expectIdempotent(input);
    });
  });
}
