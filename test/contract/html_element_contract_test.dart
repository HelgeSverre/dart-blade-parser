import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

// Test visitor implementation
class TestVisitor extends AstVisitor<String> {
  bool visitedHtmlElement = false;

  @override
  String visitHtmlElement(HtmlElementNode node) {
    visitedHtmlElement = true;
    return 'visited';
  }

  @override
  String visitDocument(DocumentNode node) => 'document';

  @override
  String visitText(TextNode node) => 'text';

  @override
  String visitDirective(DirectiveNode node) => 'directive';

  @override
  String visitEcho(EchoNode node) => 'echo';

  @override
  String visitComponent(ComponentNode node) => 'component';

  @override
  String visitComment(CommentNode node) => 'comment';

  @override
  String visitError(ErrorNode node) => 'error';

  @override
  String visitSlot(SlotNode node) => 'slot';
}

void main() {
  group('HtmlElementNode Constructor Contract Tests', () {
    test('HtmlElementNode can be constructed with minimal parameters', () {
      final node = HtmlElementNode(
        tagName: 'div',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 6, offset: 5),
        children: [],
      );

      expect(node.tagName, 'div');
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.isSelfClosing, false);
      expect(node.isVoid, false);
    });

    test('HtmlElementNode normalizes tag name to lowercase', () {
      final node1 = HtmlElementNode(
        tagName: 'DIV',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 6, offset: 5),
        children: [],
      );
      expect(node1.tagName, 'div');

      final node2 = HtmlElementNode(
        tagName: 'Div',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 6, offset: 5),
        children: [],
      );
      expect(node2.tagName, 'div');

      final node3 = HtmlElementNode(
        tagName: 'SPAN',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 7, offset: 6),
        children: [],
      );
      expect(node3.tagName, 'span');
    });

    test('HtmlElementNode accepts void element flags', () {
      final node = HtmlElementNode(
        tagName: 'br',
        isVoid: true,
        isSelfClosing: true,
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 7, offset: 6),
        children: [],
      );

      expect(node.isVoid, true);
      expect(node.isSelfClosing, true);
    });

    test('HtmlElementNode accepts attributes map', () {
      final node = HtmlElementNode(
        tagName: 'div',
        attributes: {
          'class': StandardAttribute(name: 'class', value: 'container'),
          'id': StandardAttribute(name: 'id', value: 'app'),
        },
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 20, offset: 19),
        children: [],
      );

      expect(node.attributes, hasLength(2));
      expect(node.attributes['class'], isA<StandardAttribute>());
      expect(node.attributes['id'], isA<StandardAttribute>());
    });

    test('HtmlElementNode accepts children list', () {
      final childText = TextNode(
        startPosition: Position(line: 1, column: 6, offset: 5),
        endPosition: Position(line: 1, column: 11, offset: 10),
        content: 'Hello',
      );

      final node = HtmlElementNode(
        tagName: 'div',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 17, offset: 16),
        children: [childText],
      );

      expect(node.children, hasLength(1));
      expect(node.children[0], isA<TextNode>());
    });
  });

  group('HtmlElementNode Visitor Pattern Contract Tests', () {
    test('HtmlElementNode supports visitor pattern', () {
      final node = HtmlElementNode(
        tagName: 'div',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 6, offset: 5),
        children: [],
      );

      final visitor = TestVisitor();
      final result = node.accept(visitor);

      expect(visitor.visitedHtmlElement, true);
      expect(result, isA<String>());
      expect(result, equals('visited'));
    });

    test('HtmlElementNode accept method calls visitor.visitHtmlElement', () {
      final node = HtmlElementNode(
        tagName: 'p',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 4, offset: 3),
        children: [],
      );

      final visitor = TestVisitor();
      expect(visitor.visitedHtmlElement, false);

      node.accept(visitor);

      expect(visitor.visitedHtmlElement, true);
    });
  });

  group('HtmlElementNode JSON Serialization Contract Tests', () {
    test('HtmlElementNode serializes to JSON correctly', () {
      final node = HtmlElementNode(
        tagName: 'div',
        attributes: {
          'class': StandardAttribute(name: 'class', value: 'container'),
        },
        isSelfClosing: false,
        isVoid: false,
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 20, offset: 19),
        children: [],
      );

      final json = node.toJson();

      expect(json['type'], 'htmlElement');
      expect(json['tagName'], 'div');
      expect(json['isSelfClosing'], false);
      expect(json['isVoid'], false);
      expect(json['attributes'], isA<Map>());
      expect(json['attributes']['class'], isA<Map>());
      expect(json['position'], isA<Map>());
      expect(json['position']['start'], isA<Map>());
      expect(json['position']['end'], isA<Map>());
      expect(json['children'], isA<List>());
    });

    test('HtmlElementNode JSON is encodable', () {
      final node = HtmlElementNode(
        tagName: 'span',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 7, offset: 6),
        children: [],
      );

      final json = node.toJson();

      // Should not throw
      expect(() => jsonEncode(json), returnsNormally);

      final encoded = jsonEncode(json);
      expect(encoded, isA<String>());
      expect(encoded, isNotEmpty);
    });

    test('HtmlElementNode serializes attributes by type', () {
      final node = HtmlElementNode(
        tagName: 'button',
        attributes: {
          'class': StandardAttribute(name: 'class', value: 'btn'),
          'x-data': AlpineAttribute(
            name: 'x-data',
            directive: 'data',
            value: '{}',
          ),
          'wire:click': LivewireAttribute(
            name: 'wire:click',
            action: 'click',
            value: 'save',
          ),
        },
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 50, offset: 49),
        children: [],
      );

      final json = node.toJson();

      expect(json['attributes']['class']['type'], 'standard');
      expect(json['attributes']['x-data']['type'], 'alpine');
      expect(json['attributes']['wire:click']['type'], 'livewire');
    });

    test('HtmlElementNode JSON includes all required fields', () {
      final child = TextNode(
        startPosition: Position(line: 1, column: 6, offset: 5),
        endPosition: Position(line: 1, column: 11, offset: 10),
        content: 'Hello',
      );

      final node = HtmlElementNode(
        tagName: 'div',
        attributes: {'id': StandardAttribute(name: 'id', value: 'test')},
        isSelfClosing: false,
        isVoid: false,
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 17, offset: 16),
        children: [child],
      );

      final json = node.toJson();

      // Verify all required fields present
      expect(json.containsKey('type'), true);
      expect(json.containsKey('tagName'), true);
      expect(json.containsKey('attributes'), true);
      expect(json.containsKey('isSelfClosing'), true);
      expect(json.containsKey('isVoid'), true);
      expect(json.containsKey('position'), true);
      expect(json.containsKey('children'), true);

      // Verify position structure
      expect(json['position'].containsKey('start'), true);
      expect(json['position'].containsKey('end'), true);
      expect(json['position']['start'].containsKey('line'), true);
      expect(json['position']['start'].containsKey('column'), true);
      expect(json['position']['start'].containsKey('offset'), true);
    });

    test('HtmlElementNode JSON children are serialized', () {
      final children = [
        TextNode(
          startPosition: Position(line: 1, column: 6, offset: 5),
          endPosition: Position(line: 1, column: 11, offset: 10),
          content: 'Text',
        ),
        HtmlElementNode(
          tagName: 'span',
          startPosition: Position(line: 1, column: 11, offset: 10),
          endPosition: Position(line: 1, column: 18, offset: 17),
          children: [],
        ),
      ];

      final node = HtmlElementNode(
        tagName: 'div',
        startPosition: Position(line: 1, column: 1, offset: 0),
        endPosition: Position(line: 1, column: 24, offset: 23),
        children: children,
      );

      final json = node.toJson();

      expect(json['children'], hasLength(2));
      expect(json['children'][0]['type'], 'text');
      expect(json['children'][1]['type'], 'htmlElement');
    });
  });
}
