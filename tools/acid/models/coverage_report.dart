import 'package:blade_parser/blade_parser.dart';
import 'test_result.dart';

/// Coverage analysis across all test results.
class CoverageReport {
  final Map<TokenType, int> tokenUsage;
  final Map<String, int> directiveUsage;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final double totalTimeMs;
  final int totalTokens;
  final int totalNodes;

  CoverageReport({
    required this.tokenUsage,
    required this.directiveUsage,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.totalTimeMs,
    required this.totalTokens,
    required this.totalNodes,
  });

  factory CoverageReport.from(List<TestResult> results) {
    final tokenUsage = <TokenType, int>{};
    final directiveUsage = <String, int>{};
    var totalTokens = 0;
    var totalNodes = 0;
    var totalTimeMs = 0.0;
    var passedTests = 0;

    for (final result in results) {
      if (result.passed) passedTests++;

      totalTokens += result.tokenCount;
      totalNodes += result.nodeCount;
      totalTimeMs += result.totalTimeMs;

      for (final tokenType in result.tokensUsed) {
        tokenUsage[tokenType] = (tokenUsage[tokenType] ?? 0) + 1;
      }

      for (final directive in result.directivesUsed) {
        directiveUsage[directive] = (directiveUsage[directive] ?? 0) + 1;
      }
    }

    return CoverageReport(
      tokenUsage: tokenUsage,
      directiveUsage: directiveUsage,
      totalTests: results.length,
      passedTests: passedTests,
      failedTests: results.length - passedTests,
      totalTimeMs: totalTimeMs,
      totalTokens: totalTokens,
      totalNodes: totalNodes,
    );
  }

  double get passRate => totalTests > 0 ? (passedTests / totalTests) * 100 : 0;

  double get avgTimeMs => totalTests > 0 ? totalTimeMs / totalTests : 0;

  int get tokenTypesCovered => tokenUsage.length;

  int get directivesCovered => directiveUsage.length;

  /// Get all token types, sorted by usage count (descending)
  List<MapEntry<TokenType, int>> get tokensByUsage {
    final entries = tokenUsage.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get all directives, sorted by usage count (descending)
  List<MapEntry<String, int>> get directivesByUsage {
    final entries = directiveUsage.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Calculate coverage percentage for token types
  /// Note: There are ~200 token types defined, but many are specific variants
  double get tokenCoveragePercent {
    const totalTokenTypes = 200; // Approximate from TokenType enum
    return (tokenTypesCovered / totalTokenTypes) * 100;
  }

  /// Calculate coverage percentage for directives
  double get directiveCoveragePercent {
    const totalDirectives = 75; // From research.md
    return (directivesCovered / totalDirectives) * 100;
  }
}
