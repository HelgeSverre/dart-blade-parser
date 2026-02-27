{{-- Livewire teleport, persist, script, assets, and entangle directive examples --}}
<div>
    {{-- @teleport - render content at a different location in the DOM --}}
    @teleport('body')
        <div class="modal-overlay" x-show="showModal">
            <div class="modal">
                <h2>{{ $modalTitle }}</h2>
                <p>{{ $modalContent }}</p>
                <button wire:click="closeModal">Close</button>
            </div>
        </div>
    @endteleport

    {{-- Teleport a dropdown to body to avoid overflow issues --}}
    <div class="relative">
        <button wire:click="$toggle('showDropdown')">Options</button>
        @teleport('body')
            <div class="dropdown-menu absolute" x-show="showDropdown">
                <a href="#" wire:click="edit">Edit</a>
                <a href="#" wire:click="duplicate">Duplicate</a>
                <a href="#" wire:click="archive">Archive</a>
            </div>
        @endteleport
    </div>

    {{-- @persist - preserve DOM across Livewire re-renders and navigation --}}
    @persist('audio-player')
        <div class="audio-player">
            <audio id="audio" src="{{ $audioSrc }}"></audio>
            <button onclick="document.getElementById('audio').play()">Play</button>
            <button onclick="document.getElementById('audio').pause()">Pause</button>
        </div>
    @endpersist

    @persist('map')
        <div id="map-container" style="height: 400px;">
            {{-- Map will be initialized by JS and preserved across updates --}}
        </div>
    @endpersist

    {{-- @script - Livewire-aware script block --}}
    @script
        <script>
            $wire.on('post-saved', () => {
                alert('Post was saved successfully!');
            });

            $wire.on('item-deleted', ({ id }) => {
                console.log('Deleted item:', id);
            });

            Livewire.hook('morph.updated', ({ el }) => {
                console.log('Element updated:', el);
            });
        </script>
    @endscript

    {{-- @assets - load external CSS/JS only once --}}
    @assets
        <link rel="stylesheet" href="https://cdn.example.com/datepicker.css">
        <script src="https://cdn.example.com/datepicker.js"></script>
    @endassets

    @assets
        <link rel="stylesheet" href="https://cdn.example.com/chart.css">
        <script src="https://cdn.example.com/chart.js"></script>
    @endassets

    {{-- @entangle - bind Livewire property to Alpine.js --}}
    <div x-data="{ open: @entangle('showPanel') }">
        <button x-on:click="open = !open">Toggle Panel</button>
        <div x-show="open" x-transition>
            <p>{{ $panelContent }}</p>
        </div>
    </div>

    {{-- @entangle with .live - sync immediately without deferring --}}
    <div x-data="{ count: @entangle('counter').live }">
        <span x-text="count"></span>
        <button x-on:click="count++">Increment</button>
        <button x-on:click="count--">Decrement</button>
    </div>

    {{-- @entangle in a form --}}
    <div x-data="{ name: @entangle('formData.name').live, email: @entangle('formData.email').live }">
        <input type="text" x-model="name" placeholder="Name">
        <input type="email" x-model="email" placeholder="Email">
        <p x-show="name">Hello, <span x-text="name"></span>!</p>
    </div>

    {{-- @entangle with complex Alpine component --}}
    <div x-data="{
        items: @entangle('selectedItems'),
        search: @entangle('searchQuery').live,
        toggle(id) {
            if (this.items.includes(id)) {
                this.items = this.items.filter(i => i !== id);
            } else {
                this.items.push(id);
            }
        }
    }">
        <input type="text" x-model="search" placeholder="Search items...">
        @foreach($availableItems as $item)
            <label wire:key="selectable-{{ $item->id }}">
                <input type="checkbox"
                       x-on:change="toggle({{ $item->id }})"
                       x-bind:checked="items.includes({{ $item->id }})">
                {{ $item->name }}
            </label>
        @endforeach
    </div>
</div>