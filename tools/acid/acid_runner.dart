import 'package:blade_parser/blade_parser.dart';
import 'models/fixture_info.dart';
import 'models/test_result.dart';
import 'models/coverage_report.dart';

/// Runs the acid test on fixtures.
class AcidRunner {
  /// Test a single fixture.
  TestResult testFixture(FixtureInfo fixture) {
    final stopwatch = Stopwatch();
    List<Token> tokens = [];
    ParseResult? parseResult;
    double lexTimeMs = 0;
    double parseTimeMs = 0;
    bool lexSuccess = false;
    bool parseSuccess = false;
    String? failureReason;

    // Step 1: Lexing
    try {
      stopwatch.start();
      final lexer = BladeLexer(fixture.content);
      tokens = lexer.tokenize();
      stopwatch.stop();
      lexTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      lexSuccess = true;
    } catch (e) {
      stopwatch.stop();
      lexTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      failureReason = 'Lexer error: $e';
    }

    // Step 2: Parsing
    try {
      stopwatch.reset();
      stopwatch.start();
      final parser = BladeParser();
      parseResult = parser.parse(fixture.content);
      stopwatch.stop();
      parseTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      parseSuccess = parseResult.isSuccess;
    } catch (e) {
      stopwatch.stop();
      parseTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      failureReason ??= 'Parser error: $e';
    }

    // Extract token types used
    final tokensUsed = tokens.map((t) => t.type).toSet();

    // Extract directive names from tokens
    final directivesUsed = <String>{};
    for (final token in tokens) {
      if (token.type.name.startsWith('directive')) {
        final directiveName = token.type.name.substring('directive'.length);
        // Convert from camelCase to lowercase (e.g., 'directiveIf' -> 'if')
        final name =
            directiveName[0].toLowerCase() + directiveName.substring(1);
        directivesUsed.add(name);
      }
    }

    // Calculate AST depth
    int astDepth = 0;
    if (parseResult?.ast != null) {
      astDepth = _calculateDepth(parseResult!.ast!);
    }

    // Count nodes
    int nodeCount = 0;
    if (parseResult?.ast != null) {
      nodeCount = _countNodes(parseResult!.ast!);
    }

    return TestResult(
      fixture: fixture,
      lexSuccess: lexSuccess,
      parseSuccess: parseSuccess,
      tokenCount: tokens.length,
      nodeCount: nodeCount,
      lexTimeMs: lexTimeMs,
      parseTimeMs: parseTimeMs,
      tokensUsed: tokensUsed,
      directivesUsed: directivesUsed,
      errors: parseResult?.errors ?? [],
      failureReason: failureReason,
      astDepth: astDepth,
    );
  }

  /// Run tests on all fixtures.
  List<TestResult> runAll(List<FixtureInfo> fixtures) {
    return fixtures.map(testFixture).toList();
  }

  /// Analyze coverage from test results.
  CoverageReport analyzeCoverage(List<TestResult> results) {
    return CoverageReport.from(results);
  }

  /// Calculate the maximum depth of the AST.
  int _calculateDepth(AstNode node) {
    if (node.children.isEmpty) return 1;

    int maxChildDepth = 0;
    for (final child in node.children) {
      final childDepth = _calculateDepth(child);
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }

    return 1 + maxChildDepth;
  }

  /// Count total nodes in the AST.
  int _countNodes(AstNode node) {
    int count = 1; // Count this node

    for (final child in node.children) {
      count += _countNodes(child);
    }

    return count;
  }
}
