import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for component closing tag validation
/// These tests EXPOSE bugs - mismatched component tags not validated
void main() {
  group('Component Closing Tag Validation Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Mismatched component names should produce error', () {
      final result = parser.parse('''
        <x-alert type="error">
          Content here
        </x-button>
      ''');

      // Current bug: No error, silently accepts mismatch
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Mismatched component tags should produce error',
      );

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('alert') ||
            e.message.toLowerCase().contains('button') ||
            e.message.toLowerCase().contains('expected') ||
            e.message.toLowerCase().contains('mismatch'),
      );

      expect(
        hasMismatchError,
        isTrue,
        reason: 'Error should mention the mismatched component names',
      );

      // Error message should be helpful
      final errorMessage = result.errors.first.message;
      expect(
        errorMessage,
        contains('alert'),
        reason: 'Error should mention expected component name',
      );
    });

    test('Correctly matched component tags should not error', () {
      final result = parser.parse('''
        <x-card>
          Card content
        </x-card>
      ''');

      // This is the baseline - should work
      expect(result.isSuccess, isTrue);
      expect(
        result.errors,
        isEmpty,
        reason: 'Correctly matched tags should produce no errors',
      );

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'card');

      expect(component, isNotNull);
    });

    test('Nested components with inner mismatch', () {
      final result = parser.parse('''
        <x-layout>
          <x-card>
            Card content
          </x-alert>
        </x-layout>
      ''');

      // Should error on the inner mismatch (card vs alert)
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Inner component mismatch should be caught',
      );

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('card') ||
            e.message.toLowerCase().contains('alert'),
      );

      expect(hasMismatchError, isTrue);
    });

    test('Nested components with outer mismatch', () {
      final result = parser.parse('''
        <x-layout>
          <x-card>
            Card content
          </x-card>
        </x-sidebar>
      ''');

      // Should error on outer mismatch (layout vs sidebar)
      expect(result.errors, isNotEmpty);

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('layout') ||
            e.message.toLowerCase().contains('sidebar'),
      );

      expect(hasMismatchError, isTrue);
    });

    test('Component name case sensitivity', () {
      // Test how case differences are handled
      final result = parser.parse('''
        <x-Alert>
          Content
        </x-alert>
      ''');

      // Expected behavior: Either normalize and match (no error),
      // OR enforce case sensitivity (produce error)
      // Current bug: Likely no validation at all

      // This test documents the behavior
      // Ideally, should normalize to lowercase and match (like HTML)
      if (result.errors.isEmpty) {
        // If no error, names should have been normalized
        final component = result.ast!.children
            .whereType<ComponentNode>()
            .firstWhere(
              (c) => c.name == 'alert',
              orElse: () => throw Exception('Component not found'),
            );

        expect(
          component.name,
          equals('alert'),
          reason: 'Component names should be normalized to lowercase',
        );
      } else {
        // If error, should mention case mismatch
        expect(
          result.errors.first.message,
          contains('Alert'),
          reason: 'Error should mention case issue',
        );
      }
    });

    test('Multiple components with various mismatches', () {
      final result = parser.parse('''
        <x-layout>
          <x-header></x-header>
          <x-main></x-sidebar>
          <x-footer></x-footer>
        </x-layout>
      ''');

      // Should catch the main/sidebar mismatch
      // Other components match correctly
      expect(result.errors, isNotEmpty);

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('main') ||
            e.message.toLowerCase().contains('sidebar'),
      );

      expect(hasMismatchError, isTrue);
    });

    test('Component vs HTML element mismatch', () {
      final result = parser.parse('''
        <x-card>
          Content
        </div>
      ''');

      // Closing with HTML tag instead of component
      // Should produce error
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Cannot close component with HTML tag',
      );
    });

    test('Self-closing component (no closing tag)', () {
      final result = parser.parse('<x-icon name="star" />');

      // Self-closing components are valid, no error
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'icon');

      expect(component, isNotNull);
      expect(component.attributes.containsKey('name'), isTrue);
    });

    test('Unclosed component should error', () {
      final result = parser.parse('''
        <x-card>
          Content here
      ''');

      // Missing closing tag
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Unclosed component should produce error',
      );

      final hasUnclosedError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('unclosed') ||
            e.message.toLowerCase().contains('missing') ||
            e.message.toLowerCase().contains('card'),
      );

      expect(hasUnclosedError, isTrue);
    });

    test('Wrong closing tag order (nested)', () {
      final result = parser.parse('''
        <x-outer>
          <x-inner>
        </x-outer>
        </x-inner>
      ''');

      // Wrong nesting order should error
      expect(
        result.errors,
        isNotEmpty,
        reason: 'Wrong closing order should be caught',
      );
    });

    test('Error position should point to closing tag', () {
      final result = parser.parse('''
        <x-alert>
          Content on line 2
        </x-button>
      ''');

      expect(result.errors, isNotEmpty);

      final error = result.errors.first;

      // Error should point to the closing tag location (line 3)
      expect(
        error.position.line,
        equals(3),
        reason: 'Error should point to the mismatched closing tag',
      );
    });

    test('Component with hyphenated name mismatch', () {
      final result = parser.parse('''
        <x-alert-box>
          Content
        </x-alert-card>
      ''');

      expect(result.errors, isNotEmpty);

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.contains('alert-box') || e.message.contains('alert-card'),
      );

      expect(
        hasMismatchError,
        isTrue,
        reason: 'Should catch mismatch in hyphenated names',
      );
    });

    test('Multiple levels of nesting with mismatch at deepest level', () {
      final result = parser.parse('''
        <x-layout>
          <x-section>
            <x-container>
              <x-card>
                Content
              </x-alert>
            </x-container>
          </x-section>
        </x-layout>
      ''');

      // Deepest mismatch: card vs alert
      expect(result.errors, isNotEmpty);

      final hasMismatchError = result.errors.any(
        (e) =>
            e.message.toLowerCase().contains('card') ||
            e.message.toLowerCase().contains('alert'),
      );

      expect(hasMismatchError, isTrue);
    });
  });
}
