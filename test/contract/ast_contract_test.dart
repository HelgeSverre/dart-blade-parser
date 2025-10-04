import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('AST Contract Tests', () {
    test('AstNode has accept method for visitor pattern', () {
      final node = TextNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 5, offset: 4),
        content: 'test',
      );

      expect(node.accept, isA<Function>());
    });

    test('AstNode has toJson method', () {
      final node = TextNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 5, offset: 4),
        content: 'test',
      );

      final json = node.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['type'], equals('text'));
      expect(json['content'], equals('test'));
    });

    test('toJson includes position information', () {
      final node = TextNode(
        startPosition: Position(line: 2, column: 3, offset: 10),
        endPosition: Position(line: 2, column: 8, offset: 15),
        content: 'hello',
      );

      final json = node.toJson();
      expect(json['position'], isNotNull);
      expect(json['position']['start'], isNotNull);
      expect(json['position']['end'], isNotNull);
      expect(json['position']['start']['line'], equals(2));
      expect(json['position']['start']['column'], equals(3));
    });

    test('JSON is serializable to string', () {
      final node = DocumentNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 10, offset: 9),
        children: [],
      );

      final json = node.toJson();
      final jsonString = jsonEncode(json);

      expect(jsonString, isA<String>());
      expect(jsonString.isNotEmpty, isTrue);
    });

    test('Different node types have correct type field', () {
      final textNode = TextNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 5, offset: 4),
        content: 'test',
      );

      final echoNode = EchoNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 10, offset: 9),
        expression: '\$test',
        isRaw: false,
      );

      expect(textNode.toJson()['type'], equals('text'));
      expect(echoNode.toJson()['type'], equals('echo'));
    });

    test('DocumentNode has children array in JSON', () {
      final doc = DocumentNode(
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 10, offset: 9),
        children: [
          TextNode(
            startPosition: Position(line: 1, column: 1, offset: 0),
            endPosition: Position(line: 1, column: 5, offset: 4),
            content: 'test',
          ),
        ],
      );

      final json = doc.toJson();
      expect(json['children'], isA<List>());
      expect(json['children'].length, equals(1));
    });
  });
}
