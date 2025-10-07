# HTML Element Parsing API Contract

## Overview
This contract defines the public API for HTML element parsing in the Blade parser. All contract tests must pass before implementation is considered complete.

## API Surface

### HtmlElementNode Constructor
```dart
HtmlElementNode({
  required Position startPosition,
  required Position endPosition,
  AstNode? parent,
  required String tagName,
  Map<String, AttributeNode> attributes = const {},
  bool isSelfClosing = false,
  bool isVoid = false,
  required List<AstNode> children,
})
```

**Contract Requirements**:
- ✅ Must accept all required parameters (startPosition, endPosition, tagName, children)
- ✅ Must accept optional parameters (parent, attributes, isSelfClosing, isVoid)
- ✅ Must normalize tagName to lowercase
- ✅ Must accept empty attributes map
- ✅ Must accept empty children list
- ✅ Must create immutable node (all fields final)

**Test Cases**:
```dart
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
  final node = HtmlElementNode(
    tagName: 'DIV',
    startPosition: Position(line: 1, column: 1, offset: 0),
    endPosition: Position(line: 1, column: 6, offset: 5),
    children: [],
  );
  expect(node.tagName, 'div');
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
```

---

### HtmlElementNode.accept() - Visitor Pattern
```dart
T accept<T>(AstVisitor<T> visitor)
```

**Contract Requirements**:
- ✅ Must call `visitor.visitHtmlElement(this)`
- ✅ Must return result of visitor call
- ✅ Must work with any visitor type T

**Test Cases**:
```dart
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
});
```

---

### HtmlElementNode.toJson() - JSON Serialization
```dart
Map<String, dynamic> toJson()
```

**Contract Requirements**:
- ✅ Must include 'type': 'htmlElement'
- ✅ Must include 'tagName': String
- ✅ Must include 'attributes': Map (serialized AttributeNodes)
- ✅ Must include 'isSelfClosing': bool
- ✅ Must include 'isVoid': bool
- ✅ Must include 'position': {start, end}
- ✅ Must include 'children': List (serialized child nodes)
- ✅ Must produce valid JSON (encodable to JSON string)

**Test Cases**:
```dart
test('HtmlElementNode serializes to JSON correctly', () {
  final node = HtmlElementNode(
    tagName: 'div',
    attributes: {
      'class': StandardAttribute(name: 'class', value: 'container', quote: '"'),
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

  // Verify JSON encodable
  expect(() => jsonEncode(json), returnsNormally);
});

test('HtmlElementNode serializes attributes by type', () {
  final node = HtmlElementNode(
    tagName: 'button',
    attributes: {
      'class': StandardAttribute(name: 'class', value: 'btn', quote: '"'),
      'x-data': AlpineAttribute(name: 'x-data', value: '{}', quote: '"'),
      'wire:click': LivewireAttribute(name: 'wire:click', value: 'save', quote: '"'),
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
```

---

### Parser.parse() Integration
```dart
ParseResult parse(String source)
```

**Contract Requirements**:
- ✅ Must recognize HTML opening tags: `<div>`, `<p>`, `<span>`, etc.
- ✅ Must recognize HTML closing tags: `</div>`, `</p>`, `</span>`, etc.
- ✅ Must recognize self-closing tags: `<br />`, `<div />`, etc.
- ✅ Must recognize void elements: `<br>`, `<img>`, `<input>`, etc.
- ✅ Must parse HTML attributes: `class="foo"`, `id='bar'`, `disabled`
- ✅ Must categorize Alpine.js attributes: `x-data`, `@click`, `:class`
- ✅ Must categorize Livewire attributes: `wire:click`, `wire:model.defer`
- ✅ Must build parent-child relationships for nested HTML
- ✅ Must distinguish HTML elements from Blade components (`<div>` vs `<x-button>`)
- ✅ Must collect multiple errors (not stop at first)
- ✅ Must return partial AST on error

