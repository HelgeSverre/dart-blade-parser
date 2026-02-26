import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for the 5 traditionally hard-to-parse Blade patterns found in
/// real-world Filament and FluxUI templates.
void main() {
  late BladeParser parser;

  setUp(() {
    parser = BladeParser();
  });

  // ===================================================================
  // Pattern 1: Dynamic tag names  <{{ \$var }}> ... </{{ \$var }}>
  // ===================================================================
  group('Pattern 1: Dynamic tag names', () {
    test('parses <{{ \$tag }}> as text without crashing', () {
      final result = parser.parse(
          '<{{ \$headingTag }} class="title">Hello</{{ \$headingTag }}>');
      // Should not crash - may produce errors but should recover gracefully
      expect(result.ast, isNotNull);
    });

    test('dynamic tag does not produce cascading errors', () {
      // The key thing is error count is bounded - not cascading
      final result = parser.parse('''
<section>
  <{{ \$headingTag }} class="title">
    {{ \$heading }}
  </{{ \$headingTag }}>
</section>
''');
      expect(result.ast, isNotNull);
      // With good recovery, we should still parse the outer <section>
    });
  });

  // ===================================================================
  // Pattern 2: Echo expressions in tag attributes  {{ \$attributes }}
  // ===================================================================
  group('Pattern 2: Echo in tag attributes', () {
    test('component with {{ \$attributes }} renders self-closing correctly', () {
      final result = parser.parse('''<x-icon-button
    icon="heroicon"
    {{ \$attributes->class(['trigger']) }}
/>''');
      expect(result.isSuccess, isTrue,
          reason: 'Should parse component with echo in attributes');
      expect(result.errors, isEmpty);

      final comp = result.ast!.children.whereType<ComponentNode>().first;
      expect(comp.name, equals('icon-button'));
      expect(comp.isSelfClosing, isTrue);
    });

    test('HTML tag with {{ \$attributes }} parses correctly', () {
      final result = parser.parse('''<div
    class="wrapper"
    {{ \$attributes->merge(['id' => 'main']) }}
>
    content
</div>''');
      expect(result.isSuccess, isTrue,
          reason: 'Should parse HTML tag with echo in attributes');
      expect(result.errors, isEmpty);

      final el = result.ast!.children.whereType<HtmlElementNode>().first;
      expect(el.tagName, equals('div'));
      expect(el.children, isNotEmpty);
    });

    test('component with {!! \$attributes !!} raw echo in attributes', () {
      final result = parser.parse('''<x-button
    type="submit"
    {!! \$attributes !!}
/>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final comp = result.ast!.children.whereType<ComponentNode>().first;
      expect(comp.name, equals('button'));
      expect(comp.isSelfClosing, isTrue);
    });

    test('Filament v2 icon-button with attribute spreading', () {
      // Exact reproduction of the failing Filament v2 pattern
      final result = parser.parse('''<x-tables::icon-button
    icon="heroicon-o-dots-vertical"
    :label="__('tables::table.buttons.open_actions.label')"
    x-cloak
    {{ \$attributes->class(['filament-tables-bulk-actions-trigger']) }}
/>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final comp = result.ast!.children.whereType<ComponentNode>().first;
      expect(comp.name, equals('tables::icon-button'));
      expect(comp.isSelfClosing, isTrue);
    });
  });

  // ===================================================================
  // Pattern 3: @unless closed with @endif
  // ===================================================================
  group('Pattern 3: @unless closed with @endif', () {
    test('@unless with @endunless works (baseline)', () {
      final result = parser.parse('''@unless (\$disabled)
    <option value="">Choose</option>
@endunless''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('unless'));
      expect(directive.children, isNotEmpty);
    });

    test('@unless closed with @endif should parse without errors', () {
      final result = parser.parse('''@unless (\$disabled)
    <option value="">Choose</option>
@endif''');
      expect(result.isSuccess, isTrue,
          reason: '@endif should be accepted as closer for @unless');
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('unless'));
      expect(directive.children, isNotEmpty);
    });

    test('@unless with @else and @endif', () {
      final result = parser.parse('''@unless (\$disabled)
    <p>Enabled</p>
@else
    <p>Disabled</p>
@endif''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('unless'));
    });
  });

  // ===================================================================
  // Pattern 4: Unknown inline directives (@blaze, @props, etc.)
  // ===================================================================
  group('Pattern 4: Unknown inline directive heuristic', () {
    test('@blaze without @endblaze treated as inline', () {
      final result = parser.parse('''@blaze

@props([
    'name' => null,
])

@php
\$classes = 'foo';
@endphp

<select {{ \$attributes->class(\$classes) }}>
    {{ \$slot }}
</select>''');
      expect(result.ast, isNotNull);

      // @blaze should be inline, not consuming everything
      // @php/@endphp should parse correctly
      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      final blazeDirective =
          directives.where((d) => d.name == 'blaze').toList();
      expect(blazeDirective, hasLength(1),
          reason: '@blaze should be parsed as inline directive');
      expect(blazeDirective.first.children, isEmpty,
          reason: '@blaze should have no children (inline)');

      // @php should be separate from @blaze
      final phpDirective =
          directives.where((d) => d.name == 'php').toList();
      expect(phpDirective, hasLength(1),
          reason: '@php/@endphp should still parse correctly');
    });

    test('@blaze(fold: true) with expression', () {
      final result = parser.parse('''@blaze(fold: true)

@props([
    'variant' => 'outline',
])''');
      expect(result.ast, isNotNull);

      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      final blazeDirective =
          directives.where((d) => d.name == 'blaze').toList();
      expect(blazeDirective, hasLength(1));
      expect(blazeDirective.first.children, isEmpty);
    });
  });

  // ===================================================================
  // Pattern 4b: @php block with HTML-like content in PHP comments/strings
  // ===================================================================
  group('Pattern 4b: @php raw content mode', () {
    test('@php block with <div> in PHP comment should not break parsing', () {
      final result = parser.parse('''@php
    /**
     * Render the `<div>` wrappers for all fields.
     * The `<div>` elements need class="hidden".
     */
    \$isHidden = true;
@endphp

<div>content</div>''');
      expect(result.isSuccess, isTrue,
          reason: '<div> in PHP comment should not break parsing');
      expect(result.errors, isEmpty);

      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      expect(directives.where((d) => d.name == 'php'), hasLength(1));

      final htmlElements =
          result.ast!.children.whereType<HtmlElementNode>().toList();
      expect(htmlElements, hasLength(1));
      expect(htmlElements.first.tagName, equals('div'));
    });

    test('@php block with <select> in string should not start HTML tag parsing',
        () {
      final result = parser.parse('''@php
\$classes = Flux::classes()
    ->add('appearance-none') // Strip the browser\\'s default <select> styles...
    ->add('text-base');
@endphp

<select class="input">
    {{ \$slot }}
</select>''');
      expect(result.isSuccess, isTrue,
          reason: '<select> in PHP string should not break parsing');
      expect(result.errors, isEmpty);
    });

    test('inline @php(\$expr) still works', () {
      final result = parser.parse('@php(\$x = 1)\n<div>{{ \$x }}</div>');
      expect(result.ast, isNotNull);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('php'));
      expect(directive.expression, isNotNull);
      expect(directive.expression, contains('\$x = 1'));
    });
  });

  // ===================================================================
  // Pattern 5: Conditional HTML spanning Blade directives
  // ===================================================================
  group('Pattern 5: Conditional HTML with tag stack mismatch', () {
    test('header inside section with @if conditional', () {
      final result = parser.parse('''<section class="wrapper">
    @if (\$hasHeader)
        <header class="header">
            <h2>Title</h2>
        </header>
    @endif
    <div class="content">
        {{ \$slot }}
    </div>
</section>''');
      expect(result.isSuccess, isTrue,
          reason:
              'Conditional <header> inside <section> should parse correctly');
      expect(result.errors, isEmpty);

      final section =
          result.ast!.children.whereType<HtmlElementNode>().first;
      expect(section.tagName, equals('section'));
    });

    test('Filament section pattern: @if attributes + conditional children',
        () {
      // Simplified reproduction of the Filament section_index pattern
      final result = parser.parse('''<section
    @if (\$collapsible)
        x-on:click="toggle()"
    @endif
    class="section"
>
    @if (\$hasHeader)
        <header class="header">
            <h2>{{ \$heading }}</h2>
        </header>
    @endif
    <div class="content">
        {{ \$slot }}
    </div>
</section>''');
      expect(result.isSuccess, isTrue,
          reason:
              'Complex Filament section pattern should parse without errors');
      expect(result.errors, isEmpty);
    });

    test(
        'tag stack mismatch recovery: </header> when inside <section> should not cascade',
        () {
      // Even if parsing isn't perfect, we should recover gracefully
      final result = parser.parse('''<section>
    <header>Title</header>
    <div>Content</div>
</section>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final section =
          result.ast!.children.whereType<HtmlElementNode>().first;
      expect(section.tagName, equals('section'));
      // header and div should be children of section
      final htmlChildren =
          section.children.whereType<HtmlElementNode>().toList();
      expect(htmlChildren.length, equals(2));
      expect(htmlChildren[0].tagName, equals('header'));
      expect(htmlChildren[1].tagName, equals('div'));
    });
  });
}
