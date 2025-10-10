import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for deep nesting edge cases in the parser
///
/// This test suite validates that the parser can handle extreme nesting depths
/// without stack overflow and maintains correct AST structure at all levels.
void main() {
  group('Deep Directive Nesting', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('100 levels of @if nesting', () {
      // Generate deeply nested @if directives
      final depth = 100;
      final buffer = StringBuffer();

      // Opening @if directives
      for (var i = 0; i < depth; i++) {
        buffer.write('@if(true)\n');
      }

      // Content at deepest level
      buffer.write('<p>Deep content</p>\n');

      // Closing @endif directives
      for (var i = 0; i < depth; i++) {
        buffer.write('@endif\n');
      }

      final template = buffer.toString();

      // Parse should succeed without stack overflow
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Parser should handle 100 levels of nesting');
      expect(result.errors, isEmpty);

      // Verify nesting depth by traversing AST
      var currentNode = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');

      var actualDepth = 1;
      while (currentNode.children.whereType<DirectiveNode>().isNotEmpty) {
        final nested = currentNode.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'if');
        currentNode = nested;
        actualDepth++;
      }

      expect(actualDepth, equals(depth),
          reason: 'AST should maintain all $depth levels of nesting');

      // Verify content exists at deepest level
      final deepestChildren = currentNode.children;
      final hasHtmlContent = deepestChildren.any((c) => c is HtmlElementNode);
      expect(hasHtmlContent, isTrue,
          reason: 'Deepest level should contain the HTML content');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('50 levels of mixed directive nesting (@if + @foreach + @section)', () {
      final depth = 50;
      final buffer = StringBuffer();

      // Alternate between different directive types
      final directives = ['if', 'foreach', 'section'];

      for (var i = 0; i < depth; i++) {
        final directive = directives[i % directives.length];
        switch (directive) {
          case 'if':
            buffer.write('@if(\$var$i)\n');
            break;
          case 'foreach':
            buffer.write('@foreach(\$items$i as \$item$i)\n');
            break;
          case 'section':
            buffer.write("@section('section$i')\n");
            break;
        }
      }

      buffer.write('{{ \$deepValue }}\n');

      for (var i = depth - 1; i >= 0; i--) {
        final directive = directives[i % directives.length];
        switch (directive) {
          case 'if':
            buffer.write('@endif\n');
            break;
          case 'foreach':
            buffer.write('@endforeach\n');
            break;
          case 'section':
            buffer.write('@endsection\n');
            break;
        }
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Parser should handle mixed directive nesting');
      expect(result.errors, isEmpty);

      // Verify we can traverse the full depth
      var currentChildren = result.ast!.children;
      var nestingCount = 0;

      while (currentChildren.whereType<DirectiveNode>().isNotEmpty) {
        final directive = currentChildren.whereType<DirectiveNode>().first;
        currentChildren = directive.children;
        nestingCount++;

        // Safety check to prevent infinite loop
        if (nestingCount > depth + 10) break;
      }

      expect(nestingCount, equals(depth),
          reason: 'Should maintain all $depth levels of nesting');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Verify correct directive closing at deep nesting levels', () {
      // Test that closing directives match correctly even at deep levels
      final depth = 30;
      final buffer = StringBuffer();

      // Create intentionally varied nesting to test matching
      for (var i = 0; i < depth; i++) {
        buffer.write('@if(\$level == $i)\n');
      }

      buffer.write('<span>Matched!</span>\n');

      // Close all directives
      for (var i = 0; i < depth; i++) {
        buffer.write('@endif\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty,
          reason: 'All directives should match correctly');

      // Verify AST structure is complete
      var node = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');

      for (var i = 0; i < depth; i++) {
        expect(node.name, equals('if'));

        if (i < depth - 1) {
          final nested = node.children.whereType<DirectiveNode>();
          expect(nested, isNotEmpty,
              reason: 'Level $i should have nested directive');
          node = nested.first;
        }
      }
    }, timeout: Timeout(Duration(seconds: 5)));
  });

  group('Deep Component Nesting', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('50 levels of component nesting', () {
      final depth = 50;
      final buffer = StringBuffer();

      // Opening tags
      for (var i = 0; i < depth; i++) {
        buffer.write('<x-level$i>\n');
      }

      buffer.write('<p>Core content</p>\n');

      // Closing tags (in reverse order)
      for (var i = depth - 1; i >= 0; i--) {
        buffer.write('</x-level$i>\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Parser should handle 50 levels of component nesting');
      expect(result.errors, isEmpty);

      // Traverse component tree
      var currentChildren = result.ast!.children;
      var componentDepth = 0;

      while (currentChildren.whereType<ComponentNode>().isNotEmpty) {
        final component = currentChildren.whereType<ComponentNode>().first;
        currentChildren = component.children;
        componentDepth++;

        // Safety limit
        if (componentDepth > depth + 10) break;
      }

      expect(componentDepth, equals(depth),
          reason: 'Should maintain full component nesting depth');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Components with slots at multiple nesting levels', () {
      final depth = 20;
      final buffer = StringBuffer();

      // Create nested components, each with a slot
      for (var i = 0; i < depth; i++) {
        buffer.write('<x-container$i>\n');
        buffer.write('<x-slot:header>Header $i</x-slot:header>\n');
      }

      buffer.write('<div>Final content</div>\n');

      for (var i = depth - 1; i >= 0; i--) {
        buffer.write('</x-container$i>\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle components with slots at multiple levels');

      // Verify slots exist at various levels
      var currentChildren = result.ast!.children;
      var levelsWithSlots = 0;

      for (var i = 0; i < depth && currentChildren.whereType<ComponentNode>().isNotEmpty; i++) {
        final component = currentChildren.whereType<ComponentNode>().first;

        if (component.slots.containsKey('header')) {
          levelsWithSlots++;
        }

        currentChildren = component.children;
      }

      expect(levelsWithSlots, greaterThan(0),
          reason: 'Slots should be recognized at nested levels');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Mixed component and HTML element nesting', () {
      final depth = 30;
      final buffer = StringBuffer();

      // Alternate between components and HTML
      for (var i = 0; i < depth; i++) {
        if (i % 2 == 0) {
          buffer.write('<x-wrapper$i>\n');
        } else {
          buffer.write('<div class="level$i">\n');
        }
      }

      buffer.write('<span>Mixed content</span>\n');

      for (var i = depth - 1; i >= 0; i--) {
        if (i % 2 == 0) {
          buffer.write('</x-wrapper$i>\n');
        } else {
          buffer.write('</div>\n');
        }
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle mixed component/HTML nesting');

      // Count total nesting depth
      var currentChildren = result.ast!.children;
      var totalDepth = 0;

      while (currentChildren.isNotEmpty) {
        final nextNode = currentChildren.firstWhere(
          (n) => n is ComponentNode || n is HtmlElementNode,
          orElse: () => currentChildren.first,
        );

        if (nextNode is ComponentNode) {
          currentChildren = nextNode.children;
          totalDepth++;
        } else if (nextNode is HtmlElementNode) {
          currentChildren = nextNode.children;
          totalDepth++;
        } else {
          break;
        }

        // Safety limit
        if (totalDepth > depth + 10) break;
      }

      expect(totalDepth, greaterThanOrEqualTo(depth - 5),
          reason: 'Should maintain most of the nesting structure');
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Mixed Directive/Component Nesting', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Directives containing deeply nested components', () {
      final depth = 20;
      final buffer = StringBuffer();

      // Outer layer: directives
      for (var i = 0; i < depth; i++) {
        buffer.write('@if(\$condition$i)\n');
        buffer.write('<x-box$i>\n');
      }

      buffer.write('<p>Deeply nested content</p>\n');

      for (var i = depth - 1; i >= 0; i--) {
        buffer.write('</x-box$i>\n');
        buffer.write('@endif\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle directives with nested components');
      expect(result.errors, isEmpty);

      // Verify mixed nesting structure
      // Structure: @if -> component -> @if -> component -> ...
      var currentNode = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');

      var mixedDepth = 0;
      while (mixedDepth < depth && currentNode.children.isNotEmpty) {
        // Should find component within directive
        final component = currentNode.children.whereType<ComponentNode>().firstOrNull;
        expect(component, isNotNull,
            reason: 'Directive at level $mixedDepth should contain component');

        if (component == null) break;

        // Navigate deeper - next directive is inside the component
        final nextDirective = component.children.whereType<DirectiveNode>().firstOrNull;
        if (nextDirective != null && nextDirective.name == 'if') {
          currentNode = nextDirective;
          mixedDepth++;
        } else {
          break;
        }
      }

      expect(mixedDepth, greaterThan(depth ~/ 2),
          reason: 'Should maintain significant mixed nesting depth');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Components containing deeply nested directives', () {
      final depth = 20;
      final buffer = StringBuffer();

      // Outer layer: components
      for (var i = 0; i < depth; i++) {
        buffer.write('<x-container$i>\n');
        buffer.write('@foreach(\$items$i as \$item$i)\n');
      }

      buffer.write('{{ \$item }}\n');

      for (var i = depth - 1; i >= 0; i--) {
        buffer.write('@endforeach\n');
        buffer.write('</x-container$i>\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle components with nested directives');
      expect(result.errors, isEmpty);

      // Verify nesting structure
      var currentChildren = result.ast!.children;
      var nestingLevel = 0;

      while (nestingLevel < depth && currentChildren.isNotEmpty) {
        // Should find component
        final component = currentChildren.whereType<ComponentNode>().firstOrNull;
        if (component != null) {
          // Component should contain directive
          final hasDirective = component.children.any((c) => c is DirectiveNode);
          expect(hasDirective, isTrue,
              reason: 'Component at level $nestingLevel should contain directive');

          // Navigate to directive's children
          final directive = component.children.whereType<DirectiveNode>().firstOrNull;
          if (directive != null) {
            currentChildren = directive.children;
            nestingLevel++;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      expect(nestingLevel, greaterThan(depth ~/ 2),
          reason: 'Should maintain significant nesting depth');
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Deep HTML Nesting with Directives', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('100 levels of HTML with directive at deepest level', () {
      final depth = 100;
      final buffer = StringBuffer();

      // Opening tags
      for (var i = 0; i < depth; i++) {
        buffer.write('<div class="level$i">\n');
      }

      // Directive at deepest level
      buffer.write('@if(\$show)\n');
      buffer.write('<p>Deep directive content</p>\n');
      buffer.write('@endif\n');

      // Closing tags
      for (var i = 0; i < depth; i++) {
        buffer.write('</div>\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle 100 levels of HTML nesting');
      expect(result.errors, isEmpty);

      // Traverse to deepest level
      var currentChildren = result.ast!.children;
      var htmlDepth = 0;

      while (currentChildren.whereType<HtmlElementNode>().isNotEmpty) {
        final element = currentChildren.whereType<HtmlElementNode>().first;
        expect(element.tagName, equals('div'));
        currentChildren = element.children;
        htmlDepth++;

        if (htmlDepth > depth + 10) break; // Safety limit
      }

      expect(htmlDepth, equals(depth),
          reason: 'Should maintain all $depth levels of HTML nesting');

      // Verify directive exists at deepest level
      final hasDirective = currentChildren.any((c) => c is DirectiveNode);
      expect(hasDirective, isTrue,
          reason: 'Directive should work at deepest HTML level');
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Echo statements at various HTML nesting depths', () {
      final depth = 50;
      final buffer = StringBuffer();

      // Create nested structure with echo at multiple levels
      for (var i = 0; i < depth; i++) {
        buffer.write('<div>\n');

        // Add echo every 10 levels
        if (i % 10 == 0) {
          buffer.write('{{ \$var$i }}\n');
        }
      }

      buffer.write('{{ \$finalValue }}\n');

      for (var i = 0; i < depth; i++) {
        buffer.write('</div>\n');
      }

      final template = buffer.toString();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue,
          reason: 'Should handle echo statements at various nesting depths');
      expect(result.errors, isEmpty);

      // Count total echo nodes in tree
      var echoCount = 0;

      void countEchoes(List<AstNode> children) {
        for (final child in children) {
          if (child is EchoNode) {
            echoCount++;
          }
          if (child.children.isNotEmpty) {
            countEchoes(child.children);
          }
        }
      }

      countEchoes(result.ast!.children);

      // Should have echo at multiple levels
      final expectedEchos = (depth / 10).floor() + 1; // One every 10 levels + final
      expect(echoCount, equals(expectedEchos),
          reason: 'Should find all echo statements at various depths');
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Performance Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parsing time should be reasonable for extreme nesting', () {
      final depth = 100;
      final buffer = StringBuffer();

      // Create complex nested structure
      for (var i = 0; i < depth; i++) {
        buffer.write('@if(\$level$i)\n');
        buffer.write('<div class="container$i">\n');
      }

      buffer.write('{{ \$content }}\n');

      for (var i = depth - 1; i >= 0; i--) {
        buffer.write('</div>\n');
        buffer.write('@endif\n');
      }

      final template = buffer.toString();

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      expect(stopwatch.elapsed.inSeconds, lessThan(5),
          reason: 'Parsing should complete in under 5 seconds');

      print('Parsed $depth levels in ${stopwatch.elapsedMilliseconds}ms');
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
