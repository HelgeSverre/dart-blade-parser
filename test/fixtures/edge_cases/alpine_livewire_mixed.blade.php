{{-- Alpine.js + Livewire + Blade combinations --}}

{{-- Alpine shorthand @click with Blade @if in same template --}}
<div x-data="{ open: false }">
    @if($showToggle)
        <button @click="open = !open" type="button">
            Toggle
        </button>
    @endif

    <div x-show="open" x-transition>
        <p>{{ $content }}</p>
    </div>
</div>

{{-- Alpine :bind shorthand with Blade echoes --}}
<div x-data="{ color: '{{ $defaultColor }}' }">
    <input type="color" x-model="color">
    <div :style="'background-color: ' + color" :class="{ 'rounded': {{ $isRounded ? 'true' : 'false' }} }">
        Preview
    </div>
</div>

{{-- Livewire model + Alpine + Blade attribute directives --}}
<form wire:submit="save">
    @csrf
    <div x-data="{ charCount: 0 }">
        <input
            type="text"
            wire:model.live="name"
            x-on:input="charCount = $el.value.length"
            @class(['input', 'input-error' => $errors->has('name')])
            @required(true)
        >
        <span x-text="charCount + '/255'"></span>
    </div>

    @error('name')
        <span class="error">{{ $message }}</span>
    @enderror

    <select wire:model="category" @disabled($isLocked)>
        @foreach($categories as $cat)
            <option value="{{ $cat->id }}" @selected($cat->id === $selectedId)>
                {{ $cat->name }}
            </option>
        @endforeach
    </select>

    <button type="submit" wire:loading.attr="disabled" wire:target="save">
        <span wire:loading.remove wire:target="save">Save</span>
        <span wire:loading wire:target="save">Saving...</span>
    </button>
</form>

{{-- Livewire polling with Alpine --}}
<div wire:poll.5s="refreshData" x-data="{ highlighted: false }">
    @foreach($entries as $entry)
        <div
            wire:key="entry-{{ $entry->id }}"
            x-on:mouseenter="highlighted = true"
            x-on:mouseleave="highlighted = false"
            :class="{ 'bg-yellow-50': highlighted }"
        >
            {{ $entry->title }}
            @can('edit', $entry)
                <button wire:click="edit({{ $entry->id }})" @click.stop>
                    Edit
                </button>
            @endcan
        </div>
    @endforeach
</div>

{{-- Alpine keyboard events with Blade --}}
<div x-data="{ search: '' }" @keydown.escape="search = ''" @keydown.enter="$wire.search(search)">
    <input type="text" x-model="search" placeholder="{{ __('Search...') }}">
    @if($showResults)
        <ul>
            @forelse($results as $result)
                <li>{{ $result->name }}</li>
            @empty
                <li>No results</li>
            @endforelse
        </ul>
    @endif
</div>
