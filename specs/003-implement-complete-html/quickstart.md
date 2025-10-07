# Quickstart Guide: HTML Element Parsing

## Overview
This guide demonstrates the HTML element parsing feature through hands-on examples. Follow these steps to verify the feature works correctly.

## Prerequisites
- Dart SDK 3.0+
- Project cloned: `git clone <repo>`
- Tests passing: `dart test`

## Basic Usage

### 1. Parse a Simple HTML Element
```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final result = parser.parse('<div class="container">Hello</div>');

  // Verify no errors
  assert(result.errors.isEmpty);

  // Access the HTML element
  final div = result.document.children[0] as HtmlElementNode;
  print('Tag: ${div.tagName}');              // Output: Tag: div
  print('Class: ${div.attributes['class']?.value}');  // Output: Class: container
  print('Children: ${div.children.length}'); // Output: Children: 1
}
```

**Expected Result**:
- ✅ Parses without errors
- ✅ Creates HtmlElementNode with tagName 'div'
- ✅ Captures 'class' attribute with value 'container'
- ✅ Contains one TextNode child with content 'Hello'

---

### 2. Parse Void Elements
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<br>');

  final br = result.document.children[0] as HtmlElementNode;
  print('Tag: ${br.tagName}');       // Output: Tag: br
  print('Is void: ${br.isVoid}');    // Output: Is void: true
  print('Children: ${br.children}'); // Output: Children: []
}
```

**Expected Result**:
- ✅ Recognizes `<br>` as void element
- ✅ Sets isVoid = true
- ✅ Children list is empty

---

### 3. Parse Self-Closing Elements
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<div />');

  final div = result.document.children[0] as HtmlElementNode;
  print('Tag: ${div.tagName}');                 // Output: Tag: div
  print('Is self-closing: ${div.isSelfClosing}'); // Output: Is self-closing: true
  print('Children: ${div.children}');           // Output: Children: []
}
```

**Expected Result**:
- ✅ Recognizes `<div />` syntax
- ✅ Sets isSelfClosing = true
- ✅ Children list is empty

---

### 4. Parse Alpine.js Attributes
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<div x-data="{count: 0}" @click="count++"></div>');

  final div = result.document.children[0] as HtmlElementNode;
  final xData = div.attributes['x-data'] as AlpineAttribute;
  final onClick = div.attributes['@click'] as AlpineAttribute;

  print('Alpine x-data: ${xData.value}');  // Output: {count: 0}
  print('Alpine @click: ${onClick.value}'); // Output: count++
  print('Type: ${xData.runtimeType}');     // Output: AlpineAttribute
}
```

**Expected Result**:
- ✅ Recognizes x-data as AlpineAttribute
- ✅ Recognizes @click as AlpineAttribute
- ✅ Captures attribute values correctly

---

### 5. Parse Livewire Attributes
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<button wire:click="save" wire:loading.class="opacity-50">Save</button>');

  final button = result.document.children[0] as HtmlElementNode;
  final wireClick = button.attributes['wire:click'] as LivewireAttribute;
  final wireLoading = button.attributes['wire:loading.class'] as LivewireAttribute;

  print('Livewire click: ${wireClick.value}');     // Output: save
  print('Livewire loading: ${wireLoading.value}'); // Output: opacity-50
  print('Has modifier: ${wireLoading.name}');      // Output: wire:loading.class
}
```

**Expected Result**:
- ✅ Recognizes wire:click as LivewireAttribute
- ✅ Recognizes wire:loading.class as LivewireAttribute
- ✅ Preserves modifier in attribute name

---

### 6. Parse Nested HTML
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('''
    <div id="app">
      <header class="header">
        <h1>Title</h1>
      </header>
      <main>
        <p>Content</p>
      </main>
    </div>
  ''');

  final div = result.document.children[0] as HtmlElementNode;
  print('Root: ${div.tagName}');              // Output: Root: div
  print('Children: ${div.children.length}');  // Output: Children: 2

  final header = div.children[0] as HtmlElementNode;
  print('First child: ${header.tagName}');    // Output: First child: header

  final h1 = header.children[0] as HtmlElementNode;
  print('Nested: ${h1.tagName}');             // Output: Nested: h1
}
```

**Expected Result**:
- ✅ Builds correct parent-child hierarchy
- ✅ Maintains proper nesting depth
- ✅ All elements properly parsed

---

### 7. Mix Blade Directives with HTML
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('''
    <div>
      @if(\$show)
        <p>{{
\$message}}</p>
      @endif
    </div>
  ''');

  final div = result.document.children[0] as HtmlElementNode;
  print('Root: ${div.tagName}');              // Output: Root: div

  final ifDirective = div.children[0] as DirectiveNode;
  print('Directive: ${ifDirective.name}');    // Output: Directive: if

  final p = ifDirective.children[0] as HtmlElementNode;
  print('Inside @if: ${p.tagName}');          // Output: Inside @if: p

  final echo = p.children[0] as EchoNode;
  print('Echo type: ${echo.runtimeType}');    // Output: Echo type: EchoNode
}
```

**Expected Result**:
- ✅ HTML elements work inside Blade directives
- ✅ Blade directives work inside HTML elements
- ✅ Proper nesting maintained

---

