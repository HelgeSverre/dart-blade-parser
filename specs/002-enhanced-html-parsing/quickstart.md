# Quickstart: Enhanced HTML Element Parsing

**Feature**: 002-enhanced-html-parsing  
**Date**: 2025-10-05

This guide demonstrates the enhanced HTML parsing capabilities step-by-step.

---

## Integration Test Scenario 1: Parse Standard HTML with Attributes

**Goal**: Verify HTML elements are parsed into HtmlElementNode with attributes

**Test Code**:
```dart
import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  test('Parse standard HTML with attributes', () {
    final parser = BladeParser();
    final source = '<div class="container" id="main">Content here</div>';
    
    final result = parser.parse(source);
    
    // Verify success
    expect(result.isSuccess, isTrue);
    expect(result.errors, isEmpty);
    
    // Verify HTML element
    final node = result.ast!.children[0] as HtmlElementNode;
    expect(node.tagName, equals('div'));
    expect(node.attributes['class']!.value, equals('container'));
    expect(node.attributes['id']!.value, equals('main'));
    expect(node.children, hasLength(1));
    expect(node.children[0], isA<TextNode>());
  });
}
```

**Expected Outcome**: ✅ Test passes, HTML parsed correctly

---

## Integration Test Scenario 2: Parse Nested HTML Elements

**Goal**: Verify proper parent-child relationships in nested HTML

**Test Code**:
```dart
test('Parse nested HTML elements', () {
  final parser = BladeParser();
  final source = '''
<div class="outer">
  <ul>
    <li>Item 1</li>
    <li>Item 2</li>
  </ul>
</div>
''';
  
  final result = parser.parse(source);
  
  expect(result.isSuccess, isTrue);
  
  // Verify nesting
  final div = result.ast!.children[0] as HtmlElementNode;
  expect(div.tagName, equals('div'));
  
  final ul = div.children.whereType<HtmlElementNode>().first;
  expect(ul.tagName, equals('ul'));
  
  final items = ul.children.whereType<HtmlElementNode>().toList();
  expect(items, hasLength(2));
  expect(items[0].tagName, equals('li'));
  expect(items[1].tagName, equals('li'));
});
```

**Expected Outcome**: ✅ Nested structure correctly represented

---

## Integration Test Scenario 3: Parse Void Elements

**Goal**: Verify void elements recognized with no children

**Test Code**:
```dart
test('Parse void elements', () {
  final parser = BladeParser();
  final source = '''
<div>
  <br>
  <img src="photo.jpg" alt="Photo">
  <input type="text" name="email">
  <hr>
</div>
''';
  
  final result = parser.parse(source);
  
  expect(result.isSuccess, isTrue);
  
  final div = result.ast!.children[0] as HtmlElementNode;
  final voidElements = div.children.whereType<HtmlElementNode>()
      .where((e) => e.isVoid).toList();
  
  expect(voidElements, hasLength(4));
  expect(voidElements[0].tagName, equals('br'));
  expect(voidElements[1].tagName, equals('img'));
  expect(voidElements[2].tagName, equals('input'));
  expect(voidElements[3].tagName, equals('hr'));
  
  // Verify no children
  for (final elem in voidElements) {
    expect(elem.children, isEmpty);
  }
});
```

**Expected Outcome**: ✅ All void elements correctly identified

---

## Integration Test Scenario 4: Parse HTML with Blade Directives Inside

**Goal**: Verify mixed Blade directives and HTML elements

**Test Code**:
```dart
test('Parse HTML with Blade directives inside', () {
  final parser = BladeParser();
  final source = '''
<div class="container">
  @if(\$user->isAdmin())
    <p>Admin panel</p>
  @endif
</div>
''';
  
  final result = parser.parse(source);
  
  expect(result.isSuccess, isTrue);
  
  // Verify structure
  final div = result.ast!.children[0] as HtmlElementNode;
  expect(div.tagName, equals('div'));
  
  final ifDirective = div.children.whereType<DirectiveNode>().first;
  expect(ifDirective.name, equals('if'));
  
  final p = ifDirective.children.whereType<HtmlElementNode>().first;
  expect(p.tagName, equals('p'));
});
```

