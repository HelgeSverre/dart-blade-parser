import '../models/fixture_info.dart';
import '../models/test_result.dart';
import '../models/coverage_report.dart';

/// Console reporter with colors and Unicode art.
class ConsoleReporter {
  // ANSI color codes
  static const _reset = '\x1B[0m';
  static const _green = '\x1B[32m';
  static const _red = '\x1B[31m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _gray = '\x1B[90m';
  static const _bold = '\x1B[1m';
  static const _cyan = '\x1B[36m';

  /// Print the full report to console.
  void printReport(List<TestResult> results, CoverageReport coverage) {
    _printHeader();
    _printSummary(coverage);
    _printCategoryBreakdown(results);
    _printCoverageAnalysis(coverage);
    _printTopTokens(coverage);
    _printTopDirectives(coverage);
    _printFailures(results);
    _printFooter();
  }

  void _printHeader() {
    print('');
    print(
      '$_bold$_cyan╔════════════════════════════════════════════════════════╗$_reset',
    );
    print(
      '$_bold$_cyan║$_reset       🧪 $_bold${_cyan}BLADE PARSER ACID TEST RESULTS$_reset           $_bold$_cyan║$_reset',
    );
    print(
      '$_bold$_cyan╚════════════════════════════════════════════════════════╝$_reset',
    );
    print('');
  }

  void _printSummary(CoverageReport coverage) {
    final passRateColor = coverage.passRate >= 90
        ? _green
        : coverage.passRate >= 70
        ? _yellow
        : _red;

    print('$_bold📊 SUMMARY$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('  Total Fixtures:     $_bold${coverage.totalTests}$_reset');
    print(
      '  $_green✅ Passed:          $_bold${coverage.passedTests}$_reset  ($passRateColor${coverage.passRate.toStringAsFixed(1)}%$_reset)',
    );
    print(
      '  $_red❌ Failed:          $_bold${coverage.failedTests}$_reset  (${(100 - coverage.passRate).toStringAsFixed(1)}%)',
    );
    print('');
    print('  ⏱️  Total Time:       ${_formatTime(coverage.totalTimeMs)}');
    print('  📈 Avg Time:         ${_formatTime(coverage.avgTimeMs)}/file');
    print(
      '  🔢 Total Tokens:     $_bold${_formatNumber(coverage.totalTokens)}$_reset',
    );
    print(
      '  🌳 Total Nodes:      $_bold${_formatNumber(coverage.totalNodes)}$_reset',
    );
    print('');
  }

  void _printCategoryBreakdown(List<TestResult> results) {
    print('$_bold📂 RESULTS BY CATEGORY$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final byCategory = <FixtureCategory, List<TestResult>>{};
    for (final result in results) {
      byCategory.putIfAbsent(result.fixture.category, () => []).add(result);
    }

    // Sort categories
    final categories = byCategory.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    for (final category in categories) {
      final categoryResults = byCategory[category]!;
      final passed = categoryResults.where((r) => r.passed).length;
      final total = categoryResults.length;
      final passRate = (passed / total) * 100;

      final statusIcon = passRate == 100
          ? '$_green✅$_reset'
          : passRate >= 50
          ? '$_yellow⚠️$_reset'
          : '$_red❌$_reset';

      final rateColor = passRate == 100
          ? _green
          : passRate >= 50
          ? _yellow
          : _red;

      final categoryName = category.displayName.padRight(15);

      print(
        '  $statusIcon $categoryName ${passed.toString().padLeft(3)}/${total.toString().padLeft(3)}   ($rateColor${passRate.toStringAsFixed(1)}%$_reset)',
      );
    }

    print('');
  }

  void _printCoverageAnalysis(CoverageReport coverage) {
    print('$_bold📊 COVERAGE ANALYSIS$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final tokenColor = coverage.tokenCoveragePercent >= 50
        ? _green
        : coverage.tokenCoveragePercent >= 25
        ? _yellow
        : _red;

    final directiveColor = coverage.directiveCoveragePercent >= 50
        ? _green
        : coverage.directiveCoveragePercent >= 25
        ? _yellow
        : _red;

    print(
      '  Token Types:      ${coverage.tokenTypesCovered}/~200 tested ($tokenColor${coverage.tokenCoveragePercent.toStringAsFixed(1)}%$_reset)',
    );
    print(
      '  Directives:       ${coverage.directivesCovered}/~75  tested ($directiveColor${coverage.directiveCoveragePercent.toStringAsFixed(1)}%$_reset)',
    );
    print('');
  }

  void _printTopTokens(CoverageReport coverage) {
    print('$_bold🔤 MOST USED TOKENS (TOP 10)$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final topTokens = coverage.tokensByUsage.take(10).toList();

    if (topTokens.isEmpty) {
      print('  ${_gray}No tokens found$_reset');
    } else {
      for (final entry in topTokens) {
        final name = entry.key.name.padRight(25);
        final count = entry.value.toString().padLeft(4);
        final bar = _makeBar(entry.value, topTokens.first.value, 20);
        print('  $_cyan$name$_reset $count $_gray$bar$_reset');
      }
    }

    print('');
  }

  void _printTopDirectives(CoverageReport coverage) {
    print('$_bold⚡ DIRECTIVES USED (TOP 10)$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final topDirectives = coverage.directivesByUsage.take(10).toList();

    if (topDirectives.isEmpty) {
      print('  ${_gray}No directives found$_reset');
    } else {
      for (final entry in topDirectives) {
        final name = '@${entry.key}'.padRight(25);
        final count = entry.value.toString().padLeft(4);
        final bar = _makeBar(entry.value, topDirectives.first.value, 20);
        print('  $_cyan$name$_reset $count $_gray$bar$_reset');
      }
    }

    print('');
  }

  void _printFailures(List<TestResult> results) {
    final failures = results.where((r) => !r.passed).toList();

    if (failures.isEmpty) {
      print('$_green$_bold🎉 NO FAILURES - ALL TESTS PASSED!$_reset');
      print('');
      return;
    }

    print('$_bold$_red❌ FAILURES (${failures.length})$_reset');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (final failure in failures) {
      print('');
      print('  $_red●$_reset ${failure.fixture.relativePath}');
      if (failure.failureReason != null) {
        print('    ${_gray}Reason:$_reset ${failure.failureReason}');
      }
      if (failure.errors.isNotEmpty) {
        print('    ${_gray}Errors:$_reset ${failure.errors.length}');
        for (final error in failure.errors.take(3)) {
          print('      - ${error.message}');
        }
        if (failure.errors.length > 3) {
          print('      $_gray... and ${failure.errors.length - 3} more$_reset');
        }
      }
    }

    print('');
  }

  void _printFooter() {
    print(
      '$_gray━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset',
    );
    print('');
  }

  String _formatTime(double ms) {
    if (ms < 1) {
      return '$_bold${(ms * 1000).toStringAsFixed(0)}$_reset$_grayμs$_reset';
    } else if (ms < 1000) {
      return '$_bold${ms.toStringAsFixed(1)}$_reset${_gray}ms$_reset';
    } else {
      return '$_bold${(ms / 1000).toStringAsFixed(2)}$_reset${_gray}s$_reset';
    }
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  String _makeBar(int value, int max, int width) {
    final barWidth = ((value / max) * width).round();
    return '█' * barWidth + '░' * (width - barWidth);
  }
}
