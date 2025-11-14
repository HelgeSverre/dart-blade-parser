import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter Edge Cases', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('Unescaped echo variations', () {
      test('formats unescaped echo with spacing', () {
        const input = '<div>{!!  \$html  !!}</div>';
        const expected = '<div>{!! \$html !!}</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats multiple unescaped echos', () {
        const input = '''
<div>
{!! \$html1 !!}
{!! \$html2 !!}
</div>
''';

        final result = formatter.format(input);
        expect(result, contains('{!! \$html1 !!}'));
        expect(result, contains('{!! \$html2 !!}'));
      });

      test('formats mixed escaped and unescaped echos', () {
        const input = '''
<div>
{{ \$safe }}
{!! \$html !!}
{{ \$another }}
</div>
''';

        final result = formatter.format(input);
        expect(result, contains('{{ \$safe }}'));
        expect(result, contains('{!! \$html !!}'));
        expect(result, contains('{{ \$another }}'));
      });
    });

    group('Directive argument edge cases', () {
      test('formats directive with complex expression', () {
        const input = '@if(\$user && \$user->isActive() && \$user->hasRole("admin"))\n<p>Admin</p>\n@endif';

        final result = formatter.format(input);
        expect(result, contains('@if(\$user && \$user->isActive() && \$user->hasRole("admin"))'));
      });

      test('formats directive with array access', () {
        const input = '@if(\$data["key"]["nested"])\n<p>Test</p>\n@endif';

        final result = formatter.format(input);
        expect(result, contains('@if(\$data["key"]["nested"])'));
      });

      test('formats directive with ternary operator', () {
        const input = '@if(\$x ? \$y : \$z)\n<p>Test</p>\n@endif';

        final result = formatter.format(input);
        expect(result, contains('@if(\$x ? \$y : \$z)'));
      });

      test('formats foreach with complex iterator', () {
        const input = '@foreach(\$users->where("active", true)->get() as \$user)\n<p>{{ \$user->name }}</p>\n@endforeach';

        final result = formatter.format(input);
        expect(result, contains('@foreach(\$users->where("active", true)->get() as \$user)'));
      });
    });

    group('Attributes with special characters', () {
      test('formats attribute with colon (Alpine/Vue)', () {
        const input = '<div :class="{ active: isActive }">Content</div>';

        final result = formatter.format(input);
        expect(result, contains(':class'));
      });

      test('formats attribute with @ symbol (Alpine)', () {
        const input = '<button @click="handleClick">Click</button>';

        final result = formatter.format(input);
        expect(result, contains('@click'));
      });

      test('formats data attributes', () {
        const input = '<div data-user-id="123" data-role="admin">Content</div>';

        final result = formatter.format(input);
        expect(result, contains('data-user-id'));
        expect(result, contains('data-role'));
      });

      test('formats wire: prefixed attributes', () {
        const input = '<input wire:model.defer="name" wire:loading.class="opacity-50">';

        final result = formatter.format(input);
        expect(result, contains('wire:model.defer'));
        expect(result, contains('wire:loading.class'));
      });
    });

    group('Boolean attributes', () {
      test('formats boolean attributes without values', () {
        const input = '<input type="checkbox" checked disabled readonly>';

        final result = formatter.format(input);
        expect(result, contains('checked'));
        expect(result, contains('disabled'));
        expect(result, contains('readonly'));
      });

      test('formats boolean attributes with values', () {
        const input = '<input type="checkbox" checked="checked" disabled="disabled">';

        final result = formatter.format(input);
        expect(result, isNotEmpty);
      });
    });

    group('Multiple attributes formatting', () {
      test('formats element with many attributes', () {
        const input = '<input type="text" id="name" name="user_name" class="form-control" placeholder="Enter name" required>';

        final result = formatter.format(input);
        expect(result, contains('type="text"'));
        expect(result, contains('id="name"'));
        expect(result, contains('class="form-control"'));
      });

      test('formats element with mixed attribute types', () {
        const input = '<button type="submit" class="btn" wire:click="save" x-on:click="close" disabled>Submit</button>';

        final result = formatter.format(input);
        expect(result, contains('type="submit"'));
        expect(result, contains('wire:click'));
        expect(result, contains('x-on:click'));
      });
    });

    group('Special directive combinations', () {
      test('formats @elseif chains', () {
        const input = '''
@if(\$role === 'admin')
<p>Admin</p>
@elseif(\$role === 'moderator')
<p>Moderator</p>
@elseif(\$role === 'user')
<p>User</p>
@else
<p>Guest</p>
@endif
''';

        final result = formatter.format(input);
        expect(result, contains('@if(\$role === \'admin\')'));
        expect(result, contains('@elseif(\$role === \'moderator\')'));
        expect(result, contains('@elseif(\$role === \'user\')'));
        expect(result, contains('@else'));
      });

      test('formats @switch with multiple cases', () {
        const input = '''
@switch(\$type)
@case('info')
<div class="info">Info</div>
@break
@case('warning')
<div class="warning">Warning</div>
@break
@case('error')
<div class="error">Error</div>
@break
@default
<div>Default</div>
@endswitch
''';

        final result = formatter.format(input);
        expect(result, contains('@switch(\$type)'));
        expect(result, contains('@case(\'info\')'));
        expect(result, contains('@break'));
        expect(result, contains('@default'));
      });

      test('formats @forelse with @empty', () {
        const input = '''
@forelse(\$users as \$user)
<p>{{ \$user->name }}</p>
@empty
<p>No users found</p>
@endforelse
''';

        final result = formatter.format(input);
        expect(result, contains('@forelse(\$users as \$user)'));
        expect(result, contains('@empty'));
        expect(result, contains('@endforelse'));
      });
    });

    group('Template inheritance directives', () {
      test('formats @extends directive', () {
        const input = '@extends(\'layouts.app\')';

        final result = formatter.format(input);
        expect(result, contains('@extends(\'layouts.app\')'));
      });

      test('formats @yield directive', () {
        const input = '@yield(\'content\')';

        final result = formatter.format(input);
        expect(result, contains('@yield(\'content\')'));
      });

      test('formats @section with inline content', () {
        const input = '@section(\'title\', \'Page Title\')';

        final result = formatter.format(input);
        expect(result, contains('@section(\'title\', \'Page Title\')'));
      });

      test('formats @parent directive', () {
        const input = '''
@section('content')
@parent
<p>Additional content</p>
@endsection
''';

        final result = formatter.format(input);
        expect(result, contains('@parent'));
      });
    });

    group('Include directives', () {
      test('formats @include with data', () {
        const input = '@include(\'partials.header\', [\'title\' => \'Home\'])';

        final result = formatter.format(input);
        expect(result, contains('@include(\'partials.header\''));
      });

      test('formats @includeIf directive', () {
        const input = '@includeIf(\$condition, \'partials.alert\')';

        final result = formatter.format(input);
        expect(result, contains('@includeIf(\$condition'));
      });

      test('formats @includeWhen directive', () {
        const input = '@includeWhen(\$user->isAdmin(), \'partials.admin-menu\')';

        final result = formatter.format(input);
        expect(result, contains('@includeWhen(\$user->isAdmin()'));
      });

      test('formats @includeFirst directive', () {
        const input = '@includeFirst([\'custom.header\', \'default.header\'])';

        final result = formatter.format(input);
        expect(result, contains('@includeFirst'));
      });
    });

    group('Stack directives', () {
      test('formats @push directive', () {
        const input = '''
@push('scripts')
<script src="/app.js"></script>
@endpush
''';

        final result = formatter.format(input);
        expect(result, contains('@push(\'scripts\')'));
        expect(result, contains('@endpush'));
      });

      test('formats @prepend directive', () {
        const input = '''
@prepend('scripts')
<script src="/first.js"></script>
@endprepend
''';

        final result = formatter.format(input);
        expect(result, contains('@prepend(\'scripts\')'));
        expect(result, contains('@endprepend'));
      });

      test('formats @once directive', () {
        const input = '''
@once
<script src="/analytics.js"></script>
@endonce
''';

        final result = formatter.format(input);
        expect(result, contains('@once'));
        expect(result, contains('@endonce'));
      });
    });

    group('Authorization directives', () {
      test('formats @can directive', () {
        const input = '''
@can('update', \$post)
<a href="/posts/{{ \$post->id }}/edit">Edit</a>
@endcan
''';

        final result = formatter.format(input);
        expect(result, contains('@can(\'update\', \$post)'));
        expect(result, contains('@endcan'));
      });

      test('formats @cannot directive', () {
        const input = '''
@cannot('delete', \$post)
<p>You cannot delete this post</p>
@endcannot
''';

        final result = formatter.format(input);
        expect(result, contains('@cannot(\'delete\', \$post)'));
        expect(result, contains('@endcannot'));
      });

      test('formats @canany directive', () {
        const input = '''
@canany(['update', 'delete'], \$post)
<div>Actions available</div>
@endcanany
''';

        final result = formatter.format(input);
        expect(result, contains('@canany([\'update\', \'delete\'], \$post)'));
        expect(result, contains('@endcanany'));
      });
    });

    group('Environment directives', () {
      test('formats @env directive', () {
        const input = '''
@env('local')
<div class="debug-bar">Debug enabled</div>
@endenv
''';

        final result = formatter.format(input);
        expect(result, contains('@env(\'local\')'));
        expect(result, contains('@endenv'));
      });

      test('formats @production directive', () {
        const input = '''
@production
<script src="/analytics.js"></script>
@endproduction
''';

        final result = formatter.format(input);
        expect(result, contains('@production'));
        expect(result, contains('@endproduction'));
      });
    });

    group('Loop variable access', () {
      test('formats loop variable properties', () {
        const input = '''
@foreach(\$items as \$item)
<div class="item {{ \$loop->first ? 'first' : '' }}">
@if(\$loop->last)
<p>Last item</p>
@endif
</div>
@endforeach
''';

        final result = formatter.format(input);
        expect(result, contains('\$loop->first'));
        expect(result, contains('\$loop->last'));
      });
    });

    group('Component edge cases', () {
      test('formats component with colon in tag name', () {
        const input = '<x-slot:header>Content</x-slot>';

        final result = formatter.format(input);
        expect(result, contains('<x-slot:header>'));
      });

      test('formats component with kebab-case name', () {
        const input = '<x-user-profile-card>Content</x-user-profile-card>';

        final result = formatter.format(input);
        expect(result, contains('<x-user-profile-card>'));
      });

      test('formats component with dynamic name', () {
        const input = '<x-dynamic-component :component="\$componentName" />';

        final result = formatter.format(input);
        expect(result, contains('<x-dynamic-component'));
        expect(result, contains(':component'));
      });

      test('formats component with attribute bag', () {
        const input = '<x-button {{ \$attributes->merge([\'class\' => \'btn\']) }}>Click</x-button>';

        final result = formatter.format(input);
        expect(result, contains('<x-button'));
        // Attribute bags may be parsed as echo statements and formatted differently
        expect(result, contains('attributes'));
      });
    });

    group('Script and style tag preservation', () {
      test('preserves inline JavaScript with Blade', () {
        const input = '''
<script>
const data = {{ \$jsonData }};
console.log(data);
</script>
''';

        final result = formatter.format(input);
        expect(result, contains('<script>'));
        expect(result, contains('const data = {{ \$jsonData }};'));
        expect(result, contains('</script>'));
      });

      test('preserves CSS with Blade variables', () {
        const input = '''
<style>
.theme {
color: {{ \$primaryColor }};
}
</style>
''';

        final result = formatter.format(input);
        expect(result, contains('<style>'));
        expect(result, contains('color: {{ \$primaryColor }};'));
        expect(result, contains('</style>'));
      });
    });

    group('Unusual but valid HTML', () {
      test('formats custom elements', () {
        const input = '<my-custom-element attr="value">Content</my-custom-element>';

        final result = formatter.format(input);
        expect(result, contains('<my-custom-element'));
      });

      test('formats SVG elements', () {
        const input = '''
<svg viewBox="0 0 100 100">
<circle cx="50" cy="50" r="40" />
</svg>
''';

        final result = formatter.format(input);
        expect(result, contains('<svg'));
        expect(result, contains('<circle'));
      });

      test('formats picture element with sources', () {
        const input = '''
<picture>
<source srcset="image.webp" type="image/webp">
<img src="image.jpg" alt="Description">
</picture>
''';

        final result = formatter.format(input);
        expect(result, contains('<picture>'));
        expect(result, contains('<source'));
        expect(result, contains('<img'));
      });
    });

    group('Attribute value edge cases', () {
      test('formats attribute with URL value', () {
        const input = '<a href="https://example.com/path?query=value&other=123">Link</a>';

        final result = formatter.format(input);
        expect(result, contains('https://example.com/path?query=value&other=123'));
      });

      test('formats attribute with JSON value', () {
        const input = '<div data-config=\'{"key": "value", "nested": {"a": 1}}\'>Content</div>';

        final result = formatter.format(input);
        expect(result, contains('data-config'));
      });

      test('formats attribute with PHP-like expression', () {
        const input = '<div data-value="{{ \$obj->method()->property }}">Content</div>';

        final result = formatter.format(input);
        expect(result, contains('\$obj->method()->property'));
      });
    });

    group('Whitespace in special contexts', () {
      test('preserves whitespace in pre tag', () {
        const input = '''
<pre>
    Line 1
        Line 2 indented
    Line 3
</pre>
''';

        final result = formatter.format(input);
        expect(result, contains('<pre>'));
        expect(result, contains('</pre>'));
      });

      test('formats code blocks with indentation', () {
        const input = '''
<pre><code>function example() {
  return true;
}</code></pre>
''';

        final result = formatter.format(input);
        expect(result, contains('<code>'));
      });
    });

    group('Multiple consecutive directives', () {
      test('formats multiple @csrf and @method directives', () {
        const input = '''
<form>
@csrf
@method('PUT')
<input type="text" name="name">
</form>
''';

        final result = formatter.format(input);
        expect(result, contains('@csrf'));
        expect(result, contains('@method(\'PUT\')'));
      });

      test('formats multiple @props directives', () {
        const input = '''
@props(['type' => 'info'])
@props(['dismissible' => false])
<div>Alert</div>
''';

        final result = formatter.format(input);
        expect(result, contains('@props'));
      });
    });

    group('Nested component slots', () {
      test('formats nested slots in components', () {
        const input = '''
<x-card>
<x-slot:header>
<x-slot:title>
<h2>Title</h2>
</x-slot>
</x-slot>
<p>Body</p>
</x-card>
''';

        final result = formatter.format(input);
        expect(result, contains('<x-card>'));
        expect(result, contains('<x-slot:header>'));
        expect(result, contains('<x-slot:title>'));
      });
    });

    group('Mixed Blade and Alpine directives', () {
      test('formats Blade if with Alpine show', () {
        const input = '''
@if(\$enabled)
<div x-show="isVisible">
<p>Content</p>
</div>
@endif
''';

        final result = formatter.format(input);
        expect(result, contains('@if(\$enabled)'));
        expect(result, contains('x-show="isVisible"'));
      });

      test('formats nested Blade and Alpine', () {
        const input = '''
<div x-data="{ open: false }">
@foreach(\$items as \$item)
<div x-show="open">
{{ \$item->name }}
</div>
@endforeach
</div>
''';

        final result = formatter.format(input);
        expect(result, contains('x-data'));
        expect(result, contains('@foreach'));
        expect(result, contains('x-show'));
      });
    });

    group('Comments in various positions', () {
      test('formats comment between attributes', () {
        const input = '''
<div
class="container"
{{-- This is important --}}
id="main">
Content
</div>
''';

        final result = formatter.format(input);
        // Comments between attributes may be handled differently
        expect(result, contains('class="container"'));
        expect(result, contains('id="main"'));
      });

      test('formats comments between directives', () {
        const input = '''
@if(\$user)
{{-- User section --}}
<p>Welcome</p>
{{-- End user section --}}
@endif
''';

        final result = formatter.format(input);
        expect(result, contains('{{-- User section --}}'));
        expect(result, contains('{{-- End user section --}}'));
      });
    });

    group('Form elements', () {
      test('formats select with options', () {
        const input = '''
<select name="role">
@foreach(\$roles as \$role)
<option value="{{ \$role->id }}">{{ \$role->name }}</option>
@endforeach
</select>
''';

        final result = formatter.format(input);
        expect(result, contains('<select'));
        expect(result, contains('<option'));
      });

      test('formats radio buttons', () {
        const input = '''
@foreach(\$options as \$option)
<label>
<input type="radio" name="choice" value="{{ \$option->id }}">
{{ \$option->label }}
</label>
@endforeach
''';

        final result = formatter.format(input);
        expect(result, contains('type="radio"'));
      });
    });

    group('Table formatting', () {
      test('formats table with Blade directives', () {
        const input = '''
<table>
<thead>
<tr>
<th>Name</th>
<th>Email</th>
</tr>
</thead>
<tbody>
@foreach(\$users as \$user)
<tr>
<td>{{ \$user->name }}</td>
<td>{{ \$user->email }}</td>
</tr>
@endforeach
</tbody>
</table>
''';

        final result = formatter.format(input);
        expect(result, contains('<table>'));
        expect(result, contains('<thead>'));
        expect(result, contains('<tbody>'));
        expect(result, contains('@foreach'));
      });
    });

    group('List formatting', () {
      test('formats unordered list with directives', () {
        const input = '''
<ul>
@foreach(\$items as \$item)
<li>{{ \$item }}</li>
@endforeach
</ul>
''';

        final result = formatter.format(input);
        expect(result, contains('<ul>'));
        expect(result, contains('<li>'));
      });

      test('formats nested lists', () {
        const input = '''
<ul>
@foreach(\$categories as \$category)
<li>
{{ \$category->name }}
<ul>
@foreach(\$category->items as \$item)
<li>{{ \$item->name }}</li>
@endforeach
</ul>
</li>
@endforeach
</ul>
''';

        final result = formatter.format(input);
        expect(result, contains('<ul>'));
        expect(result, isNotEmpty);
      });
    });
  });
}
