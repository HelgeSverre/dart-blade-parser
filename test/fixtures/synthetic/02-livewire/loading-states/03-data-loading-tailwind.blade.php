{{-- Livewire data-loading with Tailwind v4 examples --}}
<div>
    {{-- Basic data-loading attribute usage --}}
    <button wire:click="save" class="data-loading:opacity-50">
        Save Changes
    </button>

    {{-- Show element only when NOT loading --}}
    <span class="not-data-loading:hidden">Ready</span>

    {{-- Parent has-data-loading variant --}}
    <div>
        <button wire:click="submit">Submit</button>
        <div class="has-data-loading:opacity-50">
            <p>This content dims when any child is loading</p>
        </div>
    </div>

    {{-- Peer-based loading state --}}
    <div class="flex items-center gap-2">
        <button wire:click="refresh" class="peer">Refresh</button>
        <span class="peer-data-loading:opacity-50">
            <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24"></svg>
        </span>
    </div>

    {{-- Arbitrary variant: direct children opacity --}}
    <div class="[&[data-loading]>*]:opacity-50">
        <div class="card">{{ $card1 }}</div>
        <div class="card">{{ $card2 }}</div>
        <div class="card">{{ $card3 }}</div>
    </div>

    {{-- Arbitrary variant: nested icon spin animation --}}
    <button wire:click="process" class="[&[data-loading]_.icon]:animate-spin">
        <svg class="icon h-5 w-5" viewBox="0 0 24 24">
            <path d="M12 2v4m0 12v4m-7-7H2m20 0h-3"></path>
        </svg>
        Process
    </button>

    {{-- Combining multiple data-loading Tailwind utilities --}}
    <form wire:submit="store">
        <input type="text" wire:model="name"
               class="data-loading:opacity-50 data-loading:pointer-events-none">
        <button type="submit"
                class="data-loading:opacity-50 data-loading:cursor-wait [&[data-loading]_.spinner]:block [&[data-loading]_.label]:hidden">
            <span class="spinner hidden">
                <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24"></svg>
            </span>
            <span class="label">Save</span>
        </button>
    </form>

    {{-- Group-based loading patterns --}}
    <div class="group" wire:click="loadDashboard">
        <div class="group-data-loading:animate-pulse">
            <h3>{{ $dashboardTitle }}</h3>
            <p>{{ $dashboardSummary }}</p>
        </div>
    </div>
</div>