### 8. Handle Boolean Attributes
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<input type="text" disabled required>');

  final input = result.document.children[0] as HtmlElementNode;
  final disabled = input.attributes['disabled'] as StandardAttribute;
  final required = input.attributes['required'] as StandardAttribute;

  print('Disabled value: ${disabled.value}'); // Output: Disabled value: null
  print('Required value: ${required.value}'); // Output: Required value: null
  print('Type: ${input.attributes['type']?.value}'); // Output: Type: text
}
```

**Expected Result**:
- ✅ Boolean attributes have null value
- ✅ Normal attributes have proper values
- ✅ All attributes captured

---

### 9. Export to JSON
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<div class="foo" x-data="{}"></div>');

  final div = result.document.children[0] as HtmlElementNode;
  final json = div.toJson();

  print(jsonEncode(json));
  // Output: {"type":"htmlElement","tagName":"div","attributes":{"class":{"type":"standard","name":"class","value":"foo","quote":"\""},"x-data":{"type":"alpine","name":"x-data","value":"{}","quote":"\""}},"isSelfClosing":false,"isVoid":false,"position":{...},"children":[]}
}
```

**Expected Result**:
- ✅ Produces valid JSON
- ✅ Includes all element properties
- ✅ Attribute types distinguishable

---

### 10. Visitor Pattern
```dart
class HtmlCounter extends AstVisitor<int> {
  int count = 0;

  @override
  int visitHtmlElement(HtmlElementNode node) {
    count++;
    for (final child in node.children) {
      child.accept(this);
    }
    return count;
  }

  // ... other visitor methods ...
}

void main() {
  final parser = BladeParser();
  final result = parser.parse('<div><p>text</p><span>more</span></div>');

  final counter = HtmlCounter();
  result.document.accept(counter);

  print('HTML elements: ${counter.count}'); // Output: HTML elements: 3
}
```

**Expected Result**:
- ✅ Visitor pattern works
- ✅ All HtmlElementNodes visited
- ✅ Count is correct

---

## Error Handling Examples

### 11. Unclosed Tag
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<div><p>');

  print('Errors: ${result.errors.length}');      // Output: Errors: 1
  print('Message: ${result.errors[0].message}'); // Output: Unclosed <p> at line 1, column 6

  // Partial AST still available
  final div = result.document.children[0] as HtmlElementNode;
  print('Parsed div: ${div.tagName}');           // Output: Parsed div: div
}
```

**Expected Result**:
- ✅ Error reported with position
- ✅ Partial AST returned
- ✅ Error message is clear

---

### 12. Mismatched Tags
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<div></span>');

  print('Errors: ${result.errors.length}');      // Output: Errors: 1
  print('Message: ${result.errors[0].message}'); // Output: Expected </div>, found </span> at line 1, column 6
}
```

**Expected Result**:
- ✅ Mismatch detected
- ✅ Error shows expected vs actual
- ✅ Position included

---

### 13. Void Element with Closing Tag
```dart
void main() {
  final parser = BladeParser();
  final result = parser.parse('<br></br>');

  print('Errors: ${result.errors.length}');      // Output: Errors: 1
  print('Message: ${result.errors[0].message}'); // Output: Void element <br> cannot have closing tag at line 1, column 5
}
```

**Expected Result**:
- ✅ Void element violation detected
- ✅ Clear error message
- ✅ Position accurate

---

## Verification Checklist

After running all examples above, verify:

- [ ] All 13 examples run without crashes
- [ ] HtmlElementNode created for HTML tags
- [ ] Void elements recognized (br, img, input, etc.)
- [ ] Self-closing syntax supported
- [ ] Alpine.js attributes categorized correctly
- [ ] Livewire attributes categorized correctly
- [ ] Nested HTML parsed correctly
- [ ] Mixed Blade/HTML works
- [ ] Boolean attributes handled
- [ ] JSON export works
- [ ] Visitor pattern functional
- [ ] Errors reported clearly
- [ ] Partial AST available on error

## Performance Verification

Run the performance benchmark:
```bash
dart test test/performance/html_parsing_benchmark_test.dart
```

**Expected**:
- ✅ Throughput ≥1000 lines/sec
- ✅ Memory <100MB for typical files
- ✅ No regression from baseline

## Integration Testing

Run the full test suite:
```bash
dart test
```

**Expected**:
- ✅ All contract tests pass
- ✅ All integration tests pass
- ✅ All unit tests pass
- ✅ All performance tests pass
- ✅ All existing Blade directive tests still pass (100+)

## Troubleshooting

### Issue: HtmlElementNode not created
**Cause**: Tag name starts with `x-` (Blade component)
**Solution**: Use different tag or verify it's not a Blade component

### Issue: Attribute not categorized correctly
**Cause**: Pattern matching wrong
**Solution**: Check attribute name prefix (x-, @, :, wire:)

### Issue: Void element has children
**Cause**: Parser bug or invalid HTML
**Solution**: Verify HTML is valid, check parser logic

### Issue: Performance below threshold
**Cause**: Inefficient parsing logic
**Solution**: Profile with `dart run` profiler, optimize hot paths

## Next Steps

After completing this quickstart:
1. Read the [API Contract](contracts/html_element_api.md) for detailed API specifications
2. Review the [Data Model](data-model.md) for entity relationships
3. Check the [Research](research.md) for implementation decisions
4. Run `/tasks` to see implementation task breakdown
5. Run `/implement` to execute the implementation

## Questions?

Refer to:
- Constitution: `.specify/memory/constitution.md`
- Feature Spec: `specs/003-implement-complete-html/spec.md`
- Implementation Plan: `specs/003-implement-complete-html/plan.md`
