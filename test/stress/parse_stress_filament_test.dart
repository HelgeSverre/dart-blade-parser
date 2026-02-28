@Tags(['filament'])
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
