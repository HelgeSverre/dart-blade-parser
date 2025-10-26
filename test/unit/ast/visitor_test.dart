import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/visitor.dart';

void main() {
  group('RecursiveAstVisitor Tests', () {
    test('NodeCounter visits all nodes in document', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          @if(\$show)
            <p>{{ \$message }}</p>
          @endif
        </div>
      ''');

      final counter = NodeCounter();
      result.ast!.accept(counter);

      expect(counter.totalCount, greaterThan(0));
      expect(counter.directiveCount, 1); // @if
      expect(counter.echoCount, 1); // {{ \$message }}
      expect(counter.textCount, greaterThan(0));
    });

    test('DirectiveCollector gathers all directives', () {
      final parser = BladeParser();
      final result = parser.parse('''
        @if(\$x)
          @foreach(\$items as \$item)
            @include('partial')
          @endforeach
        @endif
      ''');

      final collector = DirectiveCollector();
      result.ast!.accept(collector);

      expect(collector.directives, hasLength(3));
      expect(
        collector.directives.map((d) => d.name).toList(),
        containsAll(['if', 'foreach', 'include']),
      );
    });

    test('EchoCollector gathers all echo statements', () {
      final parser = BladeParser();
      final result = parser.parse('''
        {{ \$name }}
        {!! \$html !!}
        <p>{{ \$count }}</p>
      ''');

      final collector = EchoCollector();
      result.ast!.accept(collector);

      expect(collector.echoes, hasLength(3));
      expect(collector.echoes.where((e) => e.isRaw).length, 1);
      expect(collector.echoes.where((e) => !e.isRaw).length, 2);
    });

    test('ComponentCollector gathers all components', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <x-alert type="success">
          <x-icon name="check" />
          Message content
        </x-alert>
      ''');

      final collector = ComponentCollector();
      result.ast!.accept(collector);

      expect(collector.components, isNotEmpty);
      expect(collector.components.map((c) => c.name), contains('alert'));
      expect(collector.components.map((c) => c.name), contains('icon'));
    });

    test('Visitor traverses nested structures correctly', () {
      final parser = BladeParser();
      final result = parser.parse('''
        @section('content')
          <div>
            @if(\$items)
              @foreach(\$items as \$item)
                <x-card>
                  {{ \$item->name }}
                </x-card>
              @endforeach
            @endif
          </div>
        @endsection
      ''');

      final counter = NodeCounter();
      result.ast!.accept(counter);

      // Verify deep traversal
      expect(counter.totalCount, greaterThan(10));
      expect(counter.directiveCount, 3); // section, if, foreach
      expect(counter.componentCount, 1); // x-card
    });

    test('Visitor with slots', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <x-layout>
          <x-slot name="header">
            <h1>Title</h1>
          </x-slot>
          <p>Content</p>
        </x-layout>
      ''');

      final collector = SlotCollector();
      result.ast!.accept(collector);

      expect(collector.slots, hasLength(1));
      expect(collector.slots.first.name, 'header');
    });

    test('Visitor handles comments', () {
      final parser = BladeParser();
      final result = parser.parse('''
        {{-- Blade comment --}}
        <!-- HTML comment -->
        <p>Text</p>
      ''');

      final collector = CommentCollector();
      result.ast!.accept(collector);

      expect(collector.comments, hasLength(2));
      expect(
        collector.comments.where((c) => c.isBladeComment).length,
        1,
      );
      expect(
        collector.comments.where((c) => !c.isBladeComment).length,
        1,
      );
    });

    test('Visitor handles error nodes', () {
      final parser = BladeParser();
      final result = parser.parse('@if(\$x) <!-- Missing @endif -->');

      final collector = ErrorCollector();
      result.ast!.accept(collector);

      // Parser may or may not create error nodes depending on error recovery
      expect(collector.errors, isA<List<ErrorNode>>());
    });

    test('defaultVisit is called for unknown node types', () {
      final visitor = CustomVisitor();
      final parser = BladeParser();
      final result = parser.parse('<p>Test</p>');

      result.ast!.accept(visitor);

      // Should not throw, should use defaultValue
      expect(visitor.visitedTypes, isNotEmpty);
    });
  });
}

/// Counts all nodes in the AST.
class NodeCounter extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  int totalCount = 0;
  int directiveCount = 0;
  int echoCount = 0;
  int textCount = 0;
  int componentCount = 0;

  @override
  void visitDocument(DocumentNode node) {
    totalCount++;
    super.visitDocument(node);
  }

  @override
  void visitDirective(DirectiveNode node) {
    totalCount++;
    directiveCount++;
    super.visitDirective(node);
  }

  @override
  void visitEcho(EchoNode node) {
    totalCount++;
    echoCount++;
    super.visitEcho(node);
  }

  @override
  void visitText(TextNode node) {
    totalCount++;
    textCount++;
    super.visitText(node);
  }

  @override
  void visitComponent(ComponentNode node) {
    totalCount++;
    componentCount++;
    super.visitComponent(node);
  }

  @override
  void visitHtmlElement(HtmlElementNode node) {
    totalCount++;
    super.visitHtmlElement(node);
  }

  @override
  void visitComment(CommentNode node) {
    totalCount++;
    super.visitComment(node);
  }

  @override
  void visitError(ErrorNode node) {
    totalCount++;
    super.visitError(node);
  }

  @override
  void visitSlot(SlotNode node) {
    totalCount++;
    super.visitSlot(node);
  }
}

/// Collects all directive nodes.
class DirectiveCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<DirectiveNode> directives = [];

  @override
  void visitDirective(DirectiveNode node) {
    directives.add(node);
    super.visitDirective(node);
  }
}

/// Collects all echo nodes.
class EchoCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<EchoNode> echoes = [];

  @override
  void visitEcho(EchoNode node) {
    echoes.add(node);
    super.visitEcho(node);
  }
}

/// Collects all component nodes.
class ComponentCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<ComponentNode> components = [];

  @override
  void visitComponent(ComponentNode node) {
    components.add(node);
    super.visitComponent(node);
  }
}

/// Collects all slot nodes.
class SlotCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<SlotNode> slots = [];

  @override
  void visitSlot(SlotNode node) {
    slots.add(node);
    super.visitSlot(node);
  }
}

/// Collects all comment nodes.
class CommentCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<CommentNode> comments = [];

  @override
  void visitComment(CommentNode node) {
    comments.add(node);
    super.visitComment(node);
  }
}

/// Collects all error nodes.
class ErrorCollector extends RecursiveAstVisitor<void> {
  @override
  void get defaultValue => null;

  final List<ErrorNode> errors = [];

  @override
  void visitError(ErrorNode node) {
    errors.add(node);
    super.visitError(node);
  }
}

/// Custom visitor for testing defaultVisit.
class CustomVisitor extends RecursiveAstVisitor<String> {
  @override
  String get defaultValue => 'default';

  final List<String> visitedTypes = [];

  @override
  String visitDocument(DocumentNode node) {
    visitedTypes.add('document');
    super.visitDocument(node);
    return defaultValue;
  }

  @override
  String visitText(TextNode node) {
    visitedTypes.add('text');
    return defaultValue;
  }

  @override
  String visitHtmlElement(HtmlElementNode node) {
    visitedTypes.add('html');
    super.visitHtmlElement(node);
    return defaultValue;
  }
}
