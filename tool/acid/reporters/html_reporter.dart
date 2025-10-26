import 'dart:io';
import '../models/test_result.dart';
import '../models/coverage_report.dart';
import '../models/fixture_info.dart';

/// HTML reporter that generates a standalone HTML report.
class HtmlReporter {
  /// Generate and save HTML report.
  void generateReport(
    List<TestResult> results,
    CoverageReport coverage,
    String outputPath,
  ) {
    final html = _buildHtml(results, coverage);
    File(outputPath).writeAsStringSync(html);
  }

  String _buildHtml(List<TestResult> results, CoverageReport coverage) {
    final timestamp = DateTime.now().toIso8601String();

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blade Parser Acid Test Report</title>
    ${_buildStyles()}
</head>
<body>
    <div class="container">
        <header>
            <h1>🧪 Blade Parser Acid Test Report</h1>
            <p class="timestamp">Generated: $timestamp</p>
        </header>

        ${_buildSummaryCards(coverage)}
        ${_buildCategorySection(results)}
        ${_buildCoverageSection(coverage)}
        ${_buildFailuresSection(results)}
        ${_buildDetailedResults(results)}
    </div>
</body>
</html>
''';
  }

  String _buildStyles() {
    return '''
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background: #f5f5f5;
        padding: 0;
        line-height: 1.5;
        font-size: 14px;
    }

    .container {
        max-width: 100%;
        margin: 0;
        background: white;
        border: 3px solid #000;
    }

    header {
        background: #1a1a1a;
        color: #fff;
        padding: 16px 20px;
        border-bottom: 3px solid #000;
    }

    header h1 {
        font-family: 'JetBrains Mono', monospace;
        font-size: 18px;
        font-weight: 700;
        letter-spacing: -0.5px;
    }

    .timestamp {
        font-family: 'JetBrains Mono', monospace;
        font-size: 12px;
        color: #999;
        margin-top: 4px;
    }

    .summary {
        background: #e8e8e8;
        padding: 10px 20px;
        border-bottom: 2px solid #000;
    }

    .summary table {
        width: 100%;
        border: 1px solid #000;
        background: #fff;
    }

    .summary th {
        background: #ccc;
        border: 1px solid #000;
        padding: 6px 10px;
        text-align: left;
        font-weight: 600;
        text-transform: uppercase;
        font-size: 12px;
        letter-spacing: 0.3px;
    }

    .summary td {
        border: 1px solid #000;
        padding: 6px 10px;
        font-weight: 600;
    }

