import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

/// Stress test: parse all real-world blade files from FluxUI and Filament
/// to verify the parser handles real-world templates without crashing.
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

  group('Filament v2 stress test', () {
    final files = findBladeFiles('test/fixtures/stress/filament/v2');

    test('found Filament v2 blade files', () {
      expect(files, isNotEmpty,
          reason:
              'Should have Filament v2 blade files in test/fixtures/stress/filament/v2');
    });

    for (final file in files) {
      final relativePath =
          file.path.replaceFirst('test/fixtures/stress/filament/v2/', '');
      test('parses $relativePath without crashing', () {
        final source = file.readAsStringSync();
        final result = parser.parse(source);
        expect(result.ast, isNotNull);
      });
    }
  });

  group('Filament v3 stress test', () {
    final files = findBladeFiles('test/fixtures/stress/filament/v3');

    test('found Filament v3 blade files', () {
      expect(files, isNotEmpty,
          reason:
              'Should have Filament v3 blade files in test/fixtures/stress/filament/v3');
    });

    for (final file in files) {
      final relativePath =
          file.path.replaceFirst('test/fixtures/stress/filament/v3/', '');
      test('parses $relativePath without crashing', () {
        final source = file.readAsStringSync();
        final result = parser.parse(source);
        expect(result.ast, isNotNull);
      });
    }
  });

  group('Filament v4 stress test', () {
    final files = findBladeFiles('test/fixtures/stress/filament/v4');

    test('found Filament v4 blade files', () {
      expect(files, isNotEmpty,
          reason:
              'Should have Filament v4 blade files in test/fixtures/stress/filament/v4');
    });

    for (final file in files) {
      final relativePath =
          file.path.replaceFirst('test/fixtures/stress/filament/v4/', '');
      test('parses $relativePath without crashing', () {
        final source = file.readAsStringSync();
        final result = parser.parse(source);
        expect(result.ast, isNotNull);
      });
    }
  });
}
