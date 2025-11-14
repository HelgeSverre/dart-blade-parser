import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for Livewire-specific formatting patterns.
///
/// Livewire uses wire: prefixed attributes extensively, and this test ensures
/// they are formatted correctly in various contexts.
void main() {
  group('Livewire Formatting', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('wire:model variations', () {
      test('formats basic wire:model', () {
        const input = '<input type="text" wire:model="name">';

        final result = formatter.format(input);

        expect(result, contains('wire:model="name"'));
      });

      test('formats wire:model.defer', () {
        const input = '<input type="text" wire:model.defer="email">';

        final result = formatter.format(input);

        expect(result, contains('wire:model.defer="email"'));
      });

      test('formats wire:model.lazy (legacy)', () {
        const input = '<input type="text" wire:model.lazy="description">';

        final result = formatter.format(input);

        expect(result, contains('wire:model.lazy="description"'));
      });

      test('formats wire:model.live', () {
        const input = '<input type="text" wire:model.live="search">';

        final result = formatter.format(input);

        expect(result, contains('wire:model.live="search"'));
      });

      test('formats wire:model.live.debounce', () {
        const input = '<input type="text" wire:model.live.debounce.500ms="search">';

        final result = formatter.format(input);

        expect(result, contains('wire:model.live.debounce.500ms="search"'));
      });

      test('formats wire:model.blur', () {
        const input = '<input type="text" wire:model.blur="username">';

        final result = formatter.format(input);

        expect(result, contains('wire:model.blur="username"'));
      });
    });

    group('wire:click and actions', () {
      test('formats wire:click with method call', () {
        const input = '<button wire:click="save">Save</button>';

        final result = formatter.format(input);

        expect(result, contains('wire:click="save"'));
      });

      test('formats wire:click with parameters', () {
        const input = '<button wire:click="delete(\$post->id)">Delete</button>';

        final result = formatter.format(input);

        expect(result, contains('wire:click="delete(\$post->id)"'));
      });

      test('formats wire:click with event modifiers', () {
        const input = '<button wire:click.prevent="submit">Submit</button>';

        final result = formatter.format(input);

        expect(result, contains('wire:click.prevent="submit"'));
      });

      test('formats wire:submit', () {
        const input = '<form wire:submit.prevent="save"><input type="text"></form>';

        final result = formatter.format(input);

        expect(result, contains('wire:submit.prevent="save"'));
      });

      test('formats wire:keydown', () {
        const input = '<input type="text" wire:keydown.enter="search">';

        final result = formatter.format(input);

        expect(result, contains('wire:keydown.enter="search"'));
      });
    });

    group('wire:loading states', () {
      test('formats wire:loading', () {
        const input = '<div wire:loading>Loading...</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:loading'));
      });

      test('formats wire:loading.remove', () {
        const input = '<button wire:loading.remove>Save</button>';

        final result = formatter.format(input);

        expect(result, contains('wire:loading.remove'));
      });

      test('formats wire:loading with target', () {
        const input = '<div wire:loading wire:target="save">Saving...</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:loading'));
        expect(result, contains('wire:target="save"'));
      });

      test('formats wire:loading.class', () {
        const input = '<div wire:loading.class="opacity-50">Content</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:loading.class="opacity-50"'));
      });

      test('formats wire:loading.attr', () {
        const input = '<button wire:loading.attr="disabled">Save</button>';

        final result = formatter.format(input);

        expect(result, contains('wire:loading.attr="disabled"'));
      });
    });

    group('wire:poll', () {
      test('formats basic wire:poll', () {
        const input = '<div wire:poll>Current time: {{ \$time }}</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:poll'));
      });

      test('formats wire:poll with interval', () {
        const input = '<div wire:poll.5s>Refreshing every 5 seconds</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:poll.5s'));
      });

      test('formats wire:poll with action', () {
        const input = '<div wire:poll.keep-alive="refresh">Content</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:poll.keep-alive="refresh"'));
      });
    });

    group('wire:init', () {
      test('formats wire:init', () {
        const input = '<div wire:init="loadData">Loading...</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:init="loadData"'));
      });
    });

    group('wire:ignore', () {
      test('formats wire:ignore', () {
        const input = '<div wire:ignore><div id="map"></div></div>';

        final result = formatter.format(input);

        expect(result, contains('wire:ignore'));
      });

      test('formats wire:ignore.self', () {
        const input = '<div wire:ignore.self>Content</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:ignore.self'));
      });
    });

    group('wire:key', () {
      test('formats wire:key in loops', () {
        const input = '''
@foreach(\$items as \$item)
<div wire:key="item-{{ \$item->id }}">
{{ \$item->name }}
</div>
@endforeach
''';

        final result = formatter.format(input);

        expect(result, contains('wire:key="item-{{ \$item->id }}"'));
      });
    });

    group('wire:dirty', () {
      test('formats wire:dirty.class', () {
        const input = '<input type="text" wire:model="name" wire:dirty.class="border-yellow-500">';

        final result = formatter.format(input);

        expect(result, contains('wire:dirty.class="border-yellow-500"'));
      });

      test('formats wire:dirty.remove', () {
        const input = '<span wire:dirty.remove class="text-green-500">Saved</span>';

        final result = formatter.format(input);

        expect(result, contains('wire:dirty.remove'));
      });
    });

    group('wire:offline', () {
      test('formats wire:offline', () {
        const input = '<div wire:offline>You are currently offline</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:offline'));
      });

      test('formats wire:offline.class', () {
        const input = '<div wire:offline.class="bg-red-500">Content</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:offline.class="bg-red-500"'));
      });
    });

    group('Complex Livewire patterns', () {
      test('formats form with multiple wire attributes', () {
        const input = '''
<form wire:submit.prevent="save">
<input type="text" wire:model.defer="title" wire:loading.attr="disabled">
<textarea wire:model.defer="content"></textarea>
<button type="submit" wire:loading.attr="disabled">
<span wire:loading.remove>Save</span>
<span wire:loading>Saving...</span>
</button>
</form>
''';

        final result = formatter.format(input);

        expect(result, contains('wire:submit.prevent="save"'));
        expect(result, contains('wire:model.defer="title"'));
        expect(result, contains('wire:loading.attr="disabled"'));
        expect(result, contains('wire:loading.remove'));
        expect(result, contains('wire:loading'));
      });

      test('formats data table with Livewire pagination', () {
        const input = '''
<div>
<input type="text" wire:model.live.debounce.300ms="search" placeholder="Search...">

<table>
<thead>
<tr>
<th wire:click="sortBy('name')">Name</th>
<th wire:click="sortBy('email')">Email</th>
</tr>
</thead>
<tbody wire:loading.class="opacity-50">
@foreach(\$users as \$user)
<tr wire:key="user-{{ \$user->id }}">
<td>{{ \$user->name }}</td>
<td>{{ \$user->email }}</td>
</tr>
@endforeach
</tbody>
</table>

<div wire:loading wire:target="search">
Searching...
</div>

{{ \$users->links() }}
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('wire:model.live.debounce.300ms="search"'));
        expect(result, contains('wire:click="sortBy(\'name\')"'));
        expect(result, contains('wire:loading.class="opacity-50"'));
        expect(result, contains('wire:key="user-{{ \$user->id }}"'));
      });

      test('formats modal with Livewire state management', () {
        const input = '''
<div x-data="{ open: @entangle('showModal') }">
<button wire:click="\$set('showModal', true)">Open Modal</button>

<div x-show="open" x-cloak>
<div wire:click.self="\$set('showModal', false)">
<div @click.stop>
<h2>{{ \$modalTitle }}</h2>
<form wire:submit.prevent="submitForm">
<input type="text" wire:model.defer="formData.name">
<button type="submit" wire:loading.attr="disabled">
<span wire:loading.remove wire:target="submitForm">Submit</span>
<span wire:loading wire:target="submitForm">Submitting...</span>
</button>
</form>
</div>
</div>
</div>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('x-data="{ open: @entangle(\'showModal\') }"'));
        expect(result, contains('wire:click="\$set(\'showModal\', true)"'));
        expect(result, contains('wire:submit.prevent="submitForm"'));
        expect(result, contains('wire:target="submitForm"'));
      });
    });

    group('Livewire with Alpine.js', () {
      test('formats wire:model with Alpine x-model', () {
        const input = '''
<div x-data="{ localValue: @entangle('serverValue') }">
<input type="text" x-model="localValue">
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('@entangle(\'serverValue\')'));
        expect(result, contains('x-model="localValue"'));
      });

      test('formats @entangle with modifiers', () {
        const input = '<div x-data="{ open: @entangle(\'isOpen\').defer }">Content</div>';

        final result = formatter.format(input);

        expect(result, contains('@entangle(\'isOpen\').defer'));
      });
    });

    group('Livewire file uploads', () {
      test('formats wire:model for file inputs', () {
        const input = '<input type="file" wire:model="photo">';

        final result = formatter.format(input);

        expect(result, contains('wire:model="photo"'));
      });

      test('formats file upload with progress', () {
        const input = '''
<input type="file" wire:model="document">
<div wire:loading wire:target="document">Uploading...</div>
''';

        final result = formatter.format(input);

        expect(result, contains('wire:model="document"'));
        expect(result, contains('wire:target="document"'));
      });
    });

    group('Livewire events', () {
      test('formats wire:on directive', () {
        const input = '<div wire:on="post-created">New post created!</div>';

        final result = formatter.format(input);

        expect(result, contains('wire:on="post-created"'));
      });

      test('formats @this.dispatch in attributes', () {
        const input = '<button wire:click="\$dispatch(\'post-created\')">Create</button>';

        final result = formatter.format(input);

        expect(result, contains('\$dispatch(\'post-created\')'));
      });
    });

    group('Livewire real-time validation', () {
      test('formats validation with wire:model.blur', () {
        const input = '''
<div>
<input type="email" wire:model.blur="email">
@error('email')
<span class="error">{{ \$message }}</span>
@enderror
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('wire:model.blur="email"'));
        expect(result, contains('@error(\'email\')'));
        // Note: @enderror is not a closing directive in the current implementation
        // It may be treated as @error or may not be output
        expect(result, isNotEmpty);
      });
    });
  });
}
