import 'package:test/test.dart';
import 'package:blade_parser/src/docs/php_array_parser.dart';

void main() {
  group('PhpArrayParser', () {
    group('basic parsing', () {
      test('parses empty array', () {
        final entries = PhpArrayParser('([])').parse();
        expect(entries, isEmpty);
      });

      test('parses array without outer parens', () {
        final entries = PhpArrayParser("['a' => 'b']").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('a'));
      });

      test('parses single key-value pair', () {
        final entries = PhpArrayParser("(['type' => 'button'])").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
        expect(entries[0].value, isA<PhpString>());
        expect((entries[0].value as PhpString).value, equals('button'));
      });

      test('parses multiple key-value pairs', () {
        final entries = PhpArrayParser(
          "(['type' => 'button', 'variant' => 'primary'])",
        ).parse();
        expect(entries, hasLength(2));
        expect(entries[0].key, equals('type'));
        expect(entries[1].key, equals('variant'));
      });

      test('parses standalone string (required prop)', () {
        final entries = PhpArrayParser("(['message'])").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, isNull);
        expect(entries[0].value, isA<PhpString>());
        expect((entries[0].value as PhpString).value, equals('message'));
      });

      test('parses mixed required and optional props', () {
        final entries = PhpArrayParser(
          "(['message', 'type' => 'button', 'title'])",
        ).parse();
        expect(entries, hasLength(3));

        expect(entries[0].key, isNull);
        expect((entries[0].value as PhpString).value, equals('message'));

        expect(entries[1].key, equals('type'));
        expect((entries[1].value as PhpString).value, equals('button'));

        expect(entries[2].key, isNull);
        expect((entries[2].value as PhpString).value, equals('title'));
      });

      test('handles trailing comma', () {
        final entries = PhpArrayParser("(['type' => 'button',])").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });
    });

    group('value types', () {
      test('parses single-quoted strings', () {
        final entries = PhpArrayParser("(['label' => 'hello'])").parse();
        expect((entries[0].value as PhpString).value, equals('hello'));
      });

      test('parses double-quoted strings', () {
        final entries =
            PhpArrayParser('(["label" => "hello"])').parse();
        expect((entries[0].value as PhpString).value, equals('hello'));
      });

      test('parses string with escaped quote', () {
        final entries =
            PhpArrayParser(r"(['label' => 'it\'s here'])").parse();
        expect((entries[0].value as PhpString).value, equals("it's here"));
      });

      test('parses string with escaped backslash', () {
        final entries =
            PhpArrayParser(r"(['path' => 'C:\\Users'])").parse();
        expect((entries[0].value as PhpString).value, equals(r'C:\Users'));
      });

      test('parses true', () {
        final entries = PhpArrayParser("(['active' => true])").parse();
        expect(entries[0].value, isA<PhpBool>());
        expect((entries[0].value as PhpBool).value, isTrue);
      });

      test('parses false', () {
        final entries = PhpArrayParser("(['disabled' => false])").parse();
        expect(entries[0].value, isA<PhpBool>());
        expect((entries[0].value as PhpBool).value, isFalse);
      });

      test('parses null', () {
        final entries = PhpArrayParser("(['icon' => null])").parse();
        expect(entries[0].value, isA<PhpNull>());
      });

      test('parses integer', () {
        final entries = PhpArrayParser("(['count' => 5])").parse();
        expect(entries[0].value, isA<PhpNumber>());
        expect((entries[0].value as PhpNumber).value, equals(5));
      });

      test('parses negative integer', () {
        final entries = PhpArrayParser("(['offset' => -1])").parse();
        expect(entries[0].value, isA<PhpNumber>());
        expect((entries[0].value as PhpNumber).value, equals(-1));
      });

      test('parses float', () {
        final entries = PhpArrayParser("(['price' => 19.99])").parse();
        expect(entries[0].value, isA<PhpNumber>());
        expect((entries[0].value as PhpNumber).value, equals(19.99));
      });

      test('parses empty nested array', () {
        final entries = PhpArrayParser("(['items' => []])").parse();
        expect(entries[0].value, isA<PhpArray>());
        expect((entries[0].value as PhpArray).entries, isEmpty);
      });

      test('parses nested array with values', () {
        final entries =
            PhpArrayParser("(['options' => ['a', 'b', 'c']])").parse();
        expect(entries[0].value, isA<PhpArray>());
        final nested = (entries[0].value as PhpArray).entries;
        expect(nested, hasLength(3));
        expect((nested[0].value as PhpString).value, equals('a'));
        expect((nested[1].value as PhpString).value, equals('b'));
        expect((nested[2].value as PhpString).value, equals('c'));
      });
    });

    group('comments', () {
      test('skips line comments', () {
        final entries = PhpArrayParser("""([
          // This is a comment
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('skips block comments', () {
        final entries = PhpArrayParser("""([
          /* Block comment */
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('does not extract props from line comments', () {
        final entries = PhpArrayParser("""([
          // 'old_name' => 'deprecated',
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('does not extract props from block comments', () {
        final entries = PhpArrayParser("""([
          /* 'removed' => 'gone' */
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('handles inline comments after values', () {
        final entries = PhpArrayParser("""([
          'type' => 'button', // the button type
          'message', // required
        ])""").parse();
        expect(entries, hasLength(2));
        expect(entries[0].key, equals('type'));
        expect(entries[1].key, isNull);
        expect((entries[1].value as PhpString).value, equals('message'));
      });

      test('comment text does not become false positive props', () {
        final entries = PhpArrayParser("""([
          'type' => 'button',
          'message', // like 'name' but required
        ])""").parse();
        expect(entries, hasLength(2));
        // 'name' from comment must NOT appear
        expect(entries.where((e) => e.key == 'name'), isEmpty);
        expect(
          entries.where(
            (e) => e.value is PhpString && (e.value as PhpString).value == 'name',
          ),
          isEmpty,
        );
      });
    });

    group('multiline and whitespace', () {
      test('parses multiline @props', () {
        final entries = PhpArrayParser("""([
          'type' => 'button',
          'variant' => 'primary',
          'size' => 'md',
          'disabled' => false,
          'loading' => false,
          'icon' => null,
        ])""").parse();
        expect(entries, hasLength(6));
        expect(entries[0].key, equals('type'));
        expect(entries[5].key, equals('icon'));
      });

      test('handles inconsistent spacing', () {
        final entries = PhpArrayParser(
          "([  'a'=>'b'  ,  'c'  =>  'd'  ])",
        ).parse();
        expect(entries, hasLength(2));
        expect(entries[0].key, equals('a'));
        expect(entries[1].key, equals('c'));
      });
    });

    group('strings containing delimiters', () {
      test('string containing => does not split into key-value', () {
        final entries = PhpArrayParser(
          "(['hint' => 'use key => value syntax'])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('hint'));
        expect(
          (entries[0].value as PhpString).value,
          equals('use key => value syntax'),
        );
      });

      test('string containing // is not treated as comment', () {
        final entries = PhpArrayParser(
          "(['url' => 'https://example.com'])",
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals('https://example.com'),
        );
      });

      test('string containing /* */ is not treated as comment', () {
        final entries = PhpArrayParser(
          r"(['pattern' => '/* not a comment */'])",
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals('/* not a comment */'),
        );
      });

      test('string containing square brackets', () {
        final entries = PhpArrayParser(
          r"(['format' => 'items[0]'])",
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals('items[0]'),
        );
      });

      test('string containing single quotes in double-quoted string', () {
        final entries = PhpArrayParser(
          '(["label" => "it\'s fine"])',
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals("it's fine"),
        );
      });

      test('string containing double quotes in single-quoted string', () {
        final entries = PhpArrayParser(
          r"""(['attr' => 'class="active"'])""",
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals('class="active"'),
        );
      });

      test('empty string value', () {
        final entries = PhpArrayParser("(['label' => ''])").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('label'));
        expect((entries[0].value as PhpString).value, isEmpty);
      });

      test('string with multiple escaped quotes', () {
        final entries = PhpArrayParser(
          r"(['msg' => 'he said \'hello\' and \'bye\''])",
        ).parse();
        expect(entries, hasLength(1));
        expect(
          (entries[0].value as PhpString).value,
          equals("he said 'hello' and 'bye'"),
        );
      });
    });

    group('comments in unusual positions', () {
      test('comment between key and =>', () {
        final entries = PhpArrayParser("""([
          'type' /* the type */ => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
        expect((entries[0].value as PhpString).value, equals('button'));
      });

      test('comment between => and value', () {
        final entries = PhpArrayParser("""([
          'type' => /* default */ 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
        expect((entries[0].value as PhpString).value, equals('button'));
      });

      test('comment at very start of array', () {
        final entries = PhpArrayParser("""([
          /* leading comment */
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('comment at very end of array before ]', () {
        final entries = PhpArrayParser("""([
          'type' => 'button',
          /* trailing comment */
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('multiple consecutive comments', () {
        final entries = PhpArrayParser("""([
          // comment 1
          // comment 2
          /* comment 3 */
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('block comment spanning multiple lines', () {
        final entries = PhpArrayParser("""([
          /*
           * This is a
           * multi-line comment
           */
          'type' => 'button',
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('commented-out block of multiple props', () {
        final entries = PhpArrayParser("""([
          /*
          'removed1' => 'a',
          'removed2' => 'b',
          'removed3',
          */
          'active' => true,
        ])""").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('active'));
      });
    });

    group('numeric edge cases', () {
      test('zero', () {
        final entries = PhpArrayParser("(['count' => 0])").parse();
        expect((entries[0].value as PhpNumber).value, equals(0));
      });

      test('negative float', () {
        final entries = PhpArrayParser("(['offset' => -3.14])").parse();
        expect((entries[0].value as PhpNumber).value, equals(-3.14));
      });

      test('large integer', () {
        final entries =
            PhpArrayParser("(['max' => 999999999])").parse();
        expect(
          (entries[0].value as PhpNumber).value,
          equals(999999999),
        );
      });
    });

    group('nested arrays', () {
      test('deeply nested arrays (3 levels)', () {
        final entries = PhpArrayParser(
          "(['config' => ['db' => ['host' => 'localhost']]])",
        ).parse();
        expect(entries, hasLength(1));
        final level1 = (entries[0].value as PhpArray).entries;
        expect(level1, hasLength(1));
        expect(level1[0].key, equals('db'));
        final level2 = (level1[0].value as PhpArray).entries;
        expect(level2, hasLength(1));
        expect(level2[0].key, equals('host'));
        expect((level2[0].value as PhpString).value, equals('localhost'));
      });

      test('array with mixed value types', () {
        final entries = PhpArrayParser(
          "(['defaults' => ['a', 1, true, null, 'b']])",
        ).parse();
        final nested = (entries[0].value as PhpArray).entries;
        expect(nested, hasLength(5));
        expect(nested[0].value, isA<PhpString>());
        expect(nested[1].value, isA<PhpNumber>());
        expect(nested[2].value, isA<PhpBool>());
        expect(nested[3].value, isA<PhpNull>());
        expect(nested[4].value, isA<PhpString>());
      });

      test('nested associative array', () {
        final entries = PhpArrayParser(
          "(['sizes' => ['sm' => 'small', 'md' => 'medium', 'lg' => 'large']])",
        ).parse();
        final nested = (entries[0].value as PhpArray).entries;
        expect(nested, hasLength(3));
        expect(nested[0].key, equals('sm'));
        expect(nested[2].key, equals('lg'));
      });
    });

    group('PHP expressions as values (fallback handling)', () {
      test('class constant as default', () {
        final entries = PhpArrayParser(
          "(['mode' => self::DEFAULT_MODE])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('mode'));
        // Falls back to raw string capture
        expect(entries[0].value.toString(), contains('self::DEFAULT_MODE'));
      });

      test('static method call as default', () {
        final entries = PhpArrayParser(
          "(['items' => Config::get('key')])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('items'));
      });

      test('PHP constant as default', () {
        final entries = PhpArrayParser(
          "(['separator' => DIRECTORY_SEPARATOR])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('separator'));
      });
    });

    group('keyword edge cases', () {
      test('true is not prefix-matched against trueish identifiers', () {
        // If someone has a PHP constant called 'trueValue', the parser
        // should not match 'true' and leave 'Value' dangling
        final entries = PhpArrayParser(
          "(['flag' => trueValue])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('flag'));
        // Should be captured as fallback, not as PhpBool
        expect(entries[0].value, isNot(isA<PhpBool>()));
      });

      test('null is not prefix-matched against nullable', () {
        final entries = PhpArrayParser(
          "(['type' => nullable])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].value, isNot(isA<PhpNull>()));
      });

      test('false is not prefix-matched against falsehood', () {
        final entries = PhpArrayParser(
          "(['val' => falsehood])",
        ).parse();
        expect(entries, hasLength(1));
        expect(entries[0].value, isNot(isA<PhpBool>()));
      });
    });

    group('graceful degradation', () {
      test('does not crash on empty input', () {
        final entries = PhpArrayParser('').parse();
        expect(entries, isEmpty);
      });

      test('does not crash on just parens', () {
        final entries = PhpArrayParser('()').parse();
        expect(entries, isEmpty);
      });

      test('does not crash on malformed input', () {
        final entries = PhpArrayParser('not an array at all').parse();
        expect(entries, isEmpty);
      });

      test('does not crash on unclosed string', () {
        // Should not infinite loop or throw
        final entries = PhpArrayParser("(['label' => 'unclosed])").parse();
        expect(entries, hasLength(1));
      });

      test('does not crash on unclosed array', () {
        final entries =
            PhpArrayParser("(['type' => 'button'").parse();
        expect(entries, hasLength(1));
        expect(entries[0].key, equals('type'));
      });

      test('does not crash on unclosed block comment', () {
        final entries = PhpArrayParser("""([
          /* unclosed comment
          'type' => 'button',
        ])""").parse();
        // The unclosed comment swallows everything — no props extracted
        expect(entries, isEmpty);
      });
    });

    group('real-world @props expressions', () {
      test('button component props', () {
        final entries = PhpArrayParser("""([
          'type' => 'button',
          'variant' => 'primary',
          'size' => 'md',
          'disabled' => false,
          'loading' => false,
          'icon' => null
        ])""").parse();
        expect(entries, hasLength(6));
        expect(entries.where((e) => e.key != null), hasLength(6));
      });

      test('notification component with required props', () {
        final entries = PhpArrayParser(
          "(['message', 'dismissible' => true])",
        ).parse();
        expect(entries, hasLength(2));
        expect(entries[0].key, isNull);
        expect((entries[0].value as PhpString).value, equals('message'));
        expect(entries[1].key, equals('dismissible'));
        expect((entries[1].value as PhpBool).value, isTrue);
      });

      test('heavily commented Flux-style component', () {
        final entries = PhpArrayParser("""([
          // Keyboard shortcut hint displayed alongside tooltip
          "kbd" => null,
          // Position relative to the trigger element
          // Can be: top, bottom, left, right
          'position' => 'top',
          /* Whether to show an arrow pointing to the trigger */
          'arrow' => true,
          // Delay in ms before showing
          'delay' => 200,
        ])""").parse();
        expect(entries, hasLength(4));
        expect(entries[0].key, equals('kbd'));
        expect(entries[0].value, isA<PhpNull>());
        expect(entries[1].key, equals('position'));
        expect((entries[1].value as PhpString).value, equals('top'));
        expect(entries[2].key, equals('arrow'));
        expect((entries[2].value as PhpBool).value, isTrue);
        expect(entries[3].key, equals('delay'));
        expect((entries[3].value as PhpNumber).value, equals(200));
      });

      test('component with array defaults and required props', () {
        final entries = PhpArrayParser("""([
          'title',
          'description',
          'type' => 'info',
          'actions' => [],
          'closeable' => true,
          'classes' => ['rounded', 'shadow'],
        ])""").parse();
        expect(entries, hasLength(6));
        // Required props
        expect(entries[0].key, isNull);
        expect((entries[0].value as PhpString).value, equals('title'));
        expect(entries[1].key, isNull);
        expect((entries[1].value as PhpString).value, equals('description'));
        // Optional props
        expect(entries[2].key, equals('type'));
        expect(entries[3].key, equals('actions'));
        expect((entries[3].value as PhpArray).entries, isEmpty);
        expect(entries[4].key, equals('closeable'));
        expect(entries[5].key, equals('classes'));
        expect((entries[5].value as PhpArray).entries, hasLength(2));
      });

      test('component with URL and CSS class defaults', () {
        final entries = PhpArrayParser("""([
          'href' => '#',
          'target' => '_self',
          'class' => 'btn btn-primary text-white hover:bg-blue-700',
          'rel' => 'noopener noreferrer',
        ])""").parse();
        expect(entries, hasLength(4));
        expect(
          (entries[2].value as PhpString).value,
          equals('btn btn-primary text-white hover:bg-blue-700'),
        );
      });

      test('messy formatting with tabs and mixed quotes', () {
        final entries = PhpArrayParser(
          "(\t[\t'a'\t=>\t\"b\"\t,\t'c'=>'d','e'=>\ttrue\t]\t)",
        ).parse();
        expect(entries, hasLength(3));
        expect(entries[0].key, equals('a'));
        expect((entries[0].value as PhpString).value, equals('b'));
        expect(entries[1].key, equals('c'));
        expect(entries[2].key, equals('e'));
        expect((entries[2].value as PhpBool).value, isTrue);
      });
    });
  });
}
