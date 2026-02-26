{{-- Livewire wire:loading basic examples --}}
<div>
    {{-- Show element during loading --}}
    <div wire:loading>Loading...</div>

    {{-- Hide element during loading --}}
    <div wire:loading.remove>Content loaded</div>

    {{-- wire:loading with wire:target --}}
    <button wire:click="save">Save</button>
    <span wire:loading wire:target="save">Saving...</span>
    <span wire:loading.remove wire:target="save">Ready</span>

    {{-- Multiple targets --}}
    <div wire:loading wire:target="save, delete">Processing...</div>

    {{-- Target with parameters --}}
    <div wire:loading wire:target="remove({{ $post->id }})">Removing...</div>

    {{-- wire:target.except --}}
    <div wire:loading wire:target.except="download">Loading...</div>
</div>