import 'dart:io';
import '../models/fixture_info.dart';

/// Scans the fixtures directory and discovers all .blade.php files.
class FixtureScanner {
  final String fixturesPath;

  FixtureScanner(this.fixturesPath);

  /// Discover all fixture files recursively.
  List<FixtureInfo> scan() {
    final fixturesDir = Directory(fixturesPath);

    if (!fixturesDir.existsSync()) {
      throw Exception('Fixtures directory not found: $fixturesPath');
    }

    final fixtures = <FixtureInfo>[];

    // Recursively find all .blade.php files
    final files = fixturesDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.blade.php'))
        .toList();

    // Sort by path for consistent ordering
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      try {
        final fixture = FixtureInfo.fromFile(file, fixturesPath);
        fixtures.add(fixture);
      } catch (e) {
        print('Warning: Could not load fixture ${file.path}: $e');
      }
    }

    return fixtures;
  }

  /// Get fixtures grouped by category.
  Map<FixtureCategory, List<FixtureInfo>> scanByCategory() {
    final fixtures = scan();
    final grouped = <FixtureCategory, List<FixtureInfo>>{};

    for (final fixture in fixtures) {
      grouped.putIfAbsent(fixture.category, () => []).add(fixture);
    }

    return grouped;
  }

  /// Get statistics about the fixtures.
  Map<String, dynamic> getStatistics() {
    final fixtures = scan();
    final byCategory = scanByCategory();

    return {
      'total': fixtures.length,
      'byCategory': byCategory.map((cat, list) => MapEntry(cat.displayName, list.length)),
      'totalSize': fixtures.fold<int>(0, (sum, f) => sum + f.sizeBytes),
      'totalLines': fixtures.fold<int>(0, (sum, f) => sum + f.lineCount),
    };
  }
}
