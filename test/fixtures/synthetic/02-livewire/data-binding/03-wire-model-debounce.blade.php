<div class="advanced-search">
    <h2>Advanced Search with Debounce</h2>

    {{-- Debounced Search (500ms) --}}
    <div class="form-group">
        <label for="query">Search Query</label>
        <input
            type="text"
            id="query"
            wire:model.live.debounce.500ms="query"
            placeholder="Type to search..."
            class="form-control"
        >
        <small class="text-muted">Results update 500ms after you stop typing</small>
    </div>

    {{-- Debounced Tags Input (1s) --}}
    <div class="form-group">
        <label for="tags">Tags (comma-separated)</label>
        <input
            type="text"
            id="tags"
            wire:model.live.debounce.1s="tags"
            placeholder="laravel, php, livewire"
            class="form-control"
        >
        <small class="text-muted">Tags process 1 second after typing</small>
    </div>

    {{-- Debounced Description (750ms) --}}
    <div class="form-group">
        <label for="description">Description</label>
        <textarea
            id="description"
            wire:model.live.debounce.750ms="description"
            rows="4"
            class="form-control"
        ></textarea>
        <span class="char-count">{{ strlen($description) }} characters</span>
    </div>

    {{-- Loading Indicator --}}
    <div wire:loading class="loading">
        <span class="spinner"></span> Searching...
    </div>

    <button wire:click="performSearch" class="btn btn-primary">Search Now</button>
</div>
