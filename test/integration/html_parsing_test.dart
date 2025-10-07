import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('HTML Parsing Integration Tests', () {
    // Quickstart scenario #1
    test('Parse simple HTML element with class attribute and text content', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="container">Hello</div>');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children, hasLength(1));

      final div = result.ast!.children[0] as HtmlElementNode;
      expect(div.tagName, 'div');
      expect(div.attributes['class'], isA<StandardAttribute>());
      expect(div.attributes['class']!.value, 'container');
      expect(div.children, hasLength(1));
      expect(div.children[0], isA<TextNode>());

      final text = div.children[0] as TextNode;
      expect(text.content, 'Hello');
    });

    // Quickstart scenario #2
    test('Parse void element (br) without closing tag', () {
      final parser = BladeParser();
      final result = parser.parse('<br>');

      expect(result.isSuccess, isTrue);
      final br = result.ast!.children[0] as HtmlElementNode;

      expect(br.tagName, 'br');
      expect(br.isVoid, true);
      expect(br.children, isEmpty);
    });

    // Quickstart scenario #3
    test('Parse self-closing element syntax', () {
      final parser = BladeParser();
      final result = parser.parse('<div />');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.tagName, 'div');
      expect(div.isSelfClosing, true);
      expect(div.children, isEmpty);
    });

    // Quickstart scenario #4
    test('Parse Alpine.js attributes (x-data, @click)', () {
      final parser = BladeParser();
      final result =
          parser.parse('<div x-data="{count: 0}" @click="count++"></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      final xData = div.attributes['x-data'] as AlpineAttribute;
      expect(xData, isNotNull);
      expect(xData.value, '{count: 0}');

      final onClick = div.attributes['@click'] as AlpineAttribute;
      expect(onClick, isNotNull);
      expect(onClick.value, 'count++');
    });

    // Quickstart scenario #5
    test('Parse Livewire attributes (wire:click, wire:loading.class)', () {
      final parser = BladeParser();
      final result = parser.parse(
          '<button wire:click="save" wire:loading.class="opacity-50">Save</button>');

      expect(result.isSuccess, isTrue);
      final button = result.ast!.children[0] as HtmlElementNode;

      final wireClick = button.attributes['wire:click'] as LivewireAttribute;
      expect(wireClick, isNotNull);
      expect(wireClick.value, 'save');

      final wireLoading =
          button.attributes['wire:loading.class'] as LivewireAttribute;
      expect(wireLoading, isNotNull);
      expect(wireLoading.value, 'opacity-50');
      expect(wireLoading.modifiers, contains('class'));
    });

    // Quickstart scenario #6
    test('Parse nested HTML structure', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          <header>
            <h1>Title</h1>
          </header>
          <main>
            <p>Content</p>
          </main>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.tagName, 'div');
      expect(div.children.whereType<HtmlElementNode>(), hasLength(2));

      final header = div.children.whereType<HtmlElementNode>().first;
      expect(header.tagName, 'header');

      final h1 = header.children.whereType<HtmlElementNode>().first;
      expect(h1.tagName, 'h1');
      expect((h1.children[0] as TextNode).content.trim(), 'Title');

      final main = div.children.whereType<HtmlElementNode>().skip(1).first;
      expect(main.tagName, 'main');

      final p = main.children.whereType<HtmlElementNode>().first;
      expect(p.tagName, 'p');
      expect((p.children[0] as TextNode).content.trim(), 'Content');
    });

    // Quickstart scenario #8
    test('Parse boolean attributes (disabled, required)', () {
      final parser = BladeParser();
      final result = parser.parse('<input type="text" disabled required>');

      expect(result.isSuccess, isTrue);
      final input = result.ast!.children[0] as HtmlElementNode;

      final disabled = input.attributes['disabled'] as StandardAttribute;
      expect(disabled, isNotNull);
      expect(disabled.value, isNull);

      final required = input.attributes['required'] as StandardAttribute;
      expect(required, isNotNull);
      expect(required.value, isNull);

      final typeAttr = input.attributes['type'] as StandardAttribute;
      expect(typeAttr, isNotNull);
      expect(typeAttr.value, 'text');
    });

    // Quickstart scenario #9
    test('Export HTML to JSON with attribute types', () {
      final parser = BladeParser();
      final result = parser.parse('<div class="foo" x-data="{}"></div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      final json = div.toJson();

      expect(json['type'], 'htmlElement');
      expect(json['tagName'], 'div');
      expect(json['attributes']['class']['type'], 'standard');
      expect(json['attributes']['x-data']['type'], 'alpine');

      // Verify JSON is encodable
      expect(() => jsonEncode(json), returnsNormally);
    });

    // Quickstart scenario #10
    test('Visitor pattern works with HTML elements', () {
      final parser = BladeParser();
      final result = parser.parse('<div><p>text</p><span>more</span></div>');

      expect(result.isSuccess, isTrue);

      final counter = HtmlElementCounter();
      result.ast!.accept(counter);

      expect(counter.count, 3); // div, p, span
    });

    test('Parse complex nested structure with multiple levels', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div class="wrapper">
          <nav>
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/about">About</a></li>
            </ul>
          </nav>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.tagName, 'div');
      expect(div.attributes['class']!.value, 'wrapper');

      final nav = div.children.whereType<HtmlElementNode>().first;
      expect(nav.tagName, 'nav');

      final ul = nav.children.whereType<HtmlElementNode>().first;
      expect(ul.tagName, 'ul');

      final lis = ul.children.whereType<HtmlElementNode>();
      expect(lis, hasLength(2));
    });

    test('Parse HTML with multiple attribute types mixed', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div
          id="app"
          class="container"
          data-user-id="123"
          x-data="{open: false}"
          @click="open = true"
          wire:click="save"
          wire:loading.attr="disabled"
          disabled>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.attributes['id'], isA<StandardAttribute>());
      expect(div.attributes['class'], isA<StandardAttribute>());
      expect(div.attributes['data-user-id'], isA<StandardAttribute>());
      expect(div.attributes['x-data'], isA<AlpineAttribute>());
      expect(div.attributes['@click'], isA<AlpineAttribute>());
      expect(div.attributes['wire:click'], isA<LivewireAttribute>());
      expect(div.attributes['wire:loading.attr'], isA<LivewireAttribute>());
      expect(div.attributes['disabled'], isA<StandardAttribute>());
      expect(div.attributes['disabled']!.value, isNull);
    });

    test('Parse void elements with attributes', () {
      final parser = BladeParser();
      final result = parser.parse('<input type="email" name="email" required>');

      expect(result.isSuccess, isTrue);
      final input = result.ast!.children[0] as HtmlElementNode;

      expect(input.tagName, 'input');
      expect(input.isVoid, true);
      expect(input.attributes, hasLength(3));
      expect(input.attributes['type']!.value, 'email');
      expect(input.attributes['name']!.value, 'email');
      expect(input.attributes['required']!.value, isNull);
    });

    test('Parse HTML with text and whitespace', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          Hello
          <span>World</span>
          !
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;

      expect(div.children, isNotEmpty);
      expect(div.children.whereType<TextNode>(), isNotEmpty);
      expect(div.children.whereType<HtmlElementNode>(), hasLength(1));
    });

    test('Parse self-closing void element', () {
      final parser = BladeParser();
      final result = parser.parse('<br />');

      expect(result.isSuccess, isTrue);
      final br = result.ast!.children[0] as HtmlElementNode;

      expect(br.tagName, 'br');
      expect(br.isVoid, true);
      expect(br.isSelfClosing, true);
      expect(br.children, isEmpty);
    });

    test('Parse all void elements', () {
      final parser = BladeParser();
      final voidElements = [
        'area',
        'base',
        'br',
        'col',
        'embed',
        'hr',
        'img',
        'input',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr'
      ];

      for (final tag in voidElements) {
        final result = parser.parse('<$tag>');
        expect(result.isSuccess, isTrue, reason: 'Failed parsing <$tag>');

        final element = result.ast!.children[0] as HtmlElementNode;
        expect(element.tagName, tag);
        expect(element.isVoid, true, reason: '<$tag> should be void');
      }
    });
  });
}

// Test visitor for counting HTML elements
class HtmlElementCounter extends AstVisitor<void> {
  int count = 0;

  @override
  void visitHtmlElement(HtmlElementNode node) {
    count++;
    for (final child in node.children) {
      child.accept(this);
    }
  }

  @override
  void visitDocument(DocumentNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
  }

  @override
  void visitText(TextNode node) {}

  @override
  void visitDirective(DirectiveNode node) {}

  @override
  void visitEcho(EchoNode node) {}

  @override
  void visitComponent(ComponentNode node) {}

  @override
  void visitComment(CommentNode node) {}

  @override
  void visitError(ErrorNode node) {}

  @override
  void visitSlot(SlotNode node) {}
}
