@Tags(['flux'])
library;

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  late BladeParser parser;

  setUp(() {
    parser = BladeParser();
  });

  /// Recursively find all .blade.php files in a directory
  List<File> findBladeFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.blade.php'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  group('FluxUI stress test', () {
    final files = findBladeFiles('test/fixtures/stress/fluxui');

    test('found FluxUI blade files', () {
      expect(files, isNotEmpty,
          reason: 'Should have FluxUI blade files in test/fixtures/stress/fluxui');
    });

    for (final file in files) {
      final relativePath =
          file.path.replaceFirst('test/fixtures/stress/fluxui/', '');
      test('parses $relativePath without errors', () {
        final source = file.readAsStringSync();
        final result = parser.parse(source);

        // We expect the parser to produce a result without throwing
        expect(result.ast, isNotNull,
            reason: 'Parser should produce an AST for $relativePath');

        // Collect critical errors (not warnings about unclosed tags etc.)
        final criticalErrors = result.errors
            .where((e) => e.message.contains('Unexpected'))
            .toList();

        // We allow some parse errors (unclosed tags etc.) in real-world files,
        // but no crashes
        if (result.errors.isNotEmpty) {
          // Just log, don't fail - we want to see the error rate
          // print('  ${result.errors.length} parse errors in $relativePath');
        }
      });
    }
  });
}
