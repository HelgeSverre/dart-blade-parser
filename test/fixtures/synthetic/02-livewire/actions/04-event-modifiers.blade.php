{{-- Livewire event modifiers comprehensive examples --}}
<div>
    {{-- .prevent modifier - prevents default form submission --}}
    <form wire:submit.prevent="handleSubmit">
        <h3>Newsletter Signup (prevent default)</h3>
        <input type="email" wire:model="email" placeholder="Your email">
        <button type="submit">Subscribe</button>
    </form>

    {{-- .stop modifier - stops event propagation --}}
    <div wire:click="handleParent" class="parent-container">
        <div wire:click.stop="handleChild" class="child-element">
            <button wire:click.stop="handleButton">
                Click me (won't bubble to parent)
            </button>
        </div>
    </div>

    {{-- .self modifier - only triggers on element itself --}}
    <div wire:click.self="closeOverlay" class="overlay">
        <div class="modal-content">
            <h3>Click outside to close (self modifier)</h3>
            <p>Clicking this content won't trigger closeOverlay</p>
            <button wire:click="confirmAction">Confirm</button>
        </div>
    </div>

    {{-- .debounce modifier - debounces input --}}
    <div class="search-section">
        <input
            type="text"
            wire:model.debounce.500ms="searchTerm"
            placeholder="Search products (500ms debounce)"
        >
        <span wire:loading wire:target="searchTerm">Searching...</span>

        <input
            type="text"
            wire:keydown.debounce.750ms="liveSearch"
            placeholder="Live search (750ms debounce)"
        >
    </div>

    {{-- .throttle modifier - throttles events --}}
    <div class="analytics-section">
        <button wire:click.throttle.1s="trackClick">
            Track Click (max once per second)
        </button>

        <div
            wire:mousemove.throttle.250ms="trackMouseMovement"
            class="tracking-area"
        >
            Move mouse here (throttled to 250ms)
        </div>
    </div>

    {{-- Combined modifiers --}}
    <form wire:submit.prevent="saveSettings">
        <h3>User Settings</h3>

        <input
            type="text"
            wire:model.debounce.300ms="username"
            wire:keydown.enter.prevent="validateUsername"
            placeholder="Username"
        >
        @error('username') <span class="error">{{ $message }}</span> @enderror

        <input
            type="text"
            wire:model.debounce.500ms="displayName"
            placeholder="Display Name"
        >

        <button type="submit" wire:loading.attr="disabled">
            Save Settings
        </button>
        <span wire:loading wire:target="saveSettings">Saving...</span>
    </form>

    {{-- .once modifier - fires only once --}}
    <div wire:click.once="initializeComponent" class="init-container">
        Click to initialize (only works once)
    </div>
</div>
