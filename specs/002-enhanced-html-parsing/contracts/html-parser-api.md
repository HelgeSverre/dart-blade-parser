# HTML Parser API Contract

**Feature**: 002-enhanced-html-parsing  
**Date**: 2025-10-05  
**Version**: 1.0.0

---

## Contract: Parse Standard HTML Element

**Given**: A Blade template with HTML element
```dart
final source = '<div class="container">content</div>';
```

**When**: Parser processes the template
```dart
final parser = BladeParser();
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**Then**: HTML element correctly parsed
```dart
assert(node.tagName == 'div');
assert(node.attributes['class']!.value == 'container');
assert(node.children.length == 1);
assert(node.children[0] is TextNode);
assert((node.children[0] as TextNode).content == 'content');
assert(!node.isSelfClosing);
assert(!node.isVoid);
assert(result.errors.isEmpty);
```

---

## Contract: Parse Void Element

**Given**: HTML with void element
```dart
final source = '<br>';
```

**When**: Parser processes void element
```dart
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**Then**: Void element recognized
```dart
assert(node.tagName == 'br');
assert(node.isVoid == true);
assert(node.children.isEmpty);
assert(node.attributes.isEmpty);
assert(result.errors.isEmpty);
```

---

## Contract: Parse Self-Closing Element

**Given**: Self-closing HTML syntax
```dart
final source = '<div class="foo" />';
```

**When**: Parser processes self-closing tag
```dart
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**Then**: Self-closing flag set
```dart
assert(node.tagName == 'div');
assert(node.isSelfClosing == true);
assert(node.children.isEmpty);
assert(node.attributes['class']!.value == 'foo');
assert(result.errors.isEmpty);
```

---

## Contract: Parse Mixed Attributes

**Given**: HTML with Alpine.js and Livewire attributes
```dart
final source = '''
<div 
  class="card" 
  x-data="{ open: false }"
  wire:loading
  @click="toggle">
</div>
''';
```

**When**: Parser processes mixed attributes
```dart
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**Then**: All attribute types recognized
```dart
assert(node.attributes['class'] is StandardAttribute);
assert(node.attributes['x-data'] is AlpineAttribute);
assert(node.attributes['wire:loading'] is LivewireAttribute);
assert(node.attributes['@click'] is AlpineAttribute);
assert(node.attributes.length == 4);
assert(result.errors.isEmpty);
```

---

## Contract: Parse Nested HTML Elements

**Given**: Nested HTML structure
```dart
final source = '''
<div class="outer">
  <p id="para">
    <span>Text</span>
  </p>
</div>
''';
```

**When**: Parser processes nested elements
```dart
final result = parser.parse(source);
final div = result.ast!.children[0] as HtmlElementNode;
final p = div.children[1] as HtmlElementNode;
final span = p.children[1] as HtmlElementNode;
```

**Then**: Proper nesting maintained
```dart
assert(div.tagName == 'div');
assert(p.tagName == 'p');
assert(span.tagName == 'span');
assert(span.children[0] is TextNode);
assert((span.children[0] as TextNode).content == 'Text');
assert(result.errors.isEmpty);
```

---

## Contract: HTML vs Component Distinction

**Given**: Mix of HTML and Blade components
```dart
final source = '''
<div class="wrapper">
  <x-alert type="info">
    <p>HTML inside component</p>
  </x-alert>
</div>
''';
```

**When**: Parser processes mixed content
```dart
final result = parser.parse(source);
final div = result.ast!.children[0] as HtmlElementNode;
final alert = div.children[1] as ComponentNode;
final p = alert.children[1] as HtmlElementNode;
```

**Then**: Correct node types created
```dart
assert(div is HtmlElementNode);
assert(div.tagName == 'div');
assert(alert is ComponentNode);
assert(alert.name == 'alert');
assert(p is HtmlElementNode);
assert(p.tagName == 'p');
assert(result.errors.isEmpty);
```

---

## Contract: Error Recovery - Unclosed Tag

**Given**: HTML with unclosed tag
```dart
final source = '''
<div class="foo">
  <p>Content
<!-- Missing </p> and </div> -->
''';
```

**When**: Parser processes unclosed tags
```dart
final result = parser.parse(source);
```

**Then**: Errors reported with partial AST
```dart
assert(result.errors.length >= 1);
assert(result.errors.any((e) => e.message.contains('Unclosed')));
assert(result.ast != null); // Partial AST exists
assert(result.ast!.children.isNotEmpty);
```

---

## Contract: Error - Void Element with Closing Tag

**Given**: Void element with invalid closing tag
```dart
final source = '<br></br>';
```

**When**: Parser processes invalid void element
```dart
final result = parser.parse(source);
```

**Then**: Error reported
```dart
assert(result.errors.length >= 1);
assert(result.errors.any((e) => 
  e.message.contains('Void element') && 
  e.message.contains('closing tag')));
```

---

## Contract: Position Tracking

**Given**: HTML element at known position
```dart
final source = '''
<div class="test">
  content
</div>
''';
```

**When**: Parser processes element
```dart
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**Then**: Positions tracked correctly
```dart
assert(node.startPosition.line == 1);
assert(node.startPosition.column == 1);
assert(node.endPosition.line == 3);
assert(node.startPosition.offset >= 0);
assert(node.endPosition.offset > node.startPosition.offset);
```

---

## Contract: JSON Serialization

**Given**: HTML element
```dart
final source = '<div class="foo" x-data="{}"></div>';
final result = parser.parse(source);
final node = result.ast!.children[0] as HtmlElementNode;
```

**When**: Node serialized to JSON
```dart
final json = node.toJson();
```

**Then**: All fields present
```dart
assert(json['type'] == 'htmlElement');
assert(json['tagName'] == 'div');
assert(json['attributes'] != null);
assert(json['attributes']['class'] != null);
assert(json['attributes']['x-data'] != null);
assert(json['isSelfClosing'] == false);
assert(json['isVoid'] == false);
assert(json['position'] != null);
assert(json['children'] != null);
```

---

**Contract Status**: ✅ Ready for Test Implementation  
**Test Coverage**: 10 contracts × ~5 assertions = 50+ contract assertions
