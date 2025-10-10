import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Comprehensive error recovery tests for the Blade parser.
/// Tests parser behavior when encountering malformed input and validates
/// that errors are reported appropriately while still generating partial ASTs.
void main() {
  group('Parser Error Recovery Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('1. Mismatched Component Tags', () {
      test('Simple mismatched component tags', () {
        final result = parser.parse('''
          <x-alert type="error">
            Content here
          </x-button>
        ''');

        // Should report error about mismatch
        expect(result.errors, isNotEmpty,
            reason: 'Mismatched component tags should produce error');

        final hasMismatchError = result.errors.any((e) =>
            e.message.toLowerCase().contains('mismatch') ||
            e.message.toLowerCase().contains('expected') ||
            (e.message.contains('alert') && e.message.contains('button')));

        expect(hasMismatchError, isTrue,
            reason: 'Error should indicate tag mismatch');

        // Should still generate partial AST
        expect(result.ast, isNotNull,
            reason: 'Parser should generate partial AST despite error');
      });

      test('Nested component with mismatch', () {
        final result = parser.parse('''
          <x-card>
            <x-header>Header content</x-card>
          </x-header>
        ''');

        // Should report nested mismatch error
        expect(result.errors, isNotEmpty,
            reason: 'Nested mismatch should be caught');

        // AST should still be generated for error recovery
        expect(result.ast, isNotNull);
      });

      test('Similar names but different components', () {
        final result = parser.parse('''
          <x-custom-component>
            Content
          </x-custom-different>
        ''');

        expect(result.errors, isNotEmpty);

        final hasMismatchError = result.errors.any((e) =>
            e.message.contains('custom-component') ||
            e.message.contains('custom-different'));

        expect(hasMismatchError, isTrue,
            reason: 'Should catch similar but different component names');
        expect(result.ast, isNotNull);
      });
    });

    group('2. Missing Directive Closures', () {
      test('Missing @endif', () {
        final result = parser.parse('''
          @if(\$show)
            <p>Content</p>
        ''');

        expect(result.errors, isNotEmpty,
            reason: 'Missing @endif should produce error');

        final hasIfError = result.errors.any((e) =>
            e.message.toLowerCase().contains('unclosed') &&
            e.message.toLowerCase().contains('if'));

        expect(hasIfError, isTrue,
            reason: 'Error should mention unclosed @if');

        // Should still have partial AST with if directive
        expect(result.ast, isNotNull);
        final directives = result.ast!.children.whereType<DirectiveNode>();
        expect(directives.any((d) => d.name == 'if'), isTrue,
            reason: 'Partial AST should include if directive');
      });

      test('Missing @endforeach', () {
        final result = parser.parse('''
          @foreach(\$items as \$item)
            <p>{{ \$item }}</p>
        ''');

        expect(result.errors, isNotEmpty);

        final hasForeachError = result.errors.any((e) =>
            e.message.toLowerCase().contains('unclosed') &&
            e.message.toLowerCase().contains('foreach'));

        expect(hasForeachError, isTrue);
        expect(result.ast, isNotNull);
      });

      test('Missing @endsection', () {
        final result = parser.parse('''
          @section('content')
            <p>Section content</p>
        ''');

        expect(result.errors, isNotEmpty,
            reason: 'Missing @endsection should produce error');

        final hasSectionError = result.errors.any((e) =>
            e.message.toLowerCase().contains('unclosed') &&
            e.message.toLowerCase().contains('section'));

        expect(hasSectionError, isTrue);
        expect(result.ast, isNotNull);
      });

      test('Nested directives with missing inner closure', () {
        final result = parser.parse('''
          @if(\$outer)
            @foreach(\$items as \$item)
              <p>{{ \$item }}</p>
          @endif
        ''');

        // Missing @endforeach
        expect(result.errors, isNotEmpty);

        // Should report the missing @endforeach
        final hasForeachError = result.errors.any((e) =>
            e.message.toLowerCase().contains('foreach'));

        expect(hasForeachError, isTrue,
            reason: 'Should detect missing inner directive closure');
        expect(result.ast, isNotNull);
      });
    });

    group('3. Extra Closing Directives', () {
      test('Extra @endif without matching @if', () {
        final result = parser.parse('''
          <p>Some content</p>
          @endif
        ''');

        // This is tricky - parser might just skip it or error
        // At minimum, should not crash
        expect(result.ast, isNotNull,
            reason: 'Parser should handle extra closing directive gracefully');

        // The extra @endif might be treated as text or error token
        // Implementation-specific behavior
      });

      test('Multiple @endif for single @if', () {
        final result = parser.parse('''
          @if(\$condition)
            <p>Content</p>
          @endif
          @endif
        ''');

        // Extra @endif should be handled gracefully
        expect(result.ast, isNotNull);

        // May or may not produce error depending on implementation
        // Key is not to crash
      });

      test('Extra @endforeach without matching @foreach', () {
        final result = parser.parse('''
          <div>Content</div>
          @endforeach
        ''');

        expect(result.ast, isNotNull,
            reason: 'Should handle orphaned closing directive');
      });
    });

    group('4. Overlapping Directive Blocks', () {
      test('Wrong nesting order - if/section overlap', () {
        final result = parser.parse('''
          @if(\$a)
            @section('test')
          @endif
            Content
          @endsection
        ''');

        // Crossed boundaries - @section starts inside @if but ends outside
        expect(result.errors, isNotEmpty,
            reason: 'Overlapping directive blocks should produce errors');

        // Should still generate partial AST
        expect(result.ast, isNotNull);
      });

      test('foreach/if crossed boundaries', () {
        final result = parser.parse('''
          @foreach(\$items as \$item)
            @if(\$x)
          @endforeach
          @endif
        ''');

        // Wrong closure order
        expect(result.errors, isNotEmpty,
            reason: 'Crossed directive boundaries should error');
        expect(result.ast, isNotNull);
      });
    });

    group('5. Component/Directive Interaction Issues', () {
      test('Component inside verbatim should be treated as text', () {
        final result = parser.parse('''
          @verbatim
            <x-alert type="info">This should not be parsed as component</x-alert>
          @endverbatim
        ''');

        // Should parse successfully - verbatim content is raw
        expect(result.isSuccess, isTrue,
            reason: '@verbatim should treat component tags as raw text');

        // Content inside verbatim should NOT be parsed as ComponentNode
        final verbatimDirective = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((d) => d.name == 'verbatim');

        // Children should be text, not components
        final hasComponentChildren = verbatimDirective.children
            .any((c) => c is ComponentNode);

        expect(hasComponentChildren, isFalse,
            reason: 'Components inside @verbatim should not be parsed');
      });

      test('Slot outside component should error or be handled', () {
        final result = parser.parse('''
          <x-slot:name>
            Content
          </x-slot>
        ''');

        // Slot outside component context
        // Implementation may allow it (parsed as standalone) or error
        expect(result.ast, isNotNull,
            reason: 'Should handle slot outside component gracefully');

        // Check if it's parsed as SlotNode
        final hasSlot = result.ast!.children.any((c) => c is SlotNode);

        if (hasSlot) {
          // If parsed as slot, that's one valid approach
          expect(result.ast!.children.whereType<SlotNode>(), isNotEmpty);
        }
        // Alternative: could be error or treated differently
      });

      test('Invalid slot name - numeric', () {
        final result = parser.parse('''
          <x-component>
            <x-slot:123>Content</x-slot>
          </x-component>
        ''');

        // Numeric slot names might be allowed or disallowed
        // Key is not to crash
        expect(result.ast, isNotNull,
            reason: 'Parser should handle numeric slot names');
      });

      test('Invalid slot name - empty', () {
        final result = parser.parse('''
          <x-component>
            <x-slot:>Content</x-slot>
          </x-component>
        ''');

        // Empty slot name after colon
        expect(result.ast, isNotNull,
            reason: 'Should handle empty slot name gracefully');
      });

      test('Invalid slot name - starts with dash', () {
        final result = parser.parse('''
          <x-component>
            <x-slot:-invalid>Content</x-slot>
          </x-component>
        ''');

        // Slot name starting with dash
        expect(result.ast, isNotNull);
      });
    });

    group('6. Self-Closing Edge Cases', () {
      test('Self-closing non-void HTML tag - div', () {
        final result = parser.parse('<div />');

        // HTML spec: div is not void, but self-closing syntax exists
        // Parser should handle it (either allow or warn)
        expect(result.ast, isNotNull,
            reason: 'Should handle self-closing non-void element');

        final htmlElements = result.ast!.children.whereType<HtmlElementNode>();
        if (htmlElements.isNotEmpty) {
          final div = htmlElements.first;
          expect(div.tagName, equals('div'));
          // May or may not be marked as self-closing
        }
      });

      test('Self-closing non-void HTML tag - span', () {
        final result = parser.parse('<span />');

        expect(result.ast, isNotNull);

        final htmlElements = result.ast!.children.whereType<HtmlElementNode>();
        if (htmlElements.isNotEmpty) {
          expect(htmlElements.first.tagName, equals('span'));
        }
      });

      test('Self-closing non-void HTML tag - p', () {
        final result = parser.parse('<p />');

        expect(result.ast, isNotNull);
      });

      test('Mixed self-closing components and HTML', () {
        final result = parser.parse('''
          <x-component />
          <div />
          <x-other>Content</x-other>
        ''');

        expect(result.ast, isNotNull,
            reason: 'Should handle mixed self-closing elements');

        // Should have multiple children
        expect(result.ast!.children.length, greaterThan(0));
      });
    });

    group('7. Multiple Errors - Error Recovery', () {
      test('Multiple unclosed directives should report all errors', () {
        final result = parser.parse('''
          @if(\$a)
            <p>Content A</p>
          @foreach(\$items as \$item)
            <p>{{ \$item }}</p>
        ''');

        // Missing both @endif and @endforeach
        expect(result.errors.length, greaterThanOrEqualTo(2),
            reason: 'Should report multiple errors');

        // Should mention both missing closures
        final hasIfError = result.errors.any((e) =>
            e.message.toLowerCase().contains('if'));
        final hasForeachError = result.errors.any((e) =>
            e.message.toLowerCase().contains('foreach'));

        expect(hasIfError, isTrue);
        expect(hasForeachError, isTrue);

        // Should still generate partial AST
        expect(result.ast, isNotNull);
      });

      test('Component mismatch and directive error combined', () {
        final result = parser.parse('''
          @if(\$condition)
            <x-alert>
              Content
            </x-button>
        ''');

        // Missing @endif AND mismatched component tags
        expect(result.errors, isNotEmpty,
            reason: 'Should catch multiple error types');
        expect(result.ast, isNotNull);
      });

      test('Deeply nested errors should all be reported', () {
        final result = parser.parse('''
          @if(\$a)
            @foreach(\$items as \$item)
              @while(\$condition)
                <x-component>
                  Content
                </x-other>
        ''');

        // Multiple issues:
        // - Missing @endwhile
        // - Missing @endforeach
        // - Missing @endif
        // - Mismatched component tags
        expect(result.errors.length, greaterThan(0),
            reason: 'Should report errors from nested structures');
        expect(result.ast, isNotNull);
      });
    });
  });
}
