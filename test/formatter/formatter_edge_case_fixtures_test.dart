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
}
