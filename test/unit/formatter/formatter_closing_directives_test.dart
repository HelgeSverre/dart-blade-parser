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
      expect(output, contains('@endPushOnce'));
    });

    test('prependOnce directive preserves closing tag', () {
      final output = format('@prependOnce("styles")\n<link>\n@endPrependOnce');
      expect(output, contains('@endPrependOnce'));
    });

    test('pushIf directive preserves closing tag', () {
      final output = format('@pushIf(true, "scripts")\n<script></script>\n@endPushIf');
      expect(output, contains('@endPushIf'));
    });

    test('pushIf round-trips idempotently with @endPushIf', () {
      final input = '@pushIf(true, "scripts")\n    <script></script>\n@endPushIf';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: '@pushIf/@endPushIf should be idempotent');
      expect(first, contains('@pushIf'));
      expect(first, contains('@endPushIf'));
      expect(first, isNot(contains('@endPushOnce')));
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

    test('empty with else formats both branches', () {
      final input = '@empty(\$items)\n<p>None</p>\n@else\n<p>Has items</p>\n@endempty';
      final output = format(input);
      expect(output, contains('@empty'));
      expect(output, contains('@else'));
      expect(output, contains('@endempty'));
      expect(output, contains('None'));
      expect(output, contains('Has items'));
    });

    test('empty with else is idempotent', () {
      final input = '@empty(\$items)\n<p>None</p>\n@else\n<p>Has items</p>\n@endempty';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second), reason: '@empty/@else/@endempty should be idempotent');
    });

    test('forelse with @empty does not emit @endempty', () {
      final output = format('@forelse(\$items as \$item)\n<li>{{ \$item }}</li>\n@empty\n<p>None</p>\n@endforelse');
      expect(output, contains('@empty'));
      expect(output, contains('@endforelse'));
      expect(output, isNot(contains('@endempty')),
          reason: '@empty inside @forelse must not produce @endempty');
    });

    test('forelse with @empty(\$expr) does not emit @endempty', () {
      final output = format('@forelse(\$items as \$item)\n<li>{{ \$item }}</li>\n@empty(\$items)\n<p>None</p>\n@endforelse');
      expect(output, contains('@empty'));
      expect(output, contains('@endforelse'));
      expect(output, isNot(contains('@endempty')),
          reason: '@empty(\$expr) inside @forelse must not produce @endempty');
    });

    test('standalone @empty emits @endempty', () {
      final output = format('@empty(\$items)\n<p>None</p>\n@endempty');
      expect(output, contains('@empty'));
      expect(output, contains('@endempty'));
      expect(output, isNot(contains('@endforelse')));
    });

    test('isset with else formats both branches', () {
      final input = '@isset(\$user)\n<p>{{ \$user->name }}</p>\n@else\n<p>Guest</p>\n@endisset';
      final output = format(input);
      expect(output, contains('@isset'));
      expect(output, contains('@else'));
      expect(output, contains('@endisset'));
    });

    // Issue #1: @slot/@endslot parsed as block directive
    test('slot directive preserves closing tag', () {
      final output = format('@slot("header")\n<h1>Title</h1>\n@endslot');
      expect(output, contains('@slot'));
      expect(output, contains('@endslot'));
    });

    test('slot round-trips idempotently', () {
      final input = '@slot("header")\n    <h1>Title</h1>\n@endslot';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: '@slot/@endslot should be idempotent');
    });

    // Issue #2: @context/@endcontext (Laravel 12.x)
    test('context directive preserves closing tag', () {
      final output = format('@context("canonical")\n<link href="{{ \$value }}" rel="canonical">\n@endcontext');
      expect(output, contains('@context'));
      expect(output, contains('@endcontext'));
    });

    test('context round-trips idempotently', () {
      final input = '@context("canonical")\n    <link href="{{ \$value }}" rel="canonical">\n@endcontext';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: '@context/@endcontext should be idempotent');
    });

    // Issue #3: @hasstack (closes with @endif)
    test('hasStack directive closes with @endif', () {
      final output = format('@hasStack("scripts")\n<ul>@stack("scripts")</ul>\n@endif');
      expect(output, contains('@hasStack'));
      expect(output, contains('@endif'));
      expect(output, isNot(contains('@endhasStack')));
    });

    // Issue #4: @teleport/@endTeleport (Livewire)
    test('teleport directive preserves closing tag', () {
      final output = format('@teleport("body")\n<div>Modal</div>\n@endTeleport');
      expect(output, contains('@teleport'));
      expect(output, contains('@endTeleport'));
    });

    test('teleport round-trips idempotently', () {
      final input = '@teleport("body")\n    <div>Modal</div>\n@endTeleport';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: '@teleport/@endTeleport should be idempotent');
    });

    // Issue #5: @persist/@endPersist (Livewire)
    test('persist directive preserves closing tag', () {
      final output = format('@persist("player")\n<div>Player</div>\n@endPersist');
      expect(output, contains('@persist'));
      expect(output, contains('@endPersist'));
    });

    test('persist round-trips idempotently', () {
      final input = '@persist("player")\n    <div>Player</div>\n@endPersist';
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: '@persist/@endPersist should be idempotent');
    });

    // Issue #6: @stop (section alias)
    test('section closed by @stop', () {
      final output = format('@section("content")\n<p>Content</p>\n@stop');
      expect(output, contains('@section'));
      expect(output, contains('@stop'));
    });

    // Issue #7: @append (section closer)
    test('section closed by @append', () {
      final output = format('@section("sidebar")\n<nav>Nav</nav>\n@append');
      expect(output, contains('@section'));
      expect(output, contains('@append'));
    });
  });
}
