{{-- Livewire wire:loading modifier examples --}}
<div>
    {{-- Add CSS class during loading --}}
    <button wire:click="save" wire:loading.class="opacity-50 cursor-wait">
        Save Changes
    </button>

    {{-- Remove CSS class during loading --}}
    <div wire:loading.class.remove="bg-green-500" wire:target="save">
        Status Indicator
    </div>

    {{-- Set HTML attribute during loading --}}
    <button wire:click="submit" wire:loading.attr="disabled">
        Submit Form
    </button>

    {{-- Multiple attributes --}}
    <input type="text" wire:loading.attr="readonly" wire:target="search">

    {{-- Delay modifiers --}}
    <div wire:loading.delay>Loading (default 200ms delay)...</div>
    <div wire:loading.delay.shortest>Loading (50ms delay)...</div>
    <div wire:loading.delay.shorter>Loading (100ms delay)...</div>
    <div wire:loading.delay.short>Loading (150ms delay)...</div>
    <div wire:loading.delay.long>Loading (300ms delay)...</div>
    <div wire:loading.delay.longer>Loading (500ms delay)...</div>
    <div wire:loading.delay.longest>Loading (1000ms delay)...</div>

    {{-- Display type modifiers --}}
    <div wire:loading.inline-flex>
        <svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10" stroke="currentColor"></circle>
        </svg>
        Loading...
    </div>

    <span wire:loading.inline wire:target="search">Searching...</span>

    <div wire:loading.block wire:target="loadMore">
        <p>Loading more results...</p>
    </div>

    <tr wire:loading.table wire:target="fetchRows">
        <td colspan="5">Loading rows...</td>
    </tr>

    <div wire:loading.flex wire:target="refresh">
        <div class="spinner"></div>
        <span>Refreshing...</span>
    </div>

    <div wire:loading.grid wire:target="loadGallery">
        <div class="skeleton"></div>
        <div class="skeleton"></div>
        <div class="skeleton"></div>
    </div>

    {{-- Combined modifiers --}}
    <button wire:click="processPayment"
            wire:loading.class="opacity-50"
            wire:loading.attr="disabled"
            wire:loading.delay.short>
        <span wire:loading.remove wire:target="processPayment">Pay Now</span>
        <span wire:loading.inline wire:target="processPayment">Processing...</span>
    </button>

    {{-- Loading with class and target --}}
    <div wire:loading.class="animate-pulse" wire:target="fetchData">
        <h2>{{ $title }}</h2>
        <p>{{ $description }}</p>
    </div>
</div>