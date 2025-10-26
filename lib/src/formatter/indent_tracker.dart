import 'dart:math';
import 'package:blade_parser/src/formatter/formatter_config.dart';

/// Tracks and manages indentation level during formatting.
///
/// Maintains the current indentation depth and generates the appropriate
/// indent string based on configuration (spaces vs tabs).
class IndentTracker {
  final FormatterConfig _config;
  int _level = 0;
  String? _cachedIndent;

  /// Creates an indent tracker with the given configuration.
  IndentTracker(this._config);

  /// Gets the current indentation level (0-indexed).
  int get level => _level;

  /// Gets the current indentation string.
  ///
  /// This is cached and only regenerated when the level changes.
  String get current {
    _cachedIndent ??= _generateIndent();
    return _cachedIndent!;
  }

  /// Increases the indentation level by 1.
  void increase() {
    _level++;
    _cachedIndent = null;
  }

  /// Decreases the indentation level by 1.
  ///
  /// The level cannot go below 0.
  void decrease() {
    _level = max(0, _level - 1);
    _cachedIndent = null;
  }

  /// Sets the indentation level to a specific value.
  void set(int level) {
    _level = max(0, level);
    _cachedIndent = null;
  }

  /// Resets the indentation level to 0.
  void reset() {
    _level = 0;
    _cachedIndent = null;
  }

  /// Generates the indent string based on current level and config.
  String _generateIndent() {
    if (_level == 0) return '';

    if (_config.indentStyle == IndentStyle.tabs) {
      return '\t' * _level;
    } else {
      return ' ' * (_config.indentSize * _level);
    }
  }

  /// Returns the indent string for the next level (current + 1).
  String get next {
    if (_config.indentStyle == IndentStyle.tabs) {
      return '\t' * (_level + 1);
    } else {
      return ' ' * (_config.indentSize * (_level + 1));
    }
  }

  @override
  String toString() => 'IndentTracker(level: $_level, indent: "$current")';
}
