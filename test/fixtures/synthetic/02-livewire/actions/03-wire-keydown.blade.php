{{-- Livewire wire:keydown keyboard event examples --}}
<div>
    {{-- Enter key for search --}}
    <div class="search-container">
        <input
            type="text"
            wire:model="searchQuery"
            wire:keydown.enter="performSearch"
            placeholder="Press Enter to search"
        >
        <span wire:loading wire:target="performSearch">Searching...</span>
    </div>

    {{-- Escape key to close modal --}}
    <div wire:keydown.escape="closeModal" class="modal" tabindex="0">
        <div class="modal-content">
            <h3>Press ESC to close</h3>
            <p>{{ $modalContent }}</p>
        </div>
    </div>

    {{-- Comment submission with keyboard shortcuts --}}
    <div class="comment-box">
        <textarea
            wire:model="comment"
            wire:keydown.enter="addComment"
            wire:keydown.shift.enter="addCommentAndClear"
            placeholder="Enter to submit, Shift+Enter for submit and clear"
            rows="3"
        ></textarea>
        <small>Press Enter to submit, Shift+Enter to submit and clear</small>
    </div>

    {{-- Task management with keyboard shortcuts --}}
    <div class="task-input">
        <input
            type="text"
            wire:model="taskName"
            wire:keydown.enter="createTask"
            wire:keydown.escape="clearInput"
            placeholder="Add task (Enter to save, Esc to clear)"
        >
    </div>

    {{-- Navigation with arrow keys --}}
    <div
        wire:keydown.arrow-up="previousItem"
        wire:keydown.arrow-down="nextItem"
        wire:keydown.arrow-left="previousPage"
        wire:keydown.arrow-right="nextPage"
        tabindex="0"
        class="navigable-list"
    >
        <h4>Use arrow keys to navigate</h4>
        @foreach($items as $item)
            <div class="item {{ $selectedItem === $item->id ? 'active' : '' }}">
                {{ $item->name }}
            </div>
        @endforeach
    </div>

    {{-- Quick actions with keyboard modifiers --}}
    <div
        wire:keydown.ctrl.s="saveChanges"
        wire:keydown.ctrl.shift.s="saveAndPublish"
        wire:keydown.ctrl.k="openCommandPalette"
        tabindex="0"
        class="editor"
    >
        <h4>Keyboard Shortcuts</h4>
        <ul>
            <li>Ctrl+S: Save</li>
            <li>Ctrl+Shift+S: Save and Publish</li>
            <li>Ctrl+K: Command Palette</li>
        </ul>
    </div>
</div>
