@Tags(['flux'])
library;

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Formatter Idempotency - FluxUI stress fixtures', () {
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

    test('formats FluxUI fixtures idempotently', () {
      final fixturesDir = Directory('test/fixtures/stress/fluxui');

      if (!fixturesDir.existsSync()) {
        print('FluxUI stress fixtures directory not found, skipping');
        return;
      }

      final bladeFiles = fixturesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.blade.php'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      print(
        'Testing ${bladeFiles.length} FluxUI fixture files for idempotency',
      );

      final failures = <String>[];
      for (final file in bladeFiles) {
        final content = file.readAsStringSync();
        final relativePath = file.path.replaceFirst(
          '${Directory.current.path}/',
          '',
        );

        try {
          expectIdempotent(content, description: relativePath);
        } catch (e) {
          failures.add(relativePath);
        }
      }

      if (failures.isNotEmpty) {
        fail(
          'Idempotency failed for ${failures.length}/${bladeFiles.length} FluxUI files:\n'
          '${failures.map((f) => '  - $f').join('\n')}',
        );
      }
    });
  });
}
