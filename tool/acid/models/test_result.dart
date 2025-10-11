import 'package:blade_parser/blade_parser.dart';
import 'fixture_info.dart';

/// Result of testing a single fixture.
class TestResult {
  final FixtureInfo fixture;
  final bool lexSuccess;
  final bool parseSuccess;
  final int tokenCount;
  final int nodeCount;
  final double lexTimeMs;
  final double parseTimeMs;
  final Set<TokenType> tokensUsed;
  final Set<String> directivesUsed;
  final List<ParseError> errors;
  final String? failureReason;
  final int astDepth;

  TestResult({
    required this.fixture,
    required this.lexSuccess,
    required this.parseSuccess,
    required this.tokenCount,
    required this.nodeCount,
    required this.lexTimeMs,
    required this.parseTimeMs,
    required this.tokensUsed,
    required this.directivesUsed,
    required this.errors,
    this.failureReason,
    required this.astDepth,
  });

  bool get passed {
    // Invalid fixtures are expected to have errors
    if (fixture.category == FixtureCategory.invalid) {
      return !parseSuccess && errors.isNotEmpty;
    }
    // All other fixtures should parse successfully
    return parseSuccess && errors.isEmpty;
  }

  String get statusIcon {
    if (passed) return '✅';
    if (fixture.category == FixtureCategory.invalid) return '⚠️';
    return '❌';
  }

  double get totalTimeMs => lexTimeMs + parseTimeMs;
}
