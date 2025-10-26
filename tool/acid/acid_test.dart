import 'dart:io';

import 'package:args/args.dart';

import 'acid_runner.dart';
import 'reporters/console_reporter.dart';
import 'reporters/html_reporter.dart';
import 'utils/fixture_scanner.dart';

/// Main entry point for the Blade Parser Acid Test.
///
/// Usage:
///   dart tool/acid/acid_test.dart [options]
///
/// Options:
///   -f, --format=<type>    Output format: console, html, or both (default: console)
///   -o, --output=<path>    Custom path for HTML report
///       --open             Open the HTML report automatically after generation
///   -h, --help             Show this help message
void main(List<String> args) async {
  // Set up argument parser
  final parser = ArgParser()
    ..addOption(
      'format',
      abbr: 'f',
      defaultsTo: 'console',
      allowed: ['console', 'html', 'both'],
      help: 'Output format',
      allowedHelp: {
        'console': 'Print colored console output',
        'html': 'Generate HTML report only',
        'both': 'Generate both console and HTML output',
      },
    )
    ..addOption('output', abbr: 'o', help: 'Custom path for HTML report')
    ..addFlag(
      'open',
      help: 'Open the HTML report automatically after generation',
      defaultsTo: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  // Parse arguments
  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (e) {
    print('Error: ${e.message}\n');
    print(parser.usage);
    exit(2);
  }

  // Show help if requested
  if (argResults.flag('help')) {
    print('Blade Parser Acid Test\n');
    print('Usage: dart tool/acid/acid_test.dart [options]\n');
    print('Options:');
    print(parser.usage);
    exit(0);
  }

  // Extract parsed values
  final format = argResults.option('format')!;
  var outputPath = argResults.option('output');
  final openReport = argResults.flag('open');

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
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    outputPath ??=
        '$projectRoot/tool/acid/reports/acid_test_report_$timestamp.html';

    // Ensure reports directory exists
    final reportsDir = Directory('$projectRoot/tool/acid/reports');
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }

    final htmlReporter = HtmlReporter();
    htmlReporter.generateReport(results, coverage, outputPath);

    print('📄 HTML report generated: $outputPath');
    print('');

    if (openReport) {
      // Open the report in the default browser
      if (Platform.isWindows) {
        Process.run('start', [outputPath], runInShell: true);
      } else if (Platform.isMacOS) {
        Process.run('open', [outputPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [outputPath]);
      }
    }
  }

  // Exit with appropriate code
  if (coverage.failedTests > 0) {
    exit(1);
  } else {
    exit(0);
  }
}
