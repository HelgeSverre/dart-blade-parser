import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Security-Related Edge Case Tests
///
/// These tests verify that the parser handles security-sensitive content correctly.
/// IMPORTANT: We're testing PARSING behavior, not runtime security. The parser's job
/// is to correctly parse potentially malicious-looking syntax without crashing, hanging,
/// or corrupting. Runtime security (XSS prevention, SQL injection, etc.) is handled
/// by Laravel's execution engine, not by the parser.
///
/// Test Coverage:
/// 1. XSS patterns in echo statements (parsing only)
/// 2. SQL injection patterns as literal strings
/// 3. Path traversal in @include directives
/// 4. Very long attribute values (DoS prevention)
/// 5. Deeply nested structures (stack overflow prevention)
/// 6. Recursive @include patterns (syntax handling)
/// 7. Special characters in variable names
void main() {
  group('Security: XSS Patterns in Echo Statements', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parses script tag injection pattern in echo', () {
      const template = "{{ '<script>alert(1)</script>' }}";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should parse XSS pattern without crashing',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, equals("'<script>alert(1)</script>'"));
      expect(
        echoNodes.first.isRaw,
        isFalse,
        reason: 'Standard echo should not be marked as raw',
      );

      // Verify the entire dangerous pattern is captured as-is
      expect(echoNodes.first.expression, contains('<script>'));
      expect(echoNodes.first.expression, contains('alert'));
    });

    test('Parses img onerror XSS pattern in echo', () {
      const template = "{{ '<img src=x onerror=alert(1)>' }}";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle img onerror pattern',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, contains('onerror'));
      expect(echoNodes.first.expression, contains('alert'));

      // Parser should not execute or sanitize - just capture
      expect(
        echoNodes.first.expression,
        equals("'<img src=x onerror=alert(1)>'"),
      );
    });

    test('Parses javascript: protocol XSS pattern', () {
      const template = "{{ 'javascript:alert(document.cookie)' }}";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle javascript: protocol',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, contains('javascript:'));
      expect(echoNodes.first.expression, contains('document.cookie'));

      // Verify entire expression captured without modification
      expect(
        echoNodes.first.expression,
        equals("'javascript:alert(document.cookie)'"),
      );
    });
  });

  group('Security: SQL Injection Patterns', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parses SQL injection in echo statement', () {
      const template = r"{{ $id . '; DROP TABLE users; --' }}";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle SQL injection patterns',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));

      // Verify the SQL injection pattern is captured as literal string
      expect(echoNodes.first.expression, contains('DROP TABLE'));
      expect(echoNodes.first.expression, contains('--'));
    });

    test('Parses SQL injection pattern in @if directive', () {
      const template = r'''
@if($id == "1 OR 1=1")
    <p>User found</p>
@endif
''';
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle SQL injection in conditionals',
      );

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));
      expect(directives.first.name, equals('if'));

      // Verify expression contains the SQL injection pattern
      expect(directives.first.expression, contains('OR 1=1'));
    });
  });

  group('Security: Path Traversal in @include', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parses path traversal with parent directory references', () {
      const template = "@include('../../../etc/passwd')";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should parse path traversal syntax',
      );

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));
      expect(directives.first.name, equals('include'));

      // Verify path is captured without validation (validation is runtime)
      expect(directives.first.expression, contains('../../../'));
      expect(directives.first.expression, contains('etc/passwd'));
    });

    test('Parses config file path traversal', () {
      const template = "@include('../../config/database')";
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));
      expect(directives.first.expression, contains('../../config'));
    });

    test('Parses variable include path (potential user input)', () {
      const template = r'@include($userInput)';
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle variable paths',
      );

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));
      // Parser wraps expression in parentheses
      expect(directives.first.expression, equals(r'($userInput)'));

      // Parser doesn't validate variable content - that's runtime
    });
  });

  group('Security: Very Long Attribute Values (DoS Prevention)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test(
      'Handles 10,000 character attribute value without hanging',
      () {
        final longValue = 'a' * 10000;
        final template = '<div class="$longValue">Content</div>';

        final stopwatch = Stopwatch()..start();
        final result = parser.parse(template);
        stopwatch.stop();

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should handle long attributes',
        );
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(5),
          reason: 'Should parse in reasonable time',
        );

        final htmlElements = result.ast!.children.whereType<HtmlElementNode>();
        expect(htmlElements.length, equals(1));
        expect(htmlElements.first.attributes['class'], isNotNull);
        expect(
          htmlElements.first.attributes['class']!.value!.length,
          equals(10000),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'Handles 100,000 character attribute value gracefully',
      () {
        final longValue = 'b' * 100000;
        final template = '<input value="$longValue" />';

        final stopwatch = Stopwatch()..start();
        final result = parser.parse(template);
        stopwatch.stop();

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should handle very long attributes',
        );
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(10),
          reason: 'Should complete within timeout',
        );

        final htmlElements = result.ast!.children.whereType<HtmlElementNode>();
        expect(htmlElements.length, equals(1));
        expect(htmlElements.first.attributes['value'], isNotNull);
        expect(
          htmlElements.first.attributes['value']!.value!.length,
          equals(100000),
        );

        print(
          'Parsed 100k character attribute in ${stopwatch.elapsedMilliseconds}ms',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('Security: Deeply Nested Structures (Stack Overflow Prevention)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test(
      'Handles 500 levels of nested directives without stack overflow',
      () {
        const depth = 500;
        final buffer = StringBuffer();

        // Create deeply nested @if directives
        for (var i = 0; i < depth; i++) {
          buffer.write('@if(true)\n');
        }

        buffer.write('<p>Deep content</p>\n');

        for (var i = 0; i < depth; i++) {
          buffer.write('@endif\n');
        }

        final template = buffer.toString();

        final stopwatch = Stopwatch()..start();
        final result = parser.parse(template);
        stopwatch.stop();

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should handle 500 levels without stack overflow',
        );
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(10),
          reason: 'Should parse in reasonable time',
        );

        // Verify nesting depth
        var currentNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'if');

        var actualDepth = 1;
        while (currentNode.children.whereType<DirectiveNode>().isNotEmpty) {
          final nested = currentNode.children
              .whereType<DirectiveNode>()
              .where((n) => n.name == 'if')
              .firstOrNull;
          if (nested == null) break;
          currentNode = nested;
          actualDepth++;

          // Safety limit
          if (actualDepth > depth + 10) break;
        }

        expect(
          actualDepth,
          greaterThan(depth - 50),
          reason: 'Should maintain most of the nesting structure',
        );

        print(
          'Parsed $actualDepth levels in ${stopwatch.elapsedMilliseconds}ms',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'Handles 1000 levels of nested HTML elements',
      () {
        const depth = 1000;
        final buffer = StringBuffer();

        // Create deeply nested HTML
        for (var i = 0; i < depth; i++) {
          buffer.write('<div>\n');
        }

        buffer.write('<p>Deep HTML</p>\n');

        for (var i = 0; i < depth; i++) {
          buffer.write('</div>\n');
        }

        final template = buffer.toString();

        final stopwatch = Stopwatch()..start();
        final result = parser.parse(template);
        stopwatch.stop();

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should handle 1000 HTML levels',
        );
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(10),
          reason: 'Should complete within timeout',
        );

        // Verify nesting depth
        var currentChildren = result.ast!.children;
        var htmlDepth = 0;

        while (currentChildren.whereType<HtmlElementNode>().isNotEmpty) {
          final element = currentChildren.whereType<HtmlElementNode>().first;
          currentChildren = element.children;
          htmlDepth++;

          if (htmlDepth > depth + 10) break; // Safety limit
        }

        expect(
          htmlDepth,
          greaterThan(depth - 100),
          reason: 'Should maintain most HTML nesting',
        );

        print(
          'Parsed $htmlDepth HTML levels in ${stopwatch.elapsedMilliseconds}ms',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('Security: Recursive @include Patterns', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parses circular include references (syntax only)', () {
      // Template A includes B, but parser doesn't follow includes
      const templateA = r'''
<div>Template A</div>
@include('template-b')
<div>End of A</div>
''';

      final result = parser.parse(templateA);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser handles include syntax without following references',
      );

      final directives = result.ast!.children.whereType<DirectiveNode>();
      final includeDirectives =
          directives.where((d) => d.name == 'include').toList();

      expect(includeDirectives.length, equals(1));
      expect(includeDirectives.first.expression, contains('template-b'));

      // Parser doesn't follow includes, so no infinite loop risk
      // This is a syntax parsing test, not a runtime test
    });
  });

  group('Security: Special Characters in Variable Names', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parses unusual characters in echo expressions', () {
      // Test underscore and special characters that don't conflict with braces
      const template = r'{{ $unusual_chars_123 }}';
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle unusual syntax',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, equals(r'$unusual_chars_123'));

      // Note: PHP associative arrays with curly braces like {'key'} would be
      // problematic for the lexer as it uses braces as delimiters. This is
      // a known parser limitation, not a security issue.
    });

    test('Parses double dollar sign variable reference', () {
      const template = r'{{ $$variable }}';
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle variable variables',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, equals(r'$$variable'));
    });

    test('Parses special key access in objects', () {
      // Test array/object access syntax without conflicting braces
      const template = r"{{ $user['special-key'] }}";
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Parser should handle special key syntax',
      );

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, contains("['special-key']"));

      // Note: PHP's $obj->{'key'} syntax with curly braces would conflict
      // with the echo delimiter. Use square brackets or arrow notation instead.
    });
  });

  group('Security: Mixed Attack Vectors', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test(
      'Handles complex template with multiple security patterns',
      () {
        final template = r'''
@if($id == "1 OR 1=1")
    {{ '<script>alert(1)</script>' }}
    <div class="''' +
            ('a' * 5000) +
            r'''">
        @include('../../../etc/passwd')
        {!! $userInput !!}
        {{ $user['malicious-key'] }}
        {{ $$dynamicVar }}
    </div>
@endif
''';

        final stopwatch = Stopwatch()..start();
        final result = parser.parse(template);
        stopwatch.stop();

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should handle complex mixed patterns',
        );
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(5),
          reason: 'Should parse complex template efficiently',
        );

        // Verify all components are parsed
        final directives = result.ast!.children.whereType<DirectiveNode>();
        expect(directives.length, greaterThan(0));

        print(
          'Parsed complex security template in ${stopwatch.elapsedMilliseconds}ms',
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('Parser remains stable after encountering malicious patterns', () {
      final maliciousTemplates = [
        "{{ '<script>alert(1)</script>' }}",
        r"@include('../../../etc/passwd')",
        r"{{ $id . '; DROP TABLE users; --' }}",
        '<div class="${'x' * 10000}">Test</div>',
      ];

      for (final template in maliciousTemplates) {
        final result = parser.parse(template);

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Parser should remain stable for: $template',
        );
        expect(result.ast, isNotNull);
      }

      // Parser should still work after processing all malicious patterns
      const normalTemplate = '<p>Normal content {{ \$var }}</p>';
      final finalResult = parser.parse(normalTemplate);

      expect(
        finalResult.isSuccess,
        isTrue,
        reason: 'Parser should remain functional after malicious input',
      );
    });
  });

  group('Security: Parser Error Recovery', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Recovers gracefully from malformed security-sensitive input', () {
      const template = r'''
{{ '<script>alert(1)' }}
<div class="unclosed
@if($malformed
{{ $normal }}
''';

      final result = parser.parse(template);

      // Parser should not crash, though it may report errors
      expect(
        result.ast,
        isNotNull,
        reason: 'Parser should return AST even with errors',
      );

      // Should still parse what it can
      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(
        echoNodes,
        isNotEmpty,
        reason: 'Parser should recover and parse valid parts',
      );
    });
  });
}
