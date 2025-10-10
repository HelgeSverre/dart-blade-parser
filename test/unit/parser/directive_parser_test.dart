import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Directive Parser Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parse @if directive with expression', () {
      final result =
          parser.parse('@if(\$user->isAdmin())\n  <p>Admin</p>\n@endif');

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final ifDirective = result.ast!.children.first as DirectiveNode;
      expect(ifDirective.name, equals('if'));
      expect(ifDirective.expression, contains('isAdmin'));
    });

    test('Parse @if with @else', () {
      final result = parser.parse('''
        @if(\$condition)
          <p>True</p>
        @else
          <p>False</p>
        @endif
      ''');

      expect(result.isSuccess, isTrue);
      final ifNode = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');
      expect(ifNode.name, equals('if'));
      expect(ifNode.children.length, greaterThan(0));
    });

    test('Parse @foreach directive', () {
      final result = parser
          .parse('@foreach(\$items as \$item)\n  {{ \$item }}\n@endforeach');

      expect(result.isSuccess, isTrue);

      final foreachNode = result.ast!.children.first as DirectiveNode;
      expect(foreachNode.name, equals('foreach'));
      expect(foreachNode.expression, contains('as'));
    });

    test('Parse @for directive', () {
      final result =
          parser.parse('@for(\$i = 0; \$i < 10; \$i++)\n  {{ \$i }}\n@endfor');

      expect(result.isSuccess, isTrue);

      final forNode = result.ast!.children.first as DirectiveNode;
      expect(forNode.name, equals('for'));
      expect(forNode.expression, contains('< 10'));
    });

    test('Parse @while directive', () {
      final result =
          parser.parse('@while(\$condition)\n  <p>Loop</p>\n@endwhile');

      expect(result.isSuccess, isTrue);

      final whileNode = result.ast!.children.first as DirectiveNode;
      expect(whileNode.name, equals('while'));
      expect(whileNode.expression, isNotNull);
    });

    test('Parse nested directives', () {
      final result = parser.parse('''
        @if(\$outer)
          @foreach(\$items as \$item)
            @if(\$item->active)
              {{ \$item->name }}
            @endif
          @endforeach
        @endif
      ''');

      expect(result.isSuccess, isTrue);

      // Find outer if (might not be first due to whitespace)
      final outerIf = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');
      expect(outerIf.name, equals('if'));

      // Find nested foreach
      final nestedForeach = outerIf.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'foreach');
      expect(nestedForeach, isNotNull);

      // Find innermost if
      final innerIf = nestedForeach.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'if');
      expect(innerIf, isNotNull);
    });

    test('Detect unclosed @if directive', () {
      final result = parser.parse('@if(\$condition)\n  <p>Content</p>');

      expect(result.isSuccess, isFalse);
      expect(result.errors.length, greaterThan(0));
      expect(result.errors.first.message, contains('Unclosed'));
      expect(result.errors.first.message, contains('@if'));
    });

    test('Detect unclosed @foreach directive', () {
      final result =
          parser.parse('@foreach(\$items as \$item)\n  {{ \$item }}');

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.message, contains('@foreach'));
    });

    test('Parse inline @continue with condition', () {
      final result = parser.parse('''
        @foreach(\$users as \$user)
          @continue(\$user->type == 1)
          <p>{{ \$user->name }}</p>
        @endforeach
      ''');

      expect(result.isSuccess, isTrue);
      // @continue should be recognized (implementation may vary)
    });

    test('Parse inline @break with condition', () {
      final result = parser.parse('''
        @foreach(\$items as \$item)
          @break(\$item->id == 5)
          <p>{{ \$item }}</p>
        @endforeach
      ''');

      expect(result.isSuccess, isTrue);
    });

    test('Parse @section directive', () {
      final result = parser.parse('''
        @section('content')
          <p>Section content</p>
        @endsection
      ''');

      expect(result.isSuccess, isTrue);
      // Section parsing depends on implementation
    });

    test('Parse @extends directive', () {
      final result = parser.parse("@extends('layouts.app')");

      expect(result.isSuccess, isTrue);
    });

    test('Parse @yield directive', () {
      final result = parser.parse("@yield('content')");

      expect(result.isSuccess, isTrue);
    });

    test('Parse @include directive', () {
      final result = parser.parse("@include('partials.header')");

      expect(result.isSuccess, isTrue);
    });

    test('Parse @component and @endcomponent', () {
      final result = parser.parse('''
        @component('alert')
          <p>Component content</p>
        @endcomponent
      ''');

      expect(result.isSuccess, isTrue);
    });

    test('Multiple errors reported', () {
      final result = parser.parse('''
        @if(\$a)
          <p>A</p>
        @foreach(\$items as \$item)
          {{ \$item }}
      ''');

      // Should report both unclosed @if and @foreach
      expect(result.errors.length, greaterThanOrEqualTo(2));
    });

    test('Parse @auth directive', () {
      final result = parser.parse('''
        @auth
          <p>Authenticated</p>
        @endauth
      ''');

      expect(result.isSuccess, isTrue);
    });

    test('Parse @guest directive', () {
      final result = parser.parse('''
        @guest
          <a href="/login">Login</a>
        @endguest
      ''');

      expect(result.isSuccess, isTrue);
    });

    test('Parse @env directive', () {
      final result = parser.parse('''
        @env('local')
          <p>Development mode</p>
        @endenv
      ''');

      expect(result.isSuccess, isTrue);
    });

    test('Parse @error directive', () {
      final result = parser.parse('''
        @error('email')
          <span>{{ \$message }}</span>
        @enderror
      ''');

      expect(result.isSuccess, isTrue);
    });
  });

  group('Block Directive Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('@unless block should have children, not be inline', () {
      final result = parser.parse('''
        @unless(\$condition)
          <p>Content shown when false</p>
        @endunless
      ''');

      expect(result.isSuccess, isTrue);

      // Find the unless directive
      final unlessDirective = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'unless',
              orElse: () => throw Exception('unless directive not found'));

      expect(unlessDirective.name, equals('unless'));
      expect(unlessDirective.expression, isNotNull);

      // CRITICAL: unless should be a BLOCK directive with children
      // Current bug: treated as inline, children.isEmpty
      expect(unlessDirective.children.length, greaterThan(0),
          reason:
              '@unless should be block directive with children, not inline');

      // Should have HTML child
      final htmlChildren =
          unlessDirective.children.whereType<HtmlElementNode>();
      expect(htmlChildren, isNotEmpty);
    });

    test('Missing @endunless should report error', () {
      final result = parser.parse('''
        @unless(\$x)
          <p>Text</p>
      ''');

      // Should have error about unclosed @unless
      expect(result.errors, isNotEmpty,
          reason: 'Missing @endunless should produce error');

      final hasUnlessError = result.errors
          .any((e) => e.message.toLowerCase().contains('unless'));
      expect(hasUnlessError, isTrue,
          reason: 'Error should mention unclosed @unless');
    });

    test('@php block should have children with raw content', () {
      final result = parser.parse('''
        @php
          \$x = 1;
          echo \$x;
        @endphp
      ''');

      expect(result.isSuccess, isTrue);

      // Find the php directive
      final phpDirective = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'php',
              orElse: () => throw Exception('php directive not found'));

      expect(phpDirective.name, equals('php'));

      // CRITICAL: @php should be BLOCK directive with children
      // Content should NOT be parsed as Blade/HTML
      // Current bug: treated as inline, or content parsed as Blade
      expect(phpDirective.children.length, greaterThan(0),
          reason: '@php should be block directive with raw content');

      // Content should be raw text, not parsed HTML/Blade
      final hasHtmlChildren = phpDirective.children.any((c) => c is HtmlElementNode);
      expect(hasHtmlChildren, isFalse,
          reason: '@php content should be raw, not parsed as HTML');
    });

    test('Missing @endphp should report error', () {
      final result = parser.parse('''
        @php
          \$x = 1;
      ''');

      expect(result.errors, isNotEmpty,
          reason: 'Missing @endphp should produce error');

      final hasPhpError =
          result.errors.any((e) => e.message.toLowerCase().contains('php'));
      expect(hasPhpError, isTrue,
          reason: 'Error should mention unclosed @php');
    });

    test('@switch/@case/@default/@endswitch structure', () {
      final result = parser.parse('''
        @switch(\$type)
          @case(1)
            <p>One</p>
            @break
          @case(2)
            <p>Two</p>
            @break
          @default
            <p>Other</p>
        @endswitch
      ''');

      // Currently unknown how this is parsed
      // Expected: Specialized multi-branch structure
      // Current: Likely fails or incorrectly structured

      expect(result.isSuccess, isTrue,
          reason: '@switch structure should parse successfully');

      final switchDirective = result.ast!.children
          .whereType<DirectiveNode>()
          .where((n) => n.name == 'switch')
          .firstOrNull;

      expect(switchDirective, isNotNull,
          reason: '@switch directive should be found');

      // Should have proper case/default branches
      // (Implementation-specific structure)
      expect(switchDirective!.children, isNotEmpty,
          reason: '@switch should contain case/default branches');
    });

    test('@forelse/@empty/@endforelse structure', () {
      final result = parser.parse('''
        @forelse(\$items as \$item)
          <p>{{ \$item }}</p>
        @empty
          <p>No items</p>
        @endforelse
      ''');

      // Expected: Special forelse structure with empty branch
      // Current: Unknown/incorrect parsing

      expect(result.isSuccess, isTrue,
          reason: '@forelse structure should parse successfully');

      final forelseDirective = result.ast!.children
          .whereType<DirectiveNode>()
          .where((n) => n.name == 'forelse')
          .firstOrNull;

      expect(forelseDirective, isNotNull,
          reason: '@forelse directive should be found');

      // Should have both filled and empty branches
      expect(forelseDirective!.children, isNotEmpty,
          reason: '@forelse should contain both branches');

      // Should recognize @empty as part of structure
      final hasEmptyBranch = forelseDirective.children
          .whereType<DirectiveNode>()
          .any((n) => n.name == 'empty');

      expect(hasEmptyBranch, isTrue,
          reason:
              '@empty should be a child of the @forelse directive structure');
    });

    test('Nested @unless directives', () {
      final result = parser.parse('''
        @unless(\$outer)
          <p>Outer</p>
          @unless(\$inner)
            <p>Inner</p>
          @endunless
        @endunless
      ''');

      expect(result.isSuccess, isTrue);

      final outerUnless = result.ast!.children
          .whereType<DirectiveNode>()
          .firstWhere((n) => n.name == 'unless');

      expect(outerUnless.children, isNotEmpty);

      // Should have nested unless
      final nestedUnless =
          outerUnless.children.whereType<DirectiveNode>().where((n) => n.name == 'unless');

      expect(nestedUnless, isNotEmpty,
          reason: 'Nested @unless should be found in outer @unless children');
    });
  });
}