    .success { color: #080; background: #cfc; }
    .danger { color: #800; background: #fcc; }
    .warning { color: #840; background: #ffc; }
    .info { color: #008; background: #ccf; }

    section {
        padding: 20px;
        border-bottom: 2px solid #000;
    }

    section:last-child {
        border-bottom: none;
    }

    h2 {
        font-family: 'JetBrains Mono', monospace;
        font-size: 15px;
        margin-bottom: 12px;
        color: #000;
        font-weight: 700;
        text-transform: uppercase;
        border-bottom: 2px solid #000;
        padding-bottom: 6px;
        letter-spacing: 0.5px;
    }

    h3 {
        font-family: 'JetBrains Mono', monospace;
        font-size: 13px;
        margin: 16px 0 8px 0;
        font-weight: 600;
        text-transform: uppercase;
        text-decoration: underline;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 10px;
        border: 2px solid #000;
        background: white;
    }

    thead {
        background: #ccc;
    }

    th, td {
        padding: 6px 10px;
        text-align: left;
        border: 1px solid #000;
        font-size: 13px;
    }

    th {
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.3px;
    }

    td {
        font-family: 'JetBrains Mono', monospace;
    }

    tbody tr:nth-child(even) {
        background: #f9f9f9;
    }

    .badge {
        display: inline-block;
        padding: 2px 6px;
        font-weight: bold;
        border: 1px solid #000;
    }

    .badge-success {
        background: #cfc;
        color: #080;
    }

    .badge-danger {
        background: #fcc;
        color: #800;
    }

    .badge-warning {
        background: #ffc;
        color: #840;
    }

    .coverage-list {
        margin-top: 10px;
        border: 1px solid #000;
        background: #fff;
    }

    .coverage-list table {
        border: none;
        margin: 0;
    }

    .coverage-list th {
        background: #ddd;
    }

    .coverage-list td {
        font-family: 'JetBrains Mono', monospace;
    }

    .failure-details {
        background: #fcc;
        border: 2px solid #800;
        padding: 10px;
        margin: 10px 0;
        font-family: 'JetBrains Mono', monospace;
    }

    .failure-title {
        font-weight: 600;
        color: #800;
        margin-bottom: 6px;
        font-size: 13px;
    }

    .failure-reason {
        color: #840;
        font-size: 12px;
        margin-bottom: 6px;
        font-style: italic;
    }

    .error-list {
        background: white;
        border: 1px solid #000;
        padding: 8px;
        margin-top: 6px;
        font-size: 12px;
    }

    .error-list-item {
        margin: 2px 0;
        padding-left: 12px;
        position: relative;
    }

    .error-list-item:before {
        content: ">";
        position: absolute;
        left: 0;
        color: #800;
        font-weight: bold;
    }

    pre {
        font-family: 'JetBrains Mono', monospace;
        background: #f0f0f0;
        border: 1px solid #000;
        padding: 10px;
        overflow-x: auto;
        font-size: 12px;
        line-height: 1.5;
    }

    @media print {
        body {
            background: white;
        }

        .container {
            border: 1px solid #000;
        }
    }
</style>
''';
  }

  String _buildSummaryCards(CoverageReport coverage) {
    final passRateClass = coverage.passRate >= 90
        ? 'success'
        : coverage.passRate >= 70
            ? 'warning'
            : 'danger';

    return '''
<div class="summary">
    <table>
        <thead>
            <tr>
                <th>Metric</th>
                <th>Value</th>
                <th>Details</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Total Fixtures</td>
                <td><strong>${coverage.totalTests}</strong></td>
                <td>-</td>
            </tr>
            <tr class="$passRateClass">
                <td>Pass Rate</td>
                <td><strong>${coverage.passRate.toStringAsFixed(1)}%</strong></td>
                <td>${coverage.passedTests} passed, ${coverage.failedTests} failed</td>
            </tr>
            <tr>
                <td>Total Time</td>
                <td><strong>${_formatTimeCard(coverage.totalTimeMs)}</strong></td>
                <td>Avg: ${_formatTimeCard(coverage.avgTimeMs)}/file</td>
            </tr>
            <tr>
                <td>Total Tokens</td>
                <td><strong>${_formatNumber(coverage.totalTokens)}</strong></td>
                <td>-</td>
            </tr>
            <tr>
                <td>Total Nodes</td>
                <td><strong>${_formatNumber(coverage.totalNodes)}</strong></td>
                <td>-</td>
            </tr>
            <tr>
                <td>Token Types</td>
                <td><strong>${coverage.tokenTypesCovered}/~200</strong></td>
                <td>${coverage.tokenCoveragePercent.toStringAsFixed(1)}% coverage</td>
            </tr>
            <tr>
                <td>Directives</td>
                <td><strong>${coverage.directivesCovered}/~75</strong></td>
                <td>${coverage.directiveCoveragePercent.toStringAsFixed(1)}% coverage</td>
            </tr>
        </tbody>
    </table>
</div>
''';
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  String _buildCategorySection(List<TestResult> results) {
    final byCategory = <FixtureCategory, List<TestResult>>{};
    for (final result in results) {
      byCategory.putIfAbsent(result.fixture.category, () => []).add(result);
    }

    final categories = byCategory.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    final rows = categories.map((category) {
      final categoryResults = byCategory[category]!;
      final passed = categoryResults.where((r) => r.passed).length;
      final total = categoryResults.length;
      final passRate = (passed / total) * 100;

      final rowClass = passRate == 100
          ? 'success'
          : passRate >= 50
              ? 'warning'
              : 'danger';

      return '''
<tr class="$rowClass">
    <td><strong>${category.displayName}</strong></td>
    <td align="right">$total</td>
    <td align="right">$passed</td>
    <td align="right">$total - $passed</td>
    <td align="right">${passRate.toStringAsFixed(1)}%</td>
</tr>
''';
    }).join('\n');

    return '''
<section>
    <h2>RESULTS BY CATEGORY</h2>
    <table>
        <thead>
            <tr>
                <th>Category</th>
                <th align="right">Total</th>
                <th align="right">Passed</th>
                <th align="right">Failed</th>
                <th align="right">Pass Rate</th>
            </tr>
        </thead>
        <tbody>
            $rows
        </tbody>
    </table>
</section>
''';
  }

  String _buildCoverageSection(CoverageReport coverage) {
    final tokenRows = coverage.tokensByUsage
        .take(20)
        .map(
          (entry) => '''
<tr>
    <td>${entry.key.name}</td>
    <td align="right"><strong>${entry.value}</strong></td>
</tr>
''',
        )
        .join('\n');

    final directiveRows = coverage.directivesByUsage
        .take(20)
        .map(
          (entry) => '''
<tr>
    <td>@${entry.key}</td>
    <td align="right"><strong>${entry.value}</strong></td>
</tr>
''',
        )
        .join('\n');

    return '''
<section>
    <h2>COVERAGE ANALYSIS</h2>

    <h3>Top 20 Token Types</h3>
    <div class="coverage-list">
        <table>
            <thead>
                <tr>
                    <th>Token Type</th>
                    <th align="right">Count</th>
                </tr>
            </thead>
            <tbody>
                $tokenRows
            </tbody>
        </table>
    </div>

    <h3>Top 20 Directives</h3>
    <div class="coverage-list">
        <table>
            <thead>
                <tr>
                    <th>Directive</th>
                    <th align="right">Count</th>
                </tr>
            </thead>
            <tbody>
                $directiveRows
            </tbody>
        </table>
    </div>
</section>
''';
  }

  String _buildFailuresSection(List<TestResult> results) {
    final failures = results.where((r) => !r.passed).toList();

    if (failures.isEmpty) {
      return '''
<section>
    <h2>NO FAILURES</h2>
    <p><strong>All tests passed successfully!</strong></p>
</section>
''';
    }

    final failureCards = failures.map((failure) {
      final errorsList = failure.errors
          .take(5)
          .map(
            (error) =>
                '<div class="error-list-item">${_escapeHtml(error.message)}</div>',
          )
          .join('\n');

      final moreErrors = failure.errors.length > 5
          ? '<div class="error-list-item">... ${failure.errors.length - 5} more errors omitted</div>'
          : '';

      return '''
<div class="failure-details">
    <div class="failure-title">[FAIL] ${_escapeHtml(failure.fixture.relativePath)}</div>
    ${failure.failureReason != null ? '<div class="failure-reason">${_escapeHtml(failure.failureReason!)}</div>' : ''}
    ${failure.errors.isNotEmpty ? '''
    <div class="error-list">
        <strong>Errors (${failure.errors.length}):</strong>
        $errorsList
        $moreErrors
    </div>
    ''' : ''}
</div>
''';
    }).join('\n');

    return '''
<section>
    <h2>FAILURES (${failures.length})</h2>
    $failureCards
</section>
''';
  }

  String _buildDetailedResults(List<TestResult> results) {
    final rows = results.map((result) {
      final status = result.passed ? 'PASS' : 'FAIL';
      final rowClass = result.passed ? '' : 'danger';

      return '''
<tr class="$rowClass">
    <td>${_escapeHtml(result.fixture.relativePath)}</td>
    <td>${result.fixture.category.displayName}</td>
    <td><strong>[$status]</strong></td>
    <td align="right">${result.tokenCount}</td>
    <td align="right">${result.nodeCount}</td>
    <td align="right">${result.astDepth}</td>
    <td align="right">${_formatTime(result.totalTimeMs)}</td>
</tr>
''';
    }).join('\n');

    return '''
<section>
    <h2>DETAILED RESULTS (ALL FIXTURES)</h2>
    <table>
        <thead>
            <tr>
                <th>Fixture</th>
                <th>Category</th>
                <th>Status</th>
                <th align="right">Tokens</th>
                <th align="right">Nodes</th>
                <th align="right">Depth</th>
                <th align="right">Time</th>
            </tr>
        </thead>
        <tbody>
            $rows
        </tbody>
    </table>
</section>
''';
  }

  String _formatTimeCard(double ms) {
    if (ms < 1) {
      return '${(ms * 1000).toStringAsFixed(0)}μs';
    } else if (ms < 1000) {
      return '${ms.toStringAsFixed(1)}ms';
    } else {
      return '${(ms / 1000).toStringAsFixed(2)}s';
    }
  }

  String _formatTime(double ms) {
    if (ms < 1) return '${(ms * 1000).toStringAsFixed(0)}μs';
    if (ms < 1000) return '${ms.toStringAsFixed(2)}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
