import 'dart:io';
import 'utils/fixture_scanner.dart';
import 'acid_runner.dart';
import 'reporters/console_reporter.dart';
import 'reporters/html_reporter.dart';

/// Main entry point for the Blade Parser Acid Test.
///
/// Usage:
///   dart test/acid/acid_test.dart [--format=console|html|both] [--output=path]
///
/// Options:
///   --format=console  Print colored console output (default)
///   --format=html     Generate HTML report only
///   --format=both     Generate both console and HTML output
///   --output=path     Custom path for HTML report (default: test/acid/reports/acid_test_report_TIMESTAMP.html)
void main(List<String> args) async {
  // Parse command-line arguments
  var format = 'console';
  String? outputPath;

  for (final arg in args) {
    if (arg.startsWith('--format=')) {
      format = arg.substring('--format='.length);
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length);
    }
  }

  if (!['console', 'html', 'both'].contains(format)) {
    print(
      'Error: Invalid format "$format". Must be one of: console, html, both',
    );
    exit(2);
  }

  // Determine fixtures path
  final scriptPath = Platform.script.toFilePath();
  final projectRoot = Directory(scriptPath).parent.parent.parent.path;
  final fixturesPath = '$projectRoot/test/fixtures';

  if (!Directory(fixturesPath).existsSync()) {
    print('Error: Fixtures directory not found at $fixturesPath');
    exit(2);
  }

  // Run the test
  print('🔍 Scanning fixtures...');
  final scanner = FixtureScanner(fixturesPath);
  final fixtures = scanner.scan();

  print('📝 Found ${fixtures.length} fixtures');
  print('');
  print('🧪 Running acid test...');
  print('');

  final runner = AcidRunner();
  final results = runner.runAll(fixtures);
  final coverage = runner.analyzeCoverage(results);

  // Generate reports based on format
  if (format == 'console' || format == 'both') {
    final consoleReporter = ConsoleReporter();
    consoleReporter.printReport(results, coverage);
  }

  if (format == 'html' || format == 'both') {
    // Determine output path
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    outputPath ??=
        '$projectRoot/tools/acid/reports/acid_test_report_$timestamp.html';

    // Ensure reports directory exists
    final reportsDir = Directory('$projectRoot/tools/acid/reports');
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }

    final htmlReporter = HtmlReporter();
    htmlReporter.generateReport(results, coverage, outputPath);

    print('📄 HTML report generated: $outputPath');
    print('');
  }

  // Exit with appropriate code
  if (coverage.failedTests > 0) {
    exit(1);
  } else {
    exit(0);
  }
}
