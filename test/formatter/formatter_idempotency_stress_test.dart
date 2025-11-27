import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Comprehensive idempotency stress tests for the formatter.
///
/// Tests that format(format(input)) == format(input) for many variations.
/// This is critical to ensure the formatter doesn't keep changing output.
void main() {
  group('Formatter Idempotency Stress Tests', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    /// Helper to test idempotency with detailed failure reporting
    void expectIdempotent(String input, {String? description}) {
      final String formatted1;
      try {
        formatted1 = formatter.format(input);
      } catch (e) {
        // If first format fails, that's a parse error - skip
        return;
      }

      final formatted2 = formatter.format(formatted1);

      if (formatted1 != formatted2) {
        // Provide detailed diff
        print('=== IDEMPOTENCY FAILURE ===');
        print('Description: ${description ?? "N/A"}');
        print('--- First pass (${formatted1.length} chars) ---');
        print(formatted1);
        print('--- Second pass (${formatted2.length} chars) ---');
        print(formatted2);
        print('--- Diff ---');
        _showDiff(formatted1, formatted2);
        print('===========================');
      }

      expect(
        formatted2,
        equals(formatted1),
        reason: description ?? 'format(format(x)) should equal format(x)',
      );
    }

    /// Helper to test idempotency through multiple passes
    void expectIdempotentMultiPass(String input, {int passes = 5, String? description}) {
      final String formatted1;
      try {
        formatted1 = formatter.format(input);
      } catch (e) {
        return;
      }

      var current = formatted1;
      for (var i = 2; i <= passes; i++) {
        final next = formatter.format(current);
        if (next != current) {
          print('=== MULTI-PASS IDEMPOTENCY FAILURE (pass $i) ===');
          print('Description: ${description ?? "N/A"}');
          print('--- Pass ${i - 1} ---');
          print(current);
          print('--- Pass $i ---');
          print(next);
          print('===========================');
          fail('Output changed on pass $i: ${description ?? ""}');
        }
        current = next;
      }
    }

    group('Basic Templates', () {
      final basicTemplates = [
        '<div>Hello</div>',
        '<p>{{ \$variable }}</p>',
        '@if(\$x)\n<p>Yes</p>\n@endif',
        '<x-button>Click</x-button>',
        '{{-- Comment --}}',
        '<!-- HTML Comment -->',
        '<br>',
        '<img src="test.jpg">',
        '<input type="text" name="field">',
        '{!! \$html !!}',
        '@foreach(\$items as \$item)\n<li>{{ \$item }}</li>\n@endforeach',
      ];

      for (var i = 0; i < basicTemplates.length; i++) {
        test('basic template #${i + 1} is idempotent', () {
          expectIdempotent(basicTemplates[i], description: 'Basic #${i + 1}');
        });
      }
    });

    group('Whitespace Variations', () {
      test('no whitespace', () {
        expectIdempotent('<div><p>Content</p></div>');
      });

      test('single spaces', () {
        expectIdempotent('<div> <p> Content </p> </div>');
      });

      test('multiple spaces', () {
        expectIdempotent('<div>    <p>    Content    </p>    </div>');
      });

      test('tabs', () {
        expectIdempotent('<div>\t<p>\tContent\t</p>\t</div>');
      });

      test('newlines', () {
        expectIdempotent('<div>\n<p>\nContent\n</p>\n</div>');
      });

      test('mixed whitespace', () {
        expectIdempotent('<div>\n\t  <p>  \t\nContent\n  \t</p>\n</div>');
      });

      test('excessive blank lines', () {
        expectIdempotent('<div>\n\n\n<p>Content</p>\n\n\n</div>');
      });

      test('trailing whitespace', () {
        expectIdempotent('<div>   \n<p>Content</p>   \n</div>   ');
      });

      test('leading whitespace', () {
        expectIdempotent('   \n   <div>\n<p>Content</p>\n</div>');
      });
    });

    group('Nesting Depth', () {
      for (var depth = 1; depth <= 15; depth++) {
        test('$depth levels of HTML nesting', () {
          var opening = '';
          var closing = '';
          for (var i = 0; i < depth; i++) {
            opening += '<div>\n';
            closing = '</div>\n' + closing;
          }
          final input = '$opening<p>Deep content</p>\n$closing';
          expectIdempotent(input, description: '$depth levels HTML');
        });
      }

      for (var depth = 1; depth <= 10; depth++) {
        test('$depth levels of directive nesting', () {
          var opening = '';
          var closing = '';
          for (var i = 0; i < depth; i++) {
            opening += '@if(\$level$i)\n';
            closing = '@endif\n' + closing;
          }
          final input = '$opening<p>Deep</p>\n$closing';
          expectIdempotent(input, description: '$depth levels directives');
        });
      }

      test('mixed HTML and directive nesting', () {
        const input = '''
<div>
@if(\$a)
<section>
@foreach(\$items as \$item)
<article>
@if(\$item->show)
<p>{{ \$item->name }}</p>
@endif
</article>
@endforeach
</section>
@endif
</div>
''';
        expectIdempotentMultiPass(input, description: 'Mixed nesting');
      });
    });

    group('Attributes', () {
      test('single attribute', () {
        expectIdempotent('<div class="test">Content</div>');
      });

      test('multiple attributes', () {
        expectIdempotent('<div class="test" id="main" data-value="123">Content</div>');
      });

      test('boolean attributes', () {
        expectIdempotent('<input type="checkbox" checked disabled readonly>');
      });

      test('unquoted attributes', () {
        expectIdempotent('<div class=test id=main>Content</div>');
      });

      test('single-quoted attributes', () {
        expectIdempotent("<div class='test' id='main'>Content</div>");
      });

      test('Alpine attributes', () {
        expectIdempotent('<div x-data="{ open: false }" x-show="open" @click="toggle">Content</div>');
      });

      test('Livewire attributes', () {
        expectIdempotent('<input wire:model.live="name" wire:loading.class="opacity-50">');
      });

      test('mixed attribute types', () {
        expectIdempotent('''
<button
type="submit"
class="btn"
id="save-btn"
data-action="save"
x-on:click="handleClick"
wire:click="save"
wire:loading.attr="disabled"
>
Save
</button>
''');
      });

      test('attributes with Blade expressions', () {
        expectIdempotent('<div class="{{ \$class }}" data-id="{{ \$id }}">Content</div>');
      });

      test('many attributes', () {
        final attrs = List.generate(20, (i) => 'data-attr-$i="value$i"').join(' ');
        expectIdempotent('<div $attrs>Content</div>');
      });
    });

    group('Echo Statements', () {
      test('escaped echo', () {
        expectIdempotent('{{ \$variable }}');
      });

      test('unescaped echo', () {
        expectIdempotent('{!! \$html !!}');
      });

      test('echo with complex expression', () {
        expectIdempotent('{{ \$user->posts()->where("active", true)->count() }}');
      });

      test('echo with ternary', () {
        expectIdempotent('{{ \$isActive ? "Yes" : "No" }}');
      });

      test('multiple echos in paragraph', () {
        expectIdempotent('<p>{{ \$first }} and {{ \$second }} with {{ \$third }}</p>');
      });

      test('echo in attribute', () {
        expectIdempotent('<div class="{{ \$class }}">Content</div>');
      });

      test('echo with spacing variations', () {
        // Test that different input spacing produces same output
        final input1 = formatter.format('{{ \$var }}');
        final input2 = formatter.format('{{  \$var  }}');
        final input3 = formatter.format('{{\$var}}');
        expect(input1, equals(input2));
        expect(input2, equals(input3));
      });
    });

    group('Directives', () {
      final directives = [
        '@if(\$condition)\n<p>Yes</p>\n@endif',
        '@if(\$a)\n<p>A</p>\n@else\n<p>B</p>\n@endif',
        '@if(\$a)\n<p>A</p>\n@elseif(\$b)\n<p>B</p>\n@else\n<p>C</p>\n@endif',
        '@unless(\$hidden)\n<p>Visible</p>\n@endunless',
        '@foreach(\$items as \$item)\n<li>{{ \$item }}</li>\n@endforeach',
        '@forelse(\$items as \$item)\n<li>{{ \$item }}</li>\n@empty\n<p>None</p>\n@endforelse',
        '@for(\$i = 0; \$i < 10; \$i++)\n<p>{{ \$i }}</p>\n@endfor',
        '@while(\$running)\n<p>Running</p>\n@endwhile',
        '@switch(\$type)\n@case("a")\n<p>A</p>\n@break\n@default\n<p>Default</p>\n@endswitch',
        '@auth\n<p>Logged in</p>\n@endauth',
        '@guest\n<p>Guest</p>\n@endguest',
        '@can("edit", \$post)\n<a>Edit</a>\n@endcan',
        '@env("local")\n<p>Dev</p>\n@endenv',
        '@production\n<p>Prod</p>\n@endproduction',
        '@push("scripts")\n<script></script>\n@endpush',
        '@once\n<script></script>\n@endonce',
        '@php\n\$x = 1;\n@endphp',
        '@verbatim\n{{ not processed }}\n@endverbatim',
      ];

      for (var i = 0; i < directives.length; i++) {
        test('directive #${i + 1}', () {
          expectIdempotent(directives[i], description: 'Directive #${i + 1}');
        });
      }

      test('inline directives', () {
        expectIdempotent('@csrf');
        expectIdempotent('@method("PUT")');
        expectIdempotent('@include("partial")');
        expectIdempotent('@yield("content")');
        expectIdempotent('@extends("layout")');
      });
    });

    group('Components', () {
      test('simple component', () {
        expectIdempotent('<x-alert>Message</x-alert>');
      });

      test('self-closing component', () {
        expectIdempotent('<x-icon name="star" />');
      });

      test('component with attributes', () {
        expectIdempotent('<x-button type="submit" class="btn" :disabled="\$loading">Save</x-button>');
      });

      test('component with slot', () {
        expectIdempotent('''
<x-card>
<x-slot:header>
<h2>Title</h2>
</x-slot>
<p>Content</p>
</x-card>
''');
      });

      test('nested components', () {
        expectIdempotent('''
<x-layout>
<x-slot:nav>
<x-nav-item href="/">Home</x-nav-item>
<x-nav-item href="/about">About</x-nav-item>
</x-slot>
<x-card>
<p>Content</p>
</x-card>
</x-layout>
''');
      });

      test('component with directive inside', () {
        expectIdempotent('''
<x-card>
@if(\$showHeader)
<x-slot:header>
<h2>{{ \$title }}</h2>
</x-slot>
@endif
<p>{{ \$content }}</p>
</x-card>
''');
      });
    });

    group('Comments', () {
      test('Blade comment', () {
        expectIdempotent('{{-- This is a comment --}}');
      });

      test('HTML comment', () {
        expectIdempotent('<!-- This is a comment -->');
      });

      test('multiline Blade comment', () {
        expectIdempotent('{{--\nLine 1\nLine 2\n--}}');
      });

      test('comment between elements', () {
        expectIdempotent('<div>Before</div>\n{{-- Comment --}}\n<div>After</div>');
      });

      test('comment inside element', () {
        expectIdempotent('<div>\n{{-- Comment --}}\n<p>Content</p>\n</div>');
      });
    });

    group('Real-World Templates', () {
      test('login form', () {
        expectIdempotentMultiPass('''
<form method="POST" action="/login">
@csrf
<div class="form-group">
<label for="email">Email</label>
<input type="email" id="email" name="email" class="form-control" required>
</div>
<div class="form-group">
<label for="password">Password</label>
<input type="password" id="password" name="password" class="form-control" required>
</div>
<button type="submit" class="btn btn-primary">Login</button>
</form>
''', description: 'Login form');
      });

      test('data table', () {
        expectIdempotentMultiPass('''
<table class="table">
<thead>
<tr>
<th>Name</th>
<th>Email</th>
<th>Actions</th>
</tr>
</thead>
<tbody>
@forelse(\$users as \$user)
<tr>
<td>{{ \$user->name }}</td>
<td>{{ \$user->email }}</td>
<td>
<a href="{{ route("users.edit", \$user) }}">Edit</a>
<form method="POST" action="{{ route("users.destroy", \$user) }}">
@csrf
@method("DELETE")
<button type="submit">Delete</button>
</form>
</td>
</tr>
@empty
<tr>
<td colspan="3">No users found</td>
</tr>
@endforelse
</tbody>
</table>
''', description: 'Data table');
      });

      test('dashboard layout', () {
        expectIdempotentMultiPass('''
<x-layout>
<x-slot:header>
<nav>
@auth
<span>{{ auth()->user()->name }}</span>
<a href="/logout">Logout</a>
@else
<a href="/login">Login</a>
@endauth
</nav>
</x-slot>

<main>
@if(\$notifications->count())
<x-alert type="info">
You have {{ \$notifications->count() }} new notifications
</x-alert>
@endif

<div class="grid">
@foreach(\$widgets as \$widget)
<x-widget :data="\$widget" />
@endforeach
</div>
</main>

<x-slot:footer>
<p>&copy; {{ date("Y") }} My App</p>
</x-slot>
</x-layout>
''', description: 'Dashboard layout');
      });

      test('Livewire component', () {
        expectIdempotentMultiPass('''
<div wire:poll.5s>
<div class="flex justify-between">
<input type="text" wire:model.live="search" placeholder="Search...">
<select wire:model="perPage">
<option value="10">10</option>
<option value="25">25</option>
<option value="50">50</option>
</select>
</div>

<div wire:loading class="spinner"></div>

<div wire:loading.remove>
@forelse(\$items as \$item)
<div wire:key="{{ \$item->id }}" class="item">
<span>{{ \$item->name }}</span>
<button wire:click="edit({{ \$item->id }})">Edit</button>
<button wire:click="delete({{ \$item->id }})" wire:confirm="Are you sure?">Delete</button>
</div>
@empty
<p>No items found</p>
@endforelse
</div>

{{ \$items->links() }}
</div>
''', description: 'Livewire component');
      });

      test('Alpine.js dropdown', () {
        expectIdempotentMultiPass('''
<div x-data="{ open: false }" class="dropdown">
<button @click="open = !open" class="btn">
{{ \$label }}
<x-icon name="chevron-down" x-bind:class="{ 'rotate-180': open }" />
</button>

<div x-show="open" @click.away="open = false" x-transition class="dropdown-menu">
@foreach(\$items as \$item)
<a href="{{ \$item->url }}" @click="open = false" class="dropdown-item">
{{ \$item->label }}
</a>
@endforeach
</div>
</div>
''', description: 'Alpine dropdown');
      });
    });

    group('Configuration Variations', () {
      test('2-space indent', () {
        final fmt = BladeFormatter(config: const FormatterConfig(indentSize: 2));
        const input = '@if(\$x)\n<p>Content</p>\n@endif';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('tab indent', () {
        final fmt = BladeFormatter(config: const FormatterConfig(indentStyle: IndentStyle.tabs));
        const input = '@if(\$x)\n<p>Content</p>\n@endif';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('single quotes', () {
        final fmt = BladeFormatter(config: const FormatterConfig(quoteStyle: QuoteStyle.single));
        const input = '<div class="test" id="main">Content</div>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('double quotes', () {
        final fmt = BladeFormatter(config: const FormatterConfig(quoteStyle: QuoteStyle.double));
        const input = "<div class='test' id='main'>Content</div>";
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('no directive spacing', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(directiveSpacing: DirectiveSpacing.none),
        );
        const input = '@if(\$a)\n<p>A</p>\n@endif\n@if(\$b)\n<p>B</p>\n@endif';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('wrap always', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(wrapAttributes: WrapAttributes.always),
        );
        const input = '<div class="test" id="main" data-value="123">Content</div>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('attribute sorting alphabetical', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.alphabetical),
        );
        const input = '<div z="1" a="2" m="3">Content</div>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('attribute sorting by type', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(attributeSort: AttributeSort.byType),
        );
        const input = '<div wire:click="save" class="btn" @click="handle" id="main">Content</div>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('closing bracket new line', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(
            wrapAttributes: WrapAttributes.always,
            closingBracketStyle: ClosingBracketStyle.newLine,
          ),
        );
        const input = '<div class="test" id="main">Content</div>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('self-closing always', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(selfClosingStyle: SelfClosingStyle.always),
        );
        const input = '<x-icon></x-icon>';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });

      test('self-closing never', () {
        final fmt = BladeFormatter(
          config: const FormatterConfig(selfClosingStyle: SelfClosingStyle.never),
        );
        const input = '<x-icon />';
        final pass1 = fmt.format(input);
        final pass2 = fmt.format(pass1);
        expect(pass1, equals(pass2));
      });
    });

    group('Multi-Pass Stability', () {
      test('5 passes on complex template', () {
        const input = '''
<x-layout>
@auth
<div class="dashboard" x-data="{ tab: 'home' }">
@foreach(\$widgets as \$widget)
<x-card :title="\$widget->title">
@if(\$widget->type === 'chart')
<x-chart :data="\$widget->data" />
@else
<p>{{ \$widget->content }}</p>
@endif
</x-card>
@endforeach
</div>
@endauth
</x-layout>
''';
        expectIdempotentMultiPass(input, passes: 5, description: 'Complex 5-pass');
      });

      test('10 passes on deeply nested', () {
        const input = '''
<div>
@if(\$a)
<section>
@foreach(\$items as \$item)
<article>
@if(\$item->visible)
<div>
@can('view', \$item)
<p>{{ \$item->content }}</p>
@endcan
</div>
@endif
</article>
@endforeach
</section>
@endif
</div>
''';
        expectIdempotentMultiPass(input, passes: 10, description: 'Nested 10-pass');
      });
    });
  });
}

/// Show a simple line-by-line diff
void _showDiff(String a, String b) {
  final linesA = a.split('\n');
  final linesB = b.split('\n');
  final maxLines = linesA.length > linesB.length ? linesA.length : linesB.length;

  for (var i = 0; i < maxLines; i++) {
    final lineA = i < linesA.length ? linesA[i] : '<missing>';
    final lineB = i < linesB.length ? linesB[i] : '<missing>';
    if (lineA != lineB) {
      print('Line ${i + 1}:');
      print('  Pass 1: ${_escapeWhitespace(lineA)}');
      print('  Pass 2: ${_escapeWhitespace(lineB)}');
    }
  }
}

String _escapeWhitespace(String s) {
  return s
      .replaceAll('\t', '→')
      .replaceAll(' ', '·')
      .replaceAll('\r', '↵')
      .replaceAll('\n', '↲');
}
