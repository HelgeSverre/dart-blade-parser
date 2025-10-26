import 'dart:io';
import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Legacy Laravel Template Compatibility Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Laravel 4 Master Layout with @section...@show', () {
      final file =
          File('test/fixtures/legacy/laravel4-master-layout.blade.php');
      final template = file.readAsStringSync();

      final result = parser.parse(template);

      expect(result.errors, isEmpty, reason: 'Should parse without errors');

      // Find all section directives
      final sections = _findAllDirectives(result.ast!, 'section');

      // Should have 3 sections: title, styles, javascripts
      expect(sections.length, equals(3));

      // Verify each section is closed by @show
      for (final section in sections) {
        expect(
          section.closedBy,
          equals('show'),
          reason:
              'Laravel 4 sections should use @show to define default content',
        );
      }

      // Verify specific sections exist
      final titleSection =
          sections.where((s) => s.expression?.contains('title') == true);
      expect(titleSection, isNotEmpty);

      // Verify @yield('content') exists
      final yields = _findAllDirectives(result.ast!, 'yield');
      expect(yields.length, equals(1));
      expect(yields.first.expression, contains('content'));

      // Verify HTML structure parsed correctly
      final htmlElements = _findAllHtmlElements(result.ast!);
      expect(htmlElements, isNotEmpty);
    });

    test('Laravel 5.0 Auth Login Template', () {
      final file = File('test/fixtures/legacy/laravel5-auth-login.blade.php');
      final template = file.readAsStringSync();

      final result = parser.parse(template);

      expect(result.errors, isEmpty, reason: 'Should parse without errors');

      // Verify @extends directive
      final extends_ = _findAllDirectives(result.ast!, 'extends');
      expect(extends_.length, equals(1));
      expect(extends_.first.expression, contains('app'));

      // Verify @section with @endsection (Laravel 5 standard)
      final sections = _findAllDirectives(result.ast!, 'section');
      expect(sections.length, equals(1));
      expect(sections.first.expression, contains('content'));
      expect(
        sections.first.closedBy,
        equals('endsection'),
        reason: 'Laravel 5 auth templates use @endsection',
      );

      // Verify control structures
      final ifs = _findAllDirectives(result.ast!, 'if');
      expect(ifs, isNotEmpty);

      final foreachs = _findAllDirectives(result.ast!, 'foreach');
      expect(foreachs, isNotEmpty);

      // Verify form elements
      final htmlElements = _findAllHtmlElements(result.ast!);
      final forms = htmlElements.where((e) => e.tagName == 'form');
      expect(forms.length, equals(1));

      final inputs = htmlElements.where((e) => e.tagName == 'input').toList();
      expect(inputs.length, greaterThan(2),
          reason: 'Should have multiple input fields');
    });

    test('Laravel 5.0 Auth Register Template', () {
      final file =
          File('test/fixtures/legacy/laravel5-auth-register.blade.php');
      final template = file.readAsStringSync();

      final result = parser.parse(template);

      expect(result.errors, isEmpty, reason: 'Should parse without errors');

      // Verify template inheritance
      final extends_ = _findAllDirectives(result.ast!, 'extends');
      expect(extends_.length, equals(1));

      // Verify section structure
      final sections = _findAllDirectives(result.ast!, 'section');
      expect(sections.first.closedBy, equals('endsection'));

      // Verify it has more inputs than login (name, email, password, password_confirmation)
      final htmlElements = _findAllHtmlElements(result.ast!);
      final inputs = htmlElements.where((e) => e.tagName == 'input');
      expect(inputs.length, greaterThan(3));
    });

    test('Section with @overwrite (deprecated Laravel 4.x/5.x)', () {
      final file =
          File('test/fixtures/legacy/section-with-overwrite.blade.php');
      final template = file.readAsStringSync();

      final result = parser.parse(template);

      expect(result.errors, isEmpty,
          reason: 'Should parse legacy @overwrite without errors');

      // Find all sections
      final sections = _findAllDirectives(result.ast!, 'section');
      expect(sections.length, equals(4)); // title, sidebar, footer, content

      // Find the section closed with @overwrite
      final overwriteSection = sections.firstWhere(
        (s) => s.closedBy == 'overwrite',
        orElse: () => throw Exception('No section with @overwrite found'),
      );
      expect(overwriteSection.expression, contains('footer'));

      // Find the section closed with @show
      final showSection = sections.firstWhere(
        (s) => s.closedBy == 'show',
        orElse: () => throw Exception('No section with @show found'),
      );
      expect(showSection.expression, contains('sidebar'));

      // Find sections closed with @endsection
      final endsectionSections =
          sections.where((s) => s.closedBy == 'endsection');
      expect(endsectionSections.length, equals(2)); // title and content

      // Verify all three closing tag types are represented
      final closingTags = sections.map((s) => s.closedBy).toSet();
      expect(closingTags, containsAll(['endsection', 'show', 'overwrite']));
    });

    test('All closing tag variants produce correct closedBy field', () {
      // Test @endsection
      final endsectionResult = parser.parse(
        "@section('test')content@endsection",
      );
      final endsectionNode =
          _findAllDirectives(endsectionResult.ast!, 'section').first;
      expect(endsectionNode.closedBy, equals('endsection'));

      // Test @show
      final showResult = parser.parse(
        "@section('test')content@show",
      );
      final showNode = _findAllDirectives(showResult.ast!, 'section').first;
      expect(showNode.closedBy, equals('show'));

      // Test @overwrite
      final overwriteResult = parser.parse(
        "@section('test')content@overwrite",
      );
      final overwriteNode =
          _findAllDirectives(overwriteResult.ast!, 'section').first;
      expect(overwriteNode.closedBy, equals('overwrite'));
    });

    test('Mixed closing tags in single template', () {
      const template = '''
        @section('a')Content A@endsection
        @section('b')Content B@show
        @section('c')Content C@overwrite
      ''';

      final result = parser.parse(template);
      expect(result.errors, isEmpty);

      final sections = _findAllDirectives(result.ast!, 'section');
      expect(sections.length, equals(3));

      final closingTags = sections.map((s) => s.closedBy).toList();
      expect(closingTags, containsAll(['endsection', 'show', 'overwrite']));
    });

    test('Inline section does not have closedBy field', () {
      final result = parser.parse("@section('title', 'My Title')");

      expect(result.errors, isEmpty);

      final section = _findAllDirectives(result.ast!, 'section').first;

      // Inline sections (with 2 args) should not have closedBy
      expect(section.closedBy, isNull);
      expect(section.expression, contains('title'));
    });

    test('Non-section directives do not have closedBy field', () {
      // Test @if/@endif
      final ifResult = parser.parse("@if(\$test)Content@endif");
      final ifNode = _findAllDirectives(ifResult.ast!, 'if').first;
      expect(ifNode.closedBy, isNull, reason: '@if should not have closedBy');

      // Test @foreach/@endforeach
      final foreachResult =
          parser.parse("@foreach(\$items as \$item)Item@endforeach");
      final foreachNode =
          _findAllDirectives(foreachResult.ast!, 'foreach').first;
      expect(foreachNode.closedBy, isNull,
          reason: '@foreach should not have closedBy');

      // Test @unless/@endunless
      final unlessResult = parser.parse("@unless(\$hide)Show@endunless");
      final unlessNode = _findAllDirectives(unlessResult.ast!, 'unless').first;
      expect(unlessNode.closedBy, isNull,
          reason: '@unless should not have closedBy');
    });

    test('Unclosed section error message mentions all closing options', () {
      final result = parser.parse("@section('test')Content");

      expect(result.errors, isNotEmpty,
          reason: 'Should have error for unclosed section');

      final error = result.errors.first;
      expect(error.message, contains('Unclosed @section directive'));
      expect(
        error.hint,
        contains('@endsection, @show, or @overwrite'),
        reason: 'Error hint should mention all closing tag options',
      );
    });
  });
}

/// Helper to recursively find all directives with a given name
List<DirectiveNode> _findAllDirectives(AstNode node, String name) {
  final results = <DirectiveNode>[];

  void visit(AstNode n) {
    if (n is DirectiveNode && n.name == name) {
      results.add(n);
    }
    for (final child in n.children) {
      visit(child);
    }
  }

  visit(node);
  return results;
}

/// Helper to recursively find all HTML elements
List<HtmlElementNode> _findAllHtmlElements(AstNode node) {
  final results = <HtmlElementNode>[];

  void visit(AstNode n) {
    if (n is HtmlElementNode) {
      results.add(n);
    }
    for (final child in n.children) {
      visit(child);
    }
  }

  visit(node);
  return results;
}
