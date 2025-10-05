{{-- Alpine.js Event Modifiers: .prevent, .stop, .outside, .window, .debounce --}}
<div x-data="{
    search: '',
    modalOpen: false,
    scrollCount: 0,
    clickedInside: false,
    results: []
}">
    {{-- Prevent default form submission --}}
    <form @submit.prevent="results.push(search); search = ''">
        <input
            type="text"
            x-model="search"
            @input.debounce.500ms="console.log('Searching...', search)"
            placeholder="Search (debounced 500ms)"
        >
        <button type="submit">Search</button>
    </form>

    {{-- Stop propagation --}}
    <div @click="clickedInside = false" class="outer">
        Outer div
        <button @click.stop="clickedInside = true" class="inner">
            Click me (stops propagation)
        </button>
        <p x-text="clickedInside ? 'Clicked inside' : 'Clicked outside button'"></p>
    </div>

    {{-- Window and document events --}}
    <div @scroll.window.throttle.100ms="scrollCount++">
        Scroll count: <span x-text="scrollCount"></span>
    </div>

    {{-- Modal with click outside to close --}}
    <button @click="modalOpen = true">Open Modal</button>

    <div x-show="modalOpen" class="modal-backdrop">
        <div @click.outside="modalOpen = false" class="modal-content">
            <h2>Modal Dialog</h2>
            <p>Click outside to close</p>
            <button @click.prevent.stop="modalOpen = false">
                Close
            </button>
        </div>
    </div>
</div>
