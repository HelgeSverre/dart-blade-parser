import 'dart:io';

/// Information about a test fixture file.
class FixtureInfo {
  final String path;
  final String relativePath;
  final FixtureCategory category;
  final String content;
  final int sizeBytes;
  final int lineCount;

  FixtureInfo({
    required this.path,
    required this.relativePath,
    required this.category,
    required this.content,
    required this.sizeBytes,
    required this.lineCount,
  });

  /// Create from a file path
  factory FixtureInfo.fromFile(File file, String fixturesRoot) {
    final content = file.readAsStringSync();
    final relativePath = file.path.substring(fixturesRoot.length + 1);

    return FixtureInfo(
      path: file.path,
      relativePath: relativePath,
      category: _categorizeFixture(relativePath),
      content: content,
      sizeBytes: content.length,
      lineCount: content.split('\n').length,
    );
  }

  static FixtureCategory _categorizeFixture(String relativePath) {
    final parts = relativePath.split('/');
    if (parts.isEmpty) return FixtureCategory.other;

    final dirName = parts[0];

    switch (dirName) {
      case 'valid':
        return FixtureCategory.valid;
      case 'invalid':
        return FixtureCategory.invalid;
      case 'edge_cases':
        return FixtureCategory.edgeCases;
      case 'alpine':
        return FixtureCategory.alpine;
      case 'livewire':
        return FixtureCategory.livewire;
      case 'components':
        return FixtureCategory.components;
      case 'small':
        return FixtureCategory.small;
      case 'medium':
        return FixtureCategory.medium;
      case 'large':
        return FixtureCategory.large;
      case 'synthetic':
        return FixtureCategory.synthetic;
      default:
        return FixtureCategory.other;
    }
  }

  String get fileName => relativePath.split('/').last;
}

enum FixtureCategory {
  valid,
  invalid,
  edgeCases,
  alpine,
  livewire,
  components,
  small,
  medium,
  large,
  synthetic,
  other;

  String get displayName {
    switch (this) {
      case FixtureCategory.edgeCases:
        return 'edge_cases';
      default:
        return name;
    }
  }

  /// Should this category be expected to parse successfully?
  bool get shouldSucceed {
    return this != FixtureCategory.invalid;
  }
}
