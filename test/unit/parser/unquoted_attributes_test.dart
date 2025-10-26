import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for unquoted attribute values
/// These tests EXPOSE bugs - unquoted values not supported
void main() {
  group('Unquoted Attribute Values Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Simple unquoted attribute value', () {
      final result = parser.parse('<div class=container>Content</div>');

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Unquoted attributes are valid HTML',
      );

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(
        div.attributes.containsKey('class'),
        isTrue,
        reason: 'Should recognize class attribute',
      );

      final classAttr = div.attributes['class'];
      expect(classAttr, isNotNull);

      // Current bug: value might be null or parsing fails
      expect(
        classAttr!.value,
        equals('container'),
        reason: 'Unquoted value should be captured',
      );
    });

    test('Numeric unquoted value', () {
      final result = parser.parse('<input maxlength=100 tabindex=0>');

      expect(result.isSuccess, isTrue);

      final input = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'input');

      expect(input.attributes.containsKey('maxlength'), isTrue);
      expect(input.attributes['maxlength']!.value, equals('100'));

      expect(input.attributes.containsKey('tabindex'), isTrue);
      expect(input.attributes['tabindex']!.value, equals('0'));
    });

    test('Livewire attribute with unquoted value', () {
      final result = parser.parse('<div wire:poll=500ms>Content</div>');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(
        div.attributes.containsKey('wire:poll'),
        isTrue,
        reason: 'Should recognize wire:poll attribute',
      );

      final pollAttr = div.attributes['wire:poll'];
      expect(pollAttr, isNotNull);
      expect(pollAttr, isA<LivewireAttribute>());

      // Current bug: unquoted value likely fails
      expect(
        pollAttr!.value,
        equals('500ms'),
        reason: 'Unquoted Livewire value should work',
      );
    });

    test('Alpine.js attribute with unquoted value', () {
      final result = parser.parse('<div x-show=isOpen>Content</div>');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(div.attributes.containsKey('x-show'), isTrue);

      final showAttr = div.attributes['x-show'];
      expect(showAttr, isA<AlpineAttribute>());
      expect(showAttr!.value, equals('isOpen'));
    });

    test('Multiple unquoted attributes', () {
      final result = parser.parse('''
        <div id=main class=container data-x=value></div>
      ''');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(
        div.attributes.length,
        equals(3),
        reason: 'Should parse all three unquoted attributes',
      );

      expect(div.attributes['id']!.value, equals('main'));
      expect(div.attributes['class']!.value, equals('container'));
      expect(div.attributes['data-x']!.value, equals('value'));
    });

    test('Mixed quoted and unquoted attributes', () {
      final result = parser.parse('''
        <div class="quoted" id=unquoted data-test="another" tabindex=0></div>
      ''');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(div.attributes.length, equals(4));

      // Quoted attributes should work (baseline)
      expect(div.attributes['class']!.value, equals('quoted'));
      expect(div.attributes['data-test']!.value, equals('another'));

      // Unquoted attributes should also work
      expect(
        div.attributes['id']!.value,
        equals('unquoted'),
        reason: 'Unquoted attribute should work alongside quoted',
      );
      expect(div.attributes['tabindex']!.value, equals('0'));
    });

    test('Unquoted value with hyphen', () {
      final result = parser.parse('<meta charset=utf-8>');

      expect(result.isSuccess, isTrue);

      final meta = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'meta',
          );

      expect(
        meta.attributes['charset']!.value,
        equals('utf-8'),
        reason: 'Unquoted value should include hyphen',
      );
    });

    test('Unquoted value stops at whitespace', () {
      final result = parser.parse('<div class=container id=main>Content</div>');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      // class=container should stop at whitespace before id
      expect(
        div.attributes['class']!.value,
        equals('container'),
        reason: 'Unquoted value should stop at whitespace',
      );

      expect(div.attributes['id']!.value, equals('main'));
    });

    test('Unquoted value stops at tag end', () {
      final result = parser.parse('<div class=test>Content</div>');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(
        div.attributes['class']!.value,
        equals('test'),
        reason: 'Unquoted value should stop at >',
      );
    });

    test('Unquoted value stops at self-close', () {
      final result = parser.parse('<input type=text />');

      expect(result.isSuccess, isTrue);

      final input = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'input');

      expect(
        input.attributes['type']!.value,
        equals('text'),
        reason: 'Unquoted value should stop at />',
      );
    });

    test('Unquoted URL value', () {
      final result = parser.parse('<a href=https://example.com>Link</a>');

      expect(result.isSuccess, isTrue);

      final anchor = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'a');

      // URL should be captured up to tag end or whitespace
      expect(
        anchor.attributes['href']!.value,
        equals('https://example.com'),
        reason: 'URL in unquoted attribute should work',
      );
    });

    test('Component with unquoted attributes', () {
      final result = parser.parse(
        '<x-button size=lg variant=primary>Click</x-button>',
      );

      if (!result.isSuccess) {
        print('Parser errors: ${result.errors}');
      }
      expect(result.isSuccess, isTrue);

      final component = result.ast!.children
          .whereType<ComponentNode>()
          .firstWhere((c) => c.name == 'button');

      expect(component.attributes['size']!.value, equals('lg'));
      expect(component.attributes['variant']!.value, equals('primary'));
    });

    test('Boolean attribute (no value) vs unquoted value', () {
      final result = parser.parse('<input disabled checked=true>');

      expect(result.isSuccess, isTrue);

      final input = result.ast!.children
          .whereType<HtmlElementNode>()
          .firstWhere((e) => e.tagName == 'input');

      // disabled is boolean (no value)
      expect(input.attributes.containsKey('disabled'), isTrue);
      expect(
        input.attributes['disabled']!.value,
        isNull,
        reason: 'Boolean attribute should have no value',
      );

      // checked has explicit value
      expect(
        input.attributes['checked']!.value,
        equals('true'),
        reason: 'checked=true should capture "true" as value',
      );
    });

    test('Unquoted value with underscore', () {
      final result = parser.parse(
        '<div data-test_value=some_value>Content</div>',
      );

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      expect(
        div.attributes['data-test_value']!.value,
        equals('some_value'),
        reason: 'Underscores should be allowed in unquoted values',
      );
    });

    test('Unquoted value with period', () {
      final result = parser.parse('<div class=text.lg.bold>Content</div>');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      // Periods should be allowed in unquoted values
      expect(
        div.attributes['class']!.value,
        contains('.'),
        reason: 'Periods should be allowed in unquoted values',
      );
    });
  });
}
