import 'dart:io';

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

import '../../utils/recovery_nodes.dart';

void main() {
  group('Formatter RecoveryNode output', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('stray closer inside element is preserved in output', () {
      // Parser should handle </bogus> gracefully, formatter preserves content
      const input = '<div><span>Text</bogus>More</span></div>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('Text'));
      expect(result.formatted, contains('More'));
    });

    test('unclosed directive at EOF preserves content and reports error', () {
      const input = '@if(\$x)\n    <p>Hello</p>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('@if'));
      expect(result.formatted, contains('<p>Hello</p>'));
    });

    test('recovery node content round-trips verbatim', () {
        // Malformed input with stray closer — format twice, same output
        const input = '<div>Text</bogus>More</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1), reason: 'recovery output must be idempotent');
    });

    test('unclosed @if formats to a single closing directive', () {
      const input = '@if(\$x)\n    <p>Hello</p>';
      final formatted = formatter.format(input);
      expect(formatted, startsWith('@if(\$x)\n'));
      expect(formatted, contains('<p>Hello</p>'));
      expect(formatted, endsWith('@endif\n'));
      // Only one @endif should be emitted
      expect('@endif'.allMatches(formatted).length, equals(1));
      expect(formatter.format(formatted), equals(formatted),
          reason: 'must be idempotent');
    });

    test('unclosed @foreach formats to a single closing directive', () {
      const input = '@foreach(\$items as \$item)\n<li>{{ \$item }}</li>';
      final formatted = formatter.format(input);
      expect(formatted, startsWith('@foreach(\$items as \$item)\n'));
      expect(formatted, contains('{{ \$item }}'));
      expect(formatted, endsWith('@endforeach\n'));
      // Body element must be indented
      final liLine = formatted.split('\n').firstWhere((l) => l.contains('<li>'));
      expect(liLine, isNot(equals(liLine.trimLeft())),
          reason: 'body element must be indented');
      // Only one @endforeach should be emitted
      expect('@endforeach'.allMatches(formatted).length, equals(1));
      expect(formatter.format(formatted), equals(formatted),
          reason: 'must be idempotent');
    });

    group('integration: parse + format with recovery', () {
      test('stray closer in element formats and re-formats identically', () {
        const input = '<div>Text</bogus>More</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('unclosed @if formats and re-formats identically', () {
        const input = '@if(\$x)\n    <p>Hello</p>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
        expect(pass1, contains('@endif'));
      });

      test('multiple recovery sites in one template are all idempotent', () {
        const input = '<div></bogus></baz>Text</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('ancestor-close recovery is idempotent', () {
        const input = '<div><span>Text</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('stray closer content appears in formatted output', () {
        const input = '<div>Hello</bogus>World</div>';
        final result = formatter.formatWithResult(input);
        expect(result.hasErrors, isTrue);
        expect(result.formatted, contains('</bogus>'));
        expect(result.formatted, contains('Hello'));
        expect(result.formatted, contains('World'));
      });

      test('unclosed @foreach is idempotent', () {
        const input = '@foreach(\$items as \$item)\n<li>{{ \$item }}</li>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('formatWithResult exposes combined recovery metadata', () {
        final source =
            File('test/fixtures/stress/recovery-combo.blade.php')
                .readAsStringSync();
      final result = formatter.formatWithResult(source);
      expect(result.ast, isNotNull);

      final recoveries = collectRecoveryNodes(result.ast!);
      expect(recoveries, isNotEmpty);
      expect(result.recoveries, isNotEmpty);
      expect(
        recoveries.any((node) => node.reason.contains('@endforeach')),
        isTrue,
      );
      expect(
        recoveries.any((node) => node.reason.contains('@else')),
        isTrue,
      );
      expect(
        result.recoveries.any((node) => node.reason.contains('@endforeach')),
        isTrue,
      );
      expect(
        result.recoveries.any((node) => node.reason.contains('@else')),
        isTrue,
      );
      expect(
        recoveries.any(
          (node) => node.reason.contains('mismatched component closing'),
        ),
        isTrue,
      );
      });

    });

    group('RecoveryConfidence metadata', () {
      test('high-confidence recovery summaries stay stable across formats', () {
        const input = '@if(\$x)\n    <p>Hi</p>';
        final first = formatter.formatWithResult(input);
        final second = formatter.formatWithResult(first.formatted);

        expect(first.formatted, equals(second.formatted));

        final firstSummaries = first.recoveries
            .map((r) => '${r.reason}:${r.confidence}:${r.content}')
            .toList();
        final secondSummaries = second.recoveries
            .map((r) => '${r.reason}:${r.confidence}:${r.content}')
            .toList();
        expect(
          firstSummaries,
          contains('missing @endif:RecoveryConfidence.high:'),
        );
        expect(secondSummaries, isEmpty);
      });

      test('low-confidence recovery summary preserves verbatim text', () {
        const input = '<div>Start</bogus>End</div>';
        final result = formatter.formatWithResult(input);

        expect(result.formatted, contains('</bogus>'));

        final low = result.recoveries.firstWhere(
          (node) => node.confidence == RecoveryConfidence.low,
          orElse: () => throw StateError('Expected low-confidence recovery'),
        );
        expect(low.content, contains('</bogus>'));
      });
    });
  });
}
