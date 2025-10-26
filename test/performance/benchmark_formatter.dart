import 'dart:io';

/// Utility for formatting benchmark output with colors and consistent styling
class BenchmarkFormatter {
  // ANSI color codes
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _green = '\x1B[32m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _magenta = '\x1B[35m';

  /// Print a section header with emphasis
  static void printHeader(String title) {
    final separator = '═' * 60;
    print('$_bold$_cyan\n$separator$_reset');
    print('$_bold$_cyan $title$_reset');
    print('$_bold$_cyan$separator$_reset\n');
  }

  /// Print a metric with label and value
  static void printMetric(String label, String value, {bool highlight = false}) {
    final color = highlight ? _green : _blue;
    final prefix = highlight ? '→' : '•';
    print('$color$prefix $_bold$label:$_reset $color$value$_reset');
  }

  /// Print a performance result with context
  static void printResult({
    required String label,
    required String metric,
    String? context,
  }) {
    print('$_bold$_green✓ $label:$_reset $_green$metric$_reset');
    if (context != null) {
      print('  $_yellow$context$_reset');
    }
  }

  /// Print a warning or note
  static void printNote(String message) {
    print('$_yellow⚠ $message$_reset');
  }

  /// Print a summary table with aligned columns
  static void printTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    // Calculate column widths
    final columnWidths = List<int>.filled(headers.length, 0);

    // Check headers
    for (var i = 0; i < headers.length; i++) {
      columnWidths[i] = headers[i].length;
    }

    // Check rows
    for (final row in rows) {
      for (var i = 0; i < row.length && i < columnWidths.length; i++) {
        if (row[i].length > columnWidths[i]) {
          columnWidths[i] = row[i].length;
        }
      }
    }

    // Print header
    final headerRow = StringBuffer('\n$_bold$_magenta');
    for (var i = 0; i < headers.length; i++) {
      headerRow.write(headers[i].padRight(columnWidths[i] + 2));
    }
    headerRow.write(_reset);
    print(headerRow.toString());

    // Print separator
    final separator = StringBuffer(_cyan);
    for (final width in columnWidths) {
      separator.write('─' * (width + 2));
    }
    separator.write(_reset);
    print(separator.toString());

    // Print rows
    for (final row in rows) {
      final rowStr = StringBuffer();
      for (var i = 0; i < row.length; i++) {
        final width = i < columnWidths.length ? columnWidths[i] : 0;
        rowStr.write(row[i].padRight(width + 2));
      }
      print(rowStr.toString());
    }
    print('');
  }

  /// Print a simple divider
  static void printDivider() {
    print('$_cyan${'─' * 60}$_reset');
  }

  /// Print throughput with units
  static String formatThroughput(num value, String unit) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M $unit';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K $unit';
    } else {
      return '${value.toStringAsFixed(2)} $unit';
    }
  }

  /// Format memory size
  static String formatMemory(num bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${bytes.toStringAsFixed(0)} bytes';
    }
  }

  /// Format time duration
  static String formatTime(num milliseconds) {
    if (milliseconds >= 1000) {
      return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    } else {
      return '${milliseconds.toStringAsFixed(2)}ms';
    }
  }

  /// Print a grouped set of metrics
  static void printMetrics(Map<String, String> metrics) {
    for (final entry in metrics.entries) {
      printMetric(entry.key, entry.value);
    }
  }
}
