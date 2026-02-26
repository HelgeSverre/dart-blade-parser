import 'dart:io';

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests that edge case fixture files parse, format, and are idempotent.
void main() {
  group('Edge case fixture formatting', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    final fixtureDir = Directory('test/fixtures/edge_cases');
    if (!fixtureDir.existsSync()) return;

    final fixtures = fixtureDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.blade.php'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final fixture in fixtures) {
      final name = fixture.uri.pathSegments.last;

      test('$name formats without error', () {
        final input = fixture.readAsStringSync();
        expect(() => formatter.format(input), returnsNormally);
      });

      test('$name is idempotent', () {
        final input = fixture.readAsStringSync();
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1),
            reason: '$name: second format pass should match first');
      });
    }
  });

  group('Synthetic fixture regression tests', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    // These fixtures previously crashed due to @if/@foreach inside HTML tags
    // being incorrectly consumed as attribute directives in the lexer.
    final regressionFixtures = [
      'test/fixtures/synthetic/01-blade-directives/components/04-component-attributes.blade.php',
      'test/fixtures/synthetic/04-combinations/level-2-moderate/01-foreach-component-wire-key.blade.php',
    ];

    for (final path in regressionFixtures) {
      final name = path.split('/').last;

      test('$name formats without error', () {
        final input = File(path).readAsStringSync();
        expect(() => formatter.format(input), returnsNormally,
            reason: '$name should not crash the formatter');
      });

      test('$name is idempotent', () {
        final input = File(path).readAsStringSync();
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1),
            reason: '$name: second format pass should match first');
      });
    }
  });
}
