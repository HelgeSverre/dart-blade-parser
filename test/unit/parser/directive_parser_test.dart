import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Directive Parser Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Parse @if directive with expression', () {
      final result = parser.parse('@if(\$user->isAdmin())\n  <p>Admin</p>\n@endif');

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
      final ifNode = result.ast!.children.whereType<DirectiveNode>()
        .firstWhere((n) => n.name == 'if');
      expect(ifNode.name, equals('if'));
      expect(ifNode.children.length, greaterThan(0));
    });

    test('Parse @foreach directive', () {
      final result = parser.parse('@foreach(\$items as \$item)\n  {{ \$item }}\n@endforeach');

      expect(result.isSuccess, isTrue);

      final foreachNode = result.ast!.children.first as DirectiveNode;
      expect(foreachNode.name, equals('foreach'));
      expect(foreachNode.expression, contains('as'));
    });

    test('Parse @for directive', () {
      final result = parser.parse('@for(\$i = 0; \$i < 10; \$i++)\n  {{ \$i }}\n@endfor');

      expect(result.isSuccess, isTrue);

      final forNode = result.ast!.children.first as DirectiveNode;
      expect(forNode.name, equals('for'));
      expect(forNode.expression, contains('< 10'));
    });

    test('Parse @while directive', () {
      final result = parser.parse('@while(\$condition)\n  <p>Loop</p>\n@endwhile');

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
      final outerIf = result.ast!.children.whereType<DirectiveNode>()
        .firstWhere((n) => n.name == 'if');
      expect(outerIf.name, equals('if'));

      // Find nested foreach
      final nestedForeach = outerIf.children.whereType<DirectiveNode>()
        .firstWhere((n) => n.name == 'foreach');
      expect(nestedForeach, isNotNull);

      // Find innermost if
      final innerIf = nestedForeach.children.whereType<DirectiveNode>()
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
      final result = parser.parse('@foreach(\$items as \$item)\n  {{ \$item }}');

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
}
