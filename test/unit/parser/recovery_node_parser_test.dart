import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/node.dart';
import 'package:test/test.dart';

void main() {
  group('Parser RecoveryNode emission', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('stray HTML closers', () {
      test('stray closer becomes RecoveryNode child', () {
        final result = parser.parse('<div><span>Text</bogus>More</span></div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final span = div.children[0] as HtmlElementNode;

        final recoveryNodes = span.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
        expect(recoveryNodes.first.reason, contains('stray'));
      });

      test('top-level stray closer becomes RecoveryNode', () {
        final result = parser.parse('Hello</bogus>World');

        expect(result.isSuccess, isFalse);
        final recoveryNodes = result.ast!.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
      });

      test('multiple stray closers each get their own RecoveryNode', () {
        final result = parser.parse('<div>A</foo>B</bar>C</div>');

        final div = result.ast!.children[0] as HtmlElementNode;
        final recoveryNodes = div.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(2));
      });
    });

    group('unclosed directives', () {
      test('unclosed @if gets RecoveryNode marker', () {
        final result = parser.parse('@if(\$x)\n<p>Hello</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        expect(directive.name, 'if');

        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endif'));
      });

      test('unclosed @foreach gets RecoveryNode marker', () {
        final result =
            parser.parse('@foreach(\$items as \$item)\n<li>{{ \$item }}</li>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        expect(directive.name, 'foreach');

        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endforeach'));
      });

      test('unclosed @while gets RecoveryNode marker', () {
        final result = parser.parse('@while(true)\n<p>loop</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endwhile'));
      });

      test('unclosed @for gets RecoveryNode marker', () {
        final result =
            parser.parse('@for(\$i = 0; \$i < 10; \$i++)\n<p>{{ \$i }}</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endfor'));
      });

      test('unclosed generic directive gets RecoveryNode marker', () {
        final result = parser.parse('@auth\n<p>Secret</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endauth'));
      });

      test('unclosed @switch gets RecoveryNode marker', () {
        final result = parser.parse('@switch(\$x)\n@case(1)\n<p>One</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endswitch'));
      });

      test('unclosed @forelse gets RecoveryNode marker', () {
        final result = parser
            .parse('@forelse(\$items as \$item)\n<li>{{ \$item }}</li>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endforelse'));
      });

      test('properly closed directive has no RecoveryNode', () {
        final result = parser.parse('@if(\$x)\n<p>Hello</p>\n@endif');

        expect(result.isSuccess, isTrue);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, isEmpty);
      });
    });

    group('ancestor-close and unclosed HTML', () {
      test('ancestor closer auto-closes without RecoveryNode child', () {
        // </div> matches ancestor, so <span> is auto-closed.
        // No RecoveryNode child — error is in ParseResult.errors only.
        // HTML elements don't need recovery markers because the formatter
        // always emits closing tags.
        final result = parser.parse('<div><span>Text</div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final span = div.children[0] as HtmlElementNode;
        expect(span.tagName, 'span');
        expect(span.children.whereType<RecoveryNode>(), isEmpty);
      });

      test('unclosed HTML at EOF has error but no RecoveryNode child', () {
        final result = parser.parse('<div><p>Hello');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        expect(div.children.whereType<RecoveryNode>(), isEmpty);
      });

      test('properly closed HTML has no RecoveryNode', () {
        final result = parser.parse('<div><span>Text</span></div>');

        expect(result.isSuccess, isTrue);
        final div = result.ast!.children[0] as HtmlElementNode;
        expect(div.children.whereType<RecoveryNode>(), isEmpty);
      });
    });

    group('skipped regions', () {
      test('void element closer becomes RecoveryNode', () {
        final result = parser.parse('<div></br></div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final recoveryNodes = div.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, contains('br'));
      });

      test('top-level void element closer becomes RecoveryNode', () {
        final result = parser.parse('</hr>');

        expect(result.isSuccess, isFalse);
        final recoveryNodes = result.ast!.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</hr>');
      });
    });
  });
}
