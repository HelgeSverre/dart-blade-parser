import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Stress tests for the formatter with extremely noisy, chaotic input.
///
/// These tests push the formatter to its limits with:
/// - Extreme whitespace chaos (tabs, spaces, multiple blank lines)
/// - Deeply nested structures (10+ levels)
/// - Attribute soup (many attributes mixed together)
/// - Mixed directive chaos
/// - Unicode and special characters
/// - Pathological edge cases
void main() {
  group('Formatter Stress Tests', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('Whitespace Nightmare', () {
      test('handles extreme leading whitespace', () {
        const input = '''


        <div>
                            <p>Content</p>
        </div>
''';
        final result = formatter.format(input);
        expect(result, contains('<div>'));
        expect(result, contains('<p>Content</p>'));
        // Should normalize indentation
        expect(result, isNot(contains('                    ')));
      });

      test('handles mixed tabs and spaces chaos', () {
        const input =
            '<div\t  \t class="test"\t\t\tid="main"   \t>\n\t  \t<p\t  >Content\t\t</p\t>\n</div>';

        final result = formatter.format(input);
        expect(result, contains('class="test"'));
        expect(result, contains('id="main"'));
        // Should produce clean output
        expect(result, isNot(contains('\t')));
      });

      test('handles multiple consecutive blank lines', () {
        const input = '''
<div>





<p>Content</p>



</div>
''';
        final result = formatter.format(input);
        expect(result, contains('<div>'));
        expect(result, contains('</div>'));
        // Should not have excessive blank lines
        expect(result.split('\n\n\n').length, lessThan(3));
      });

      test('handles trailing whitespace everywhere', () {
        const input =
            '<div class="test"   >   \n    <p>Content</p>   \n</div>   ';

        final result = formatter.format(input);
        // Lines should not end with spaces (except possibly inside strings)
        final lines = result.split('\n');
        for (final line in lines) {
          if (!line.contains('"') && !line.contains("'")) {
            expect(line, equals(line.trimRight()));
          }
        }
      });

      test('handles CRLF mixed with LF', () {
        const input = '<div>\r\n<p>Line 1</p>\n<p>Line 2</p>\r\n</div>';

        final result = formatter.format(input);
        // Output should be normalized to LF
        expect(result, isNot(contains('\r')));
        expect(result, contains('\n'));
      });

      test('handles no whitespace between elements', () {
        const input =
            '<div><p>One</p><p>Two</p><span>Three</span><strong>Four</strong></div>';

        final result = formatter.format(input);
        expect(result, contains('One'));
        expect(result, contains('Two'));
        expect(result, contains('Three'));
        expect(result, contains('Four'));
      });

      test('handles excessive whitespace inside echo', () {
        const input = '{{            \$variable              }}';

        final result = formatter.format(input);
        expect(result, contains('{{ \$variable }}'));
      });

      test('handles whitespace around directive arguments', () {
        const input =
            '@if(     \$condition     &&     \$other     )\n<p>Yes</p>\n@endif';

        final result = formatter.format(input);
        expect(result, contains('@if'));
        expect(result, contains('@endif'));
        expect(result, isNot(contains('@endelse')));
        final lines =
            result.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final ifLine = lines.firstWhere((l) => l.contains('@if'));
        final endifLine = lines.firstWhere((l) => l.contains('@endif'));
        final ifIndent = ifLine.length - ifLine.trimLeft().length;
        final endifIndent = endifLine.length - endifLine.trimLeft().length;
        expect(ifIndent, equals(endifIndent));
      });
    });

    group('Deeply Nested Structures', () {
      test('handles 10 levels of HTML nesting', () {
        const input = '''
<div>
<section>
<article>
<main>
<aside>
<nav>
<header>
<footer>
<figure>
<figcaption>
<p>Deep content</p>
</figcaption>
</figure>
</footer>
</header>
</nav>
</aside>
</main>
</article>
</section>
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('<div>'));
        expect(result, contains('<p>Deep content</p>'));
        expect(result, contains('</div>'));
        // Should have proper indentation
        expect(
            result,
            contains(
                '                                        <p>Deep content</p>'));
      });

      test('handles 10 levels of directive nesting', () {
        const input = '''
@if(\$a)
@if(\$b)
@if(\$c)
@if(\$d)
@if(\$e)
@foreach(\$items as \$item)
@if(\$item->active)
@can('view', \$item)
@isset(\$item->data)
@unless(\$item->hidden)
<p>{{ \$item->name }}</p>
@endunless
@endisset
@endcan
@endif
@endforeach
@endif
@endif
@endif
@endif
@endif
''';
        final result = formatter.format(input);
        expect(result, contains('@if(\$a)'));
        expect(result, contains('@endunless'));
        expect(result, contains('{{ \$item->name }}'));
        // Check the deepest content has maximum indentation
        expect(result, contains('<p>'));
      });

      test('handles mixed HTML and directive deep nesting', () {
        const input = '''
<div>
@if(\$show)
<section>
@foreach(\$items as \$item)
<article>
@if(\$item->published)
<div>
@can('edit', \$item)
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
        final result = formatter.format(input);
        expect(result, contains('<div>'));
        expect(result, contains('    @if(\$show)'));
        expect(result, contains('        <section>'));
      });

      test('handles nested components with slots', () {
        const input = '''
<x-card>
<x-slot:header>
<x-icon name="star" />
<x-slot:title>
<h2>Nested Slot</h2>
</x-slot>
</x-slot>
<x-card>
<x-slot:body>
<p>Inner card content</p>
</x-slot>
</x-card>
</x-card>
''';
        final result = formatter.format(input);
        expect(result, contains('<x-card>'));
        expect(result, contains('<x-slot:header>'));
        expect(result, contains('<x-slot:title>'));
      });
    });

    group('Attribute Soup', () {
      test('handles element with 20+ attributes', () {
        const input = '''
<input type="text" id="user-email" name="email" class="form-control input-lg" placeholder="Enter email" required disabled readonly autofocus autocomplete="email" maxlength="255" minlength="5" pattern="[a-z]+" title="Email address" data-validate="email" data-error-message="Invalid email" wire:model.live="email" wire:loading.class="opacity-50" x-on:input="validateEmail" x-bind:class="{ 'error': hasError }" @keyup.enter="submit" :disabled="isLoading">
''';
        final result = formatter.format(input);
        expect(result, contains('type="text"'));
        expect(result, contains('wire:model.live'));
        expect(result, contains('x-on:input'));
        expect(result, contains('@keyup.enter'));
      });

      test('handles mixed attribute types in chaotic order', () {
        const input = '''
<div wire:click="save" class="btn" @click="handle" id="main" data-testid="button" x-show="visible" :class="{'active': isActive}" wire:loading.attr="disabled" x-data="{}" data-tooltip="Help" @mouseenter="hover=true" wire:target="save" x-transition:enter="fade" style="color: red">
Content
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('wire:click'));
        expect(result, contains('class="btn"'));
        expect(result, contains('@click'));
        expect(result, contains('x-show'));
      });

      test('handles attributes with complex values', () {
        const input = '''
<div
x-data="{ open: false, items: [1, 2, 3], config: { nested: { deep: true } } }"
x-init="\$watch('open', value => console.log(value))"
@click="handleClick(\$event, { option: 'value', callback: () => console.log('done') })"
:class="{ 'bg-red-500': error, 'bg-green-500': success, 'bg-gray-100': !error && !success }"
wire:click="process(['item1', 'item2'], { merge: true })"
data-config='{"key": "value", "array": [1,2,3], "nested": {"a": "b"}}'>
Content
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('x-data'));
        expect(result, contains('x-init'));
        expect(result, contains('data-config'));
      });

      test('handles attributes with Blade expressions', () {
        const input = '''
<button
class="{{ \$isPrimary ? 'btn-primary' : 'btn-secondary' }} {{ \$size }}"
id="{{ \$component->id }}-btn"
data-user="{{ json_encode(\$user->toArray()) }}"
wire:click="\$emit('{{ \$eventName }}', {{ \$eventData }})"
@click="handleClick({{ \$jsConfig }})"
:disabled="{{ \$isDisabled ? 'true' : 'false' }}">
{{ \$label }}
</button>
''';
        final result = formatter.format(input);
        expect(result, contains('class="'));
        expect(result, contains('wire:click'));
        expect(result, contains('{{ \$label }}'));
      });
    });

    group('Mixed Content Chaos', () {
      test('handles interleaved text, echoes, and HTML', () {
        const input = '''
<p>Hello {{ \$user->name }}, you have <strong>{{ \$count }}</strong> messages from {{ \$sender }} in your <a href="{{ \$url }}">inbox</a> since {{ \$date }}.</p>
''';
        final result = formatter.format(input);
        expect(result, contains('Hello'));
        expect(result, contains('{{ \$user->name }}'));
        expect(result, contains('{{ \$count }}'));
        expect(result, contains('<strong>'));
        expect(result, contains('<a href='));
      });

      test('handles Blade comments mixed with HTML comments', () {
        const input = '''
{{-- Blade comment --}}
<!-- HTML comment -->
<div>
{{-- Another Blade comment --}}
<p>Content</p>
<!-- Another HTML comment -->
</div>
{{-- Final comment --}}
''';
        final result = formatter.format(input);
        expect(result, contains('{{-- Blade comment --}}'));
        expect(result, contains('<!-- HTML comment -->'));
        expect(result, contains('{{-- Another Blade comment --}}'));
      });

      test('handles all echo types mixed together', () {
        const input = '''
<div>
{{ \$escaped }}
{!! \$unescaped !!}
{{ \$another }}
{!! \$more !!}
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('{{ \$escaped }}'));
        expect(result, contains('{!! \$unescaped !!}'));
        expect(result, contains('{{ \$another }}'));
        expect(result, contains('{!! \$more !!}'));
      });

      test('handles form with all input types', () {
        const input = '''
<form method="POST" action="/submit" enctype="multipart/form-data">
@csrf
@method('PUT')
<input type="text" name="name" value="{{ old('name') }}">
<input type="email" name="email" wire:model="email">
<input type="password" name="password">
<input type="number" name="age" min="0" max="120">
<input type="checkbox" name="agree" @checked(\$agreed)>
<input type="radio" name="gender" value="m">
<input type="file" name="avatar" accept="image/*">
<input type="hidden" name="user_id" value="{{ \$user->id }}">
<select name="country" wire:model="country">
@foreach(\$countries as \$country)
<option value="{{ \$country->code }}" @selected(\$country->code === \$selected)>{{ \$country->name }}</option>
@endforeach
</select>
<textarea name="bio" rows="5">{{ old('bio') }}</textarea>
<button type="submit" wire:loading.attr="disabled">Submit</button>
</form>
''';
        final result = formatter.format(input);
        expect(result, contains('@csrf'));
        expect(result, contains('@method'));
        expect(result, contains('wire:model'));
        expect(result, contains('@checked'));
        expect(result, contains('@selected'));
      });

      test('handles table with complex structure', () {
        const input = '''
<table class="table" wire:poll.5s>
<caption>{{ \$tableTitle }}</caption>
<thead>
<tr>
@foreach(\$headers as \$header)
<th wire:click="sortBy('{{ \$header->key }}')">{{ \$header->label }}</th>
@endforeach
</tr>
</thead>
<tbody>
@forelse(\$rows as \$row)
<tr wire:key="{{ \$row->id }}" class="{{ \$loop->even ? 'bg-gray-50' : '' }}">
<td>{{ \$row->name }}</td>
<td>{{ \$row->email }}</td>
<td>
<x-dropdown>
<x-slot:trigger>
<button>Actions</button>
</x-slot>
<x-dropdown-item wire:click="edit({{ \$row->id }})">Edit</x-dropdown-item>
</x-dropdown>
</td>
</tr>
@empty
<tr>
<td colspan="3">No data available</td>
</tr>
@endforelse
</tbody>
</table>
''';
        final result = formatter.format(input);
        expect(result, contains('<table'));
        expect(result, contains('<thead>'));
        expect(result, contains('<tbody>'));
        expect(result, contains('@forelse'));
        expect(result, contains('@empty'));
        expect(result, isNot(contains('@endempty')));
        expect(result, isNot(contains('@endcase')));
        expect(result, isNot(contains('@enddefault')));
        expect(result, contains('<x-dropdown>'));
      });
    });

    group('Unicode and Special Characters', () {
      test('handles emoji in content', () {
        const input = '<p>Hello {{ \$name }}! 👋 Welcome to our app 🎉</p>';

        final result = formatter.format(input);
        expect(result, contains('👋'));
        expect(result, contains('🎉'));
      });

      test('handles RTL text', () {
        const input =
            '<p dir="rtl">مرحبا {{ \$name }} - שלום {{ \$greeting }}</p>';

        final result = formatter.format(input);
        expect(result, contains('مرحبا'));
        expect(result, contains('שלום'));
        expect(result, contains('dir="rtl"'));
      });

      test('handles Chinese/Japanese characters', () {
        const input = '''
<div>
<h1>{{ \$title }} - 欢迎光临</h1>
<p>こんにちは、{{ \$user->name }}さん</p>
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('欢迎光临'));
        expect(result, contains('こんにちは'));
      });

      test('handles special HTML entities', () {
        const input =
            '<p>Price: &euro;{{ \$price }} &mdash; Tax: &pound;{{ \$tax }} &copy; {{ date("Y") }}</p>';

        final result = formatter.format(input);
        expect(result, contains('&euro;'));
        expect(result, contains('&mdash;'));
        expect(result, contains('&pound;'));
        expect(result, contains('&copy;'));
      });

      test('handles combining characters', () {
        const input = '<p>Café résumé naïve {{ \$text }}</p>';

        final result = formatter.format(input);
        expect(result, contains('Café'));
        expect(result, contains('résumé'));
        expect(result, contains('naïve'));
      });
    });

    group('Pathological Cases', () {
      test('handles element with only whitespace content', () {
        const input = '<div>     \n\t\t\n    </div>';

        final result = formatter.format(input);
        expect(result, contains('<div>'));
        expect(result, contains('</div>'));
      });

      test('handles many consecutive self-closing tags', () {
        const input = '''
<br><br><br><hr><hr><img src="a.jpg"><img src="b.jpg"><input type="text"><input type="email">
''';
        final result = formatter.format(input);
        expect(result, contains('<br>'));
        expect(result, contains('<hr>'));
        expect(result, contains('<img'));
        expect(result, contains('<input'));
      });

      test('handles directive at start of attribute value context', () {
        const input =
            '<div class="@if(\$active)active @endif base">Content</div>';

        final result = formatter.format(input);
        expect(result, contains('class='));
        expect(result, contains('Content'));
      });

      test('handles multiple @@ escapes', () {
        const input =
            '<p>Email: @@test@@example.com and @@another@@domain.org</p>';

        final result = formatter.format(input);
        // @@ escapes are converted to single @ by the parser/formatter
        expect(result, contains('@test@example.com'));
        expect(result, contains('@another@domain.org'));
      });

      test('handles @{{ escaped echo }}', () {
        const input =
            '<p>Vue syntax: @{{ message }} and Blade: {{ \$message }}</p>';

        final result = formatter.format(input);
        expect(result, contains('@{{ message }}'));
        expect(result, contains('{{ \$message }}'));
      });

      test('handles extremely long single line', () {
        final longClass = 'class-' * 100;
        final input = '<div class="$longClass">Content</div>';

        final result = formatter.format(input);
        expect(result, contains('Content'));
        expect(result, contains('</div>'));
      });

      test('handles empty template', () {
        const input = '';

        final result = formatter.format(input);
        // Empty input produces empty output
        expect(result, equals(''));
      });

      test('handles whitespace-only template', () {
        const input = '   \n\t\t\n   \n';

        final result = formatter.format(input);
        expect(result, isNotNull);
      });

      test('handles nested quotes in attributes', () {
        const input = '''
<div
x-data="{ message: 'Hello \"World\"' }"
data-json='{"key": "value with \\'quotes\\'"}'
onclick="alert(&quot;Hello&quot;)">
Content
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('x-data'));
        expect(result, contains('data-json'));
        expect(result, contains('onclick'));
      });

      test('best-effort formats unclosed tags', () {
        const input = '<div><p>Unclosed paragraph<div>Another unclosed</div>';

        const expected = '''
<div>
    <p>
        Unclosed paragraph
        <div>Another unclosed</div>
    </p>
</div>
''';

        expect(formatter.format(input), expected);
      });

      test('best-effort repairs mismatched tags', () {
        const input = '<div><span>Text</div></span>';

        expect(
            formatter.format(input), '<div><span>Text</span></div>\n</span>\n');
      });

      test('best-effort preserves stray closing tags as RecoveryNodes', () {
        const input = '<div><span>Text</bogus>More</span></div>';

        expect(
          formatter.format(input),
          '<div>\n    <span>\n        Text</bogus>More\n    </span>\n</div>\n',
        );
      });

      test('best-effort preserves malformed tag-head chunks', () {
        const input = '<div class="base" ??? data-x="1"></div>';
        const expected = '''
<div
    class="base"
    ???
    data-x="1"></div>
''';

        expect(formatter.format(input), expected);
      });
    });

    group('Real World Messy Code', () {
      test('handles poorly indented dashboard template', () {
        const input = '''
<div class="dashboard">
@auth
<nav>
      @foreach(\$menu as \$item)
   <a href="{{ \$item->url }}">{{ \$item->label }}</a>
         @endforeach
                                </nav>
@endauth
  <main>
                @if(\$showStats)
<x-stats-widget :data="\$stats" />
            @endif
        @foreach(\$widgets as \$widget)
   <x-dynamic-component :component="\$widget->type" :data="\$widget->data" />
            @endforeach
      </main>
    @guest
<div class="cta">
<h2>Sign up today!</h2>
<x-button href="/register">Get Started</x-button>
</div>
            @endguest
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('<div class="dashboard">'));
        expect(result, contains('@auth'));
        expect(result, contains('@foreach'));
        expect(result, contains('@guest'));
        // Should have proper indentation now
        expect(
            result, isNot(contains('                                </nav>')));
      });

      test('handles messy Livewire component template', () {
        const input = '''
<div wire:poll.5s  wire:loading.class="opacity-50"     wire:init="loadData">
   @if(\$loading)
<x-spinner />
         @else
<div class="grid grid-cols-3 gap-4">
   @forelse(\$items as \$item)
            <div wire:key="{{ \$item->id }}"
   wire:click="select({{ \$item->id }})"
                 class="{{ \$selected === \$item->id ? 'ring-2' : '' }}"
            >
      <img src="{{ \$item->image }}"  loading="lazy">
         <h3>{{   \$item->title   }}</h3>
<p>{!!   \$item->excerpt   !!}</p>
                  </div>
            @empty
<p   class="col-span-3 text-center"  >No items found</p>
         @endforelse
   </div>
@endif
</div>
''';
        final result = formatter.format(input);
        expect(result, contains('wire:poll.5s'));
        expect(result, contains('wire:loading.class'));
        expect(result, contains('@forelse'));
        expect(result, contains('@empty'));
        expect(result, isNot(contains('@endempty')));
        expect(result, isNot(contains('@endelse')));
        // Echo spacing should be normalized
        expect(result, contains('{{ \$item->title }}'));
      });

      test('handles copy-pasted code with inconsistent style', () {
        const input = '''
<div class='container'>
  <h1>Page Title</h1>
</div>
<div class="container">
    <h1>Page Title</h1>
</div>
<div class=container>
<h1>Page Title</h1>
</div>
@if(\$show)
<p>One style</p>
@endif
@if( \$show )
    <p>Another style</p>
@endif
@if(\$show)<p>Inline style</p>@endif
''';
        final result = formatter.format(input);
        expect(result, contains('<div'));
        expect(result, contains('<h1>'));
        expect(result, contains('@if'));
      });
    });

    group('Idempotency Under Stress', () {
      test('formatting noisy input twice produces same result', () {
        const messyInput = '''
<div    class="test"   >
         @if(  \$condition  )
   <p>   {{   \$value   }}   </p>
            @endif
   </div>
''';
        final firstPass = formatter.format(messyInput);
        final secondPass = formatter.format(firstPass);

        expect(firstPass, equals(secondPass));
      });

      test('deeply nested formatting is idempotent', () {
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
        final firstPass = formatter.format(input);
        final secondPass = formatter.format(firstPass);
        final thirdPass = formatter.format(secondPass);

        expect(firstPass, equals(secondPass));
        expect(secondPass, equals(thirdPass));
      });

      test('attribute-heavy formatting is idempotent', () {
        const input = '''
<button type="submit" class="btn btn-primary" wire:click="save" wire:loading.attr="disabled" x-on:click="handleClick" :disabled="isLoading" data-action="save">
Save
</button>
''';
        final firstPass = formatter.format(input);
        final secondPass = formatter.format(firstPass);

        expect(firstPass, equals(secondPass));
      });
    });

    group('Performance Under Load', () {
      test('handles 100 elements without timeout', () {
        final elements = List.generate(
                100, (i) => '<div class="item-$i"><p>Content $i</p></div>')
            .join('\n');
        final input = '<div class="container">$elements</div>';

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input);
        stopwatch.stop();

        expect(result, contains('<div class="container">'));
        expect(result, contains('item-99'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('handles 50 nested directives', () {
        var input = '';
        for (var i = 0; i < 50; i++) {
          input += '@if(\$level$i)\n';
        }
        input += '<p>Deep content</p>\n';
        for (var i = 49; i >= 0; i--) {
          input += '@endif\n';
        }

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input);
        stopwatch.stop();

        expect(result, contains('@if(\$level0)'));
        expect(result, contains('Deep content'));
        expect(result, contains('<p>'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('handles element with 100 attributes', () {
        final attrs =
            List.generate(100, (i) => 'data-attr-$i="value$i"').join(' ');
        final input = '<div $attrs>Content</div>';

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input);
        stopwatch.stop();

        expect(result, contains('data-attr-0'));
        expect(result, contains('data-attr-99'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });
  });
}