**Expected Outcome**: ✅ Blade and HTML correctly interleaved

---

## Integration Test Scenario 5: Parse Self-Closing HTML

**Goal**: Verify self-closing syntax supported

**Test Code**:
```dart
test('Parse self-closing HTML', () {
  final parser = BladeParser();
  final source = '''
<div class="wrapper">
  <div class="empty" />
  <span id="self-close" />
</div>
''';
  
  final result = parser.parse(source);
  
  expect(result.isSuccess, isTrue);
  
  final wrapper = result.ast!.children[0] as HtmlElementNode;
  final selfClosing = wrapper.children.whereType<HtmlElementNode>()
      .where((e) => e.isSelfClosing).toList();
  
  expect(selfClosing, hasLength(2));
  expect(selfClosing[0].tagName, equals('div'));
  expect(selfClosing[1].tagName, equals('span'));
  
  // Verify no children
  for (final elem in selfClosing) {
    expect(elem.children, isEmpty);
  }
});
```

**Expected Outcome**: ✅ Self-closing elements properly handled

---

## Integration Test Scenario 6: Error - Unclosed HTML Tag

**Goal**: Verify error recovery for unclosed tags

**Test Code**:
```dart
test('Error: unclosed HTML tag', () {
  final parser = BladeParser();
  final source = '''
<div class="container">
  <p>Content without closing
  <!-- Missing </p> and </div> -->
''';
  
  final result = parser.parse(source);
  
  expect(result.isSuccess, isFalse);
  expect(result.errors, isNotEmpty);
  
  // Verify error message
  final error = result.errors.first;
  expect(error.message.toLowerCase(), contains('unclosed'));
  expect(error.position.line, greaterThan(0));
  
  // Verify partial AST exists
  expect(result.ast, isNotNull);
  expect(result.ast!.children, isNotEmpty);
});
```

**Expected Outcome**: ✅ Error reported with partial AST

---

## Integration Test Scenario 7: Performance - HTML Parsing Throughput

**Goal**: Verify HTML parsing meets performance targets

**Test Code**:
```dart
test('Performance: HTML parsing throughput', () {
  final parser = BladeParser();
  
  // Generate 1000-line HTML template
  final lines = <String>[];
  for (var i = 0; i < 1000; i++) {
    lines.add('<div class="item-$i">');
    lines.add('  <span>Content $i</span>');
    lines.add('</div>');
  }
  final source = lines.join('\n');
  
  // Measure parse time
  final stopwatch = Stopwatch()..start();
  final result = parser.parse(source);
  stopwatch.stop();
  
  expect(result.isSuccess, isTrue);
  
  // Verify throughput ≥1000 lines/sec
  final linesPerSecond = (1000 * 1000) / stopwatch.elapsedMilliseconds;
  expect(linesPerSecond, greaterThanOrEqualTo(1000));
  
  print('HTML parsing: $linesPerSecond lines/sec');
});
```

**Expected Outcome**: ✅ Performance target met (≥1000 lines/sec)

---

## Quick Reference

### Parse HTML
```dart
final parser = BladeParser();
final result = parser.parse('<div>content</div>');
final html = result.ast!.children[0] as HtmlElementNode;
```

### Access Attributes
```dart
final className = html.attributes['class']!.value;
final alpineData = html.attributes['x-data']!.value;
```

### Check Element Type
```dart
if (html.isVoid) {
  // br, img, input, etc.
}
if (html.isSelfClosing) {
  // <div />
}
```

### Traverse Children
```dart
for (final child in html.children) {
  if (child is HtmlElementNode) {
    print('HTML: ${child.tagName}');
  } else if (child is DirectiveNode) {
    print('Directive: @${child.name}');
  }
}
```

---

**Status**: ✅ Ready for Test Implementation
**Total Scenarios**: 7 integration tests covering all major use cases
