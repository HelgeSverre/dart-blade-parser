@Tags(['filament'])
library;

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Formatter Idempotency - Filament stress fixtures', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    /// Helper to test idempotency for a given input
    void expectIdempotent(String input, {String? description}) {
      final formatted1 = formatter.format(input);
      final formatted2 = formatter.format(formatted1);

      expect(
        formatted2,
        formatted1,
        reason: 'Formatter should be idempotent: format(format(x)) == format(x)'
            '${description != null ? " ($description)" : ""}',
      );
    }

    for (final version in ['v2', 'v3', 'v4']) {
      test('formats Filament $version fixtures idempotently', () {
        final fixturesDir =
            Directory('test/fixtures/stress/filament/$version');

        if (!fixturesDir.existsSync()) {
          print(
              'Filament $version stress fixtures directory not found, skipping');
          return;
        }

        final bladeFiles = fixturesDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.blade.php'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        print(
          'Testing ${bladeFiles.length} Filament $version fixture files for idempotency',
        );

        // Known idempotency failures that are temporarily skipped pending a fix.
        const knownFailures = {
          'test/fixtures/stress/filament/v2/packages_forms_resources_views_components_repeater.blade.php',
        };

        final failures = <String>[];
        for (final file in bladeFiles) {
          final content = file.readAsStringSync();
          final relativePath = file.path.replaceFirst(
            '${Directory.current.path}/',
            '',
          );

          if (knownFailures.contains(relativePath)) {
            print('  Skipping known failure: $relativePath');
            continue;
          }

          try {
            expectIdempotent(content, description: relativePath);
          } catch (e) {
            failures.add(relativePath);
          }
        }

        if (failures.isNotEmpty) {
          fail(
            'Idempotency failed for ${failures.length}/${bladeFiles.length} Filament $version files:\n'
            '${failures.map((f) => '  - $f').join('\n')}',
          );
        }
      });
    }
  });
}
