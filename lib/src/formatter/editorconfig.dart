import 'dart:io';

/// Parser for EditorConfig files.
///
/// Supports reading `.editorconfig` files and extracting settings
/// for specific file patterns (e.g., `*.blade.php`).
///
/// See: https://editorconfig.org/
class EditorConfig {
  /// Parsed sections from the EditorConfig file.
  final List<EditorConfigSection> sections;

  /// Whether this is the root EditorConfig (stops parent directory search).
  final bool isRoot;

  EditorConfig({
    required this.sections,
    this.isRoot = false,
  });

  /// Parse an EditorConfig file from string content.
  factory EditorConfig.parse(String content) {
    final lines = content.split('\n');
    final sections = <EditorConfigSection>[];
    var isRoot = false;
    String? currentPattern;
    var currentProperties = <String, String>{};

    for (var line in lines) {
      line = line.trim();

      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }

      // Check for root declaration
      if (line.toLowerCase().startsWith('root')) {
        final parts = line.split('=');
        if (parts.length == 2) {
          isRoot = parts[1].trim().toLowerCase() == 'true';
        }
        continue;
      }

      // Check for section header [pattern]
      if (line.startsWith('[') && line.endsWith(']')) {
        // Save previous section
        if (currentPattern != null) {
          sections.add(EditorConfigSection(
            pattern: currentPattern,
            properties: Map.from(currentProperties),
          ),);
        }
        currentPattern = line.substring(1, line.length - 1);
        currentProperties = {};
        continue;
      }

      // Parse property = value
      final equalsIndex = line.indexOf('=');
      if (equalsIndex > 0 && currentPattern != null) {
        final key = line.substring(0, equalsIndex).trim().toLowerCase();
        final value = line.substring(equalsIndex + 1).trim();
        currentProperties[key] = value;
      }
    }

    // Save last section
    if (currentPattern != null) {
      sections.add(EditorConfigSection(
        pattern: currentPattern,
        properties: Map.from(currentProperties),
      ),);
    }

    return EditorConfig(sections: sections, isRoot: isRoot);
  }

  /// Load EditorConfig from a file.
  static Future<EditorConfig?> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    return EditorConfig.parse(content);
  }

  /// Find and load EditorConfig for a given file path.
  ///
  /// Searches from the file's directory upward until finding a root
  /// EditorConfig or reaching the filesystem root.
  static Future<Map<String, String>> getPropertiesForFile(
    String filePath,
  ) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    var directory = file.parent;
    final allProperties = <String, String>{};
    final configStack = <(EditorConfig, String)>[];

    // Walk up directories looking for .editorconfig files
    while (directory.path != directory.parent.path) {
      final editorConfigPath = '${directory.path}/.editorconfig';
      final config = await loadFromFile(editorConfigPath);

      if (config != null) {
        configStack.add((config, directory.path));
        if (config.isRoot) break;
      }

      directory = directory.parent;
    }

    // Process configs from root to leaf (most specific wins)
    for (final (config, configDir) in configStack.reversed) {
      final relativePath = _relativePath(configDir, filePath);

      for (final section in config.sections) {
        if (section.matches(fileName) ||
            (relativePath != null && section.matches(relativePath))) {
          allProperties.addAll(section.properties);
        }
      }
    }

    return allProperties;
  }

  static String? _relativePath(String fromDir, String toFile) {
    final from = fromDir.endsWith('/') ? fromDir : '$fromDir/';
    if (toFile.startsWith(from)) {
      return toFile.substring(from.length);
    }
    return null;
  }

  /// Get properties for a file pattern from this EditorConfig.
  Map<String, String> getProperties(String fileName) {
    final properties = <String, String>{};
    for (final section in sections) {
      if (section.matches(fileName)) {
        properties.addAll(section.properties);
      }
    }
    return properties;
  }
}

/// A section in an EditorConfig file.
class EditorConfigSection {
  /// The file pattern for this section (e.g., `*.blade.php`).
  final String pattern;

  /// The properties defined in this section.
  final Map<String, String> properties;

  EditorConfigSection({
    required this.pattern,
    required this.properties,
  });

  /// Check if a filename matches this section's pattern.
  bool matches(String fileName) {
    // Handle exact match
    if (pattern == fileName) return true;

    // Handle [*] - matches all files
    if (pattern == '*') return true;

    // Handle glob patterns like *.blade.php
    if (pattern.startsWith('*.')) {
      final extension = pattern.substring(1); // .blade.php
      return fileName.endsWith(extension);
    }

    // Handle {*.ext1,*.ext2} syntax
    if (pattern.startsWith('{') && pattern.endsWith('}')) {
      final alternatives = pattern.substring(1, pattern.length - 1).split(',');
      for (final alt in alternatives) {
        if (_matchSimpleGlob(alt.trim(), fileName)) {
          return true;
        }
      }
      return false;
    }

    // Handle patterns with path components or **
    if (pattern.contains('/') || pattern.contains('**')) {
      final regexPattern = _globToRegex(pattern);
      return RegExp('^$regexPattern\$').hasMatch(fileName);
    }

    // Simple glob with *
    return _matchSimpleGlob(pattern, fileName);
  }

  static String _globToRegex(String pattern) {
    final buffer = StringBuffer();
    final chars = pattern.split('');
    for (var i = 0; i < chars.length; i++) {
      if (chars[i] == '*' && i + 1 < chars.length && chars[i + 1] == '*') {
        // ** matches any number of path segments
        if (i + 2 < chars.length && chars[i + 2] == '/') {
          buffer.write('(.*/)?');
          i += 2; // skip **/
        } else {
          buffer.write('.*');
          i += 1; // skip **
        }
      } else if (chars[i] == '*') {
        buffer.write('[^/]*');
      } else if (chars[i] == '?') {
        buffer.write('[^/]');
      } else if (RegExp(r'[.+^${}()|\\]').hasMatch(chars[i])) {
        buffer.write('\\${chars[i]}');
      } else {
        buffer.write(chars[i]);
      }
    }
    return buffer.toString();
  }

  bool _matchSimpleGlob(String pattern, String fileName) {
    if (!pattern.contains('*')) {
      return pattern == fileName;
    }

    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*');
    return RegExp('^$regexPattern\$').hasMatch(fileName);
  }
}