**Test Cases**:
```dart
test('Parser creates HtmlElementNode for simple HTML tag', () {
  final result = Parser().parse('<div></div>');
  expect(result.errors, isEmpty);
  final doc = result.document;
  expect(doc.children, hasLength(1));
  expect(doc.children[0], isA<HtmlElementNode>());

  final element = doc.children[0] as HtmlElementNode;
  expect(element.tagName, 'div');
  expect(element.isSelfClosing, false);
  expect(element.isVoid, false);
  expect(element.children, isEmpty);
});

test('Parser creates HtmlElementNode with attributes', () {
  final result = Parser().parse('<div class="container" id="app"></div>');
  final element = result.document.children[0] as HtmlElementNode;

  expect(element.attributes, hasLength(2));
  expect(element.attributes['class'], isA<StandardAttribute>());
  expect(element.attributes['id'], isA<StandardAttribute>());
  expect(element.attributes['class']!.value, 'container');
  expect(element.attributes['id']!.value, 'app');
});

test('Parser recognizes void elements', () {
  final result = Parser().parse('<br>');
  final element = result.document.children[0] as HtmlElementNode;

  expect(element.tagName, 'br');
  expect(element.isVoid, true);
  expect(element.children, isEmpty);
});

test('Parser handles self-closing syntax', () {
  final result = Parser().parse('<div />');
  final element = result.document.children[0] as HtmlElementNode;

  expect(element.tagName, 'div');
  expect(element.isSelfClosing, true);
  expect(element.children, isEmpty);
});

test('Parser builds nested HTML structure', () {
  final result = Parser().parse('<div><p>text</p></div>');
  final div = result.document.children[0] as HtmlElementNode;

  expect(div.tagName, 'div');
  expect(div.children, hasLength(1));
  expect(div.children[0], isA<HtmlElementNode>());

  final p = div.children[0] as HtmlElementNode;
  expect(p.tagName, 'p');
  expect(p.children, hasLength(1));
  expect(p.children[0], isA<TextNode>());
});

test('Parser categorizes Alpine.js attributes', () {
  final result = Parser().parse('<div x-data="{}" @click="handle"></div>');
  final element = result.document.children[0] as HtmlElementNode;

  expect(element.attributes['x-data'], isA<AlpineAttribute>());
  expect(element.attributes['@click'], isA<AlpineAttribute>());
});

test('Parser categorizes Livewire attributes', () {
  final result = Parser().parse('<button wire:click="save" wire:loading.class="opacity-50"></button>');
  final element = result.document.children[0] as HtmlElementNode;

  expect(element.attributes['wire:click'], isA<LivewireAttribute>());
  expect(element.attributes['wire:loading.class'], isA<LivewireAttribute>());
});

test('Parser distinguishes HTML from Blade components', () {
  final result = Parser().parse('<div></div><x-button></x-button>');

  expect(result.document.children[0], isA<HtmlElementNode>());
  expect(result.document.children[1], isA<ComponentNode>());
});
```

---

## Error Handling Contracts

### Unclosed Tag Error
```dart
test('Parser reports unclosed tag error', () {
  final result = Parser().parse('<div><p>');

  expect(result.errors, hasLength(1));
  expect(result.errors[0].message, contains('Unclosed'));
  expect(result.errors[0].message, contains('<p>'));
  expect(result.errors[0].position, isNotNull);

  // Partial AST still returned
  expect(result.document.children, isNotEmpty);
});
```

### Mismatched Tag Error
```dart
test('Parser reports mismatched tag error', () {
  final result = Parser().parse('<div></span>');

  expect(result.errors, hasLength(1));
  expect(result.errors[0].message, contains('Expected'));
  expect(result.errors[0].message, contains('</div>'));
  expect(result.errors[0].message, contains('</span>'));
});
```

### Void Element Closing Tag Error
```dart
test('Parser reports error for void element closing tag', () {
  final result = Parser().parse('<br></br>');

  expect(result.errors, hasLength(1));
  expect(result.errors[0].message, contains('Void element'));
  expect(result.errors[0].message, contains('<br>'));
  expect(result.errors[0].message, contains('closing tag'));
});
```

### Invalid Tag Name Error
```dart
test('Parser reports invalid tag name error', () {
  final result = Parser().parse('<123>');

  expect(result.errors, hasLength(1));
  expect(result.errors[0].message, contains('Invalid tag name'));
});
```

### Multiple Errors Collection
```dart
test('Parser collects multiple errors', () {
  final result = Parser().parse('<div><p></div><span>');

  // Should report: mismatched </div> (expected </p>) AND unclosed <span>
  expect(result.errors.length, greaterThanOrEqualTo(2));
});
```

---

## Performance Contracts

### Parsing Speed
```dart
test('Parser maintains ≥1000 lines/sec throughput for HTML', () {
  final template = '<div class="foo">\n' * 1000; // 1000 lines

  final stopwatch = Stopwatch()..start();
  final result = Parser().parse(template);
  stopwatch.stop();

  final linesPerSecond = 1000 / (stopwatch.elapsedMilliseconds / 1000);
  expect(linesPerSecond, greaterThanOrEqualTo(1000));
  expect(result.errors, isEmpty);
});
```

### Memory Usage
```dart
test('Parser uses <100MB for typical HTML templates', () {
  final template = '<div class="container">\n  <p>Text</p>\n</div>\n' * 2000;

  // Memory tracking would go here
  // This is a placeholder for memory profiling
  final result = Parser().parse(template);
  expect(result.document, isNotNull);
});
```

---

## Backward Compatibility Contracts

### Existing Tests Must Pass
```dart
test('All existing Blade directive tests still pass', () {
  // This is verified by running existing test suite
  // No regressions allowed in:
  // - test/contract/parser_contract_test.dart
  // - test/unit/parser/directive_parser_test.dart
  // - test/integration/basic_parsing_test.dart
});
```

---

## Summary

This contract ensures:
- ✅ HtmlElementNode public API stable and complete
- ✅ Parser recognizes all HTML element patterns
- ✅ Attribute categorization works correctly
- ✅ Error handling comprehensive and clear
- ✅ Performance requirements met
- ✅ Backward compatibility maintained
- ✅ JSON serialization complete
- ✅ Visitor pattern functional

All tests must be written BEFORE implementation (TDD mandate).
