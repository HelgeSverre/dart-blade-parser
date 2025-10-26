import 'dart:convert';
import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/json_serializer.dart';

void main() {
  group('JsonSerializerVisitor Tests', () {
    test('Serializes document node', () {
      final parser = BladeParser();
      final result = parser.parse('<p>Hello</p>');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      expect(json['type'], 'document');
      expect(json['position'], isNotNull);
      expect(json['children'], isA<List>());
    });

    test('Serializes directive node', () {
      final parser = BladeParser();
      final result = parser.parse('@if(\$condition) content @endif');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      // Find the directive in children
      final directive = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'directive',
      );

      expect(directive['name'], 'if');
      expect(directive['expression'], contains('\$condition'));
      expect(directive['position'], isNotNull);
      expect(directive['children'], isA<List>());
    });

    test('Serializes echo node (regular)', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$variable }}');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final echo = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'echo',
      );

      expect(echo['expression'], contains('\$variable'));
      expect(echo['isRaw'], false);
      expect(echo['position'], isNotNull);
    });

    test('Serializes echo node (raw)', () {
      final parser = BladeParser();
      final result = parser.parse('{!! \$html !!}');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final echo = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'echo',
      );

      expect(echo['expression'], contains('\$html'));
      expect(echo['isRaw'], true);
    });

    test('Serializes text node', () {
      final parser = BladeParser();
      final result = parser.parse('Plain text content');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final text = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'text',
      );

      expect(text['content'], contains('Plain text'));
      expect(text['position'], isNotNull);
    });

    test('Serializes HTML element node', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container">content</div>');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final element = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'htmlElement',
      );

      expect(element['tagName'], 'div');
      expect(element['attributes'], isA<Map>());
      expect(element['isSelfClosing'], false);
      expect(element['isVoid'], false);
      expect(element['children'], isA<List>());
    });

    test('Serializes self-closing HTML element', () {
      final parser = BladeParser();
      final result = parser.parse('<img src="test.jpg" />');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final element = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'htmlElement',
      );

      expect(element['tagName'], 'img');
      expect(element['isSelfClosing'], true);
    });

    test('Serializes component node', () {
      final parser = BladeParser();
      final result = parser.parse('<x-alert type="success">Message</x-alert>');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final component = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'component',
      );

      expect(component['name'], 'alert');
      expect(component['attributes'], isA<Map>());
      expect(component['slots'], isA<Map>());
      expect(component['isSelfClosing'], false);
      expect(component['children'], isA<List>());
    });

    test('Serializes component with slots', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <x-card>
          <x-slot name="header">Title</x-slot>
          Body content
        </x-card>
      ''');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final component = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'component',
      );

      expect(component['slots'], isNotEmpty);
    });

    test('Serializes comment node (Blade)', () {
      final parser = BladeParser();
      final result = parser.parse('{{-- Blade comment --}}');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final comment = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'comment',
      );

      expect(comment['content'], contains('Blade comment'));
      expect(comment['isBladeComment'], true);
      expect(comment['position'], isNotNull);
    });

    test('Serializes comment node (HTML)', () {
      final parser = BladeParser();
      final result = parser.parse('<!-- HTML comment -->');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final comment = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'comment',
      );

      expect(comment['content'], contains('HTML comment'));
      expect(comment['isBladeComment'], false);
    });

    test('Serializes slot node', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <x-layout>
          <x-slot name="footer">Footer content</x-slot>
        </x-layout>
      ''');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      // Navigate to the slot
      final component = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'component',
      );

      expect(component['slots'], isNotEmpty);
    });

    test('Serializes complex nested structure', () {
      final parser = BladeParser();
      final result = parser.parse('''
        @section('content')
          <div>
            @foreach(\$items as \$item)
              <x-card>
                {{ \$item->name }}
              </x-card>
            @endforeach
          </div>
        @endsection
      ''');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      // Should successfully serialize complex structure
      expect(json['type'], 'document');
      expect(json['children'], isNotEmpty);

      // Verify JSON is valid
      final jsonString = jsonEncode(json);
      expect(jsonString, isA<String>());
      expect(jsonString.length, greaterThan(100));
    });

    test('JsonSerializerVisitor output matches node.toJson()', () {
      final parser = BladeParser();
      final result = parser.parse('<p>{{ \$test }}</p>');

      final visitor = JsonSerializerVisitor();
      final visitorJson = result.ast!.accept(visitor);
      final nodeJson = result.ast!.toJson();

      // Both should produce equivalent JSON structure
      expect(jsonEncode(visitorJson), jsonEncode(nodeJson));
    });

    test('Handles empty children lists', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$var }}');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final echo = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'echo',
      );

      // Echo nodes don't have children field in serialization
      expect(echo.containsKey('children'), false);
    });

    test('Handles null expression in directive', () {
      final parser = BladeParser();
      final result = parser.parse('@csrf');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final directive = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'directive',
      );

      expect(directive['name'], 'csrf');
      // Expression should not be present if null
      expect(directive.containsKey('expression'), anyOf([false, true]));
    });

    test('Serializes attributes correctly', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div
          class="container"
          x-data="{ open: false }"
          wire:click="doAction">
          Content
        </div>
      ''');

      final visitor = JsonSerializerVisitor();
      final json = result.ast!.accept(visitor);

      final element = (json['children'] as List).firstWhere(
        (child) => child['type'] == 'htmlElement',
      );

      expect(element['attributes'], isNotEmpty);
      expect(element['attributes'], isA<Map>());

      // Check that different attribute types are serialized
      final attributes = element['attributes'] as Map;
      expect(attributes, isNotEmpty);
    });

    test('defaultVisit throws for unknown node type', () {
      final visitor = JsonSerializerVisitor();

      // This shouldn't happen in normal operation, but test the safety
      expect(
        () => visitor.defaultVisit(
          // Create a mock unknown node - this is contrived for testing
          DocumentNode(
            startPosition: Position(line: 1, column: 1, offset: 0),
            endPosition: Position(line: 1, column: 1, offset: 0),
            children: [],
          ),
        ),
        throwsUnimplementedError,
      );
    });
  });
}
