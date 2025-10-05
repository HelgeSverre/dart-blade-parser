{{-- Alpine.js Keyboard Event Modifiers: .enter, .escape, .shift, arrow keys --}}
<div x-data="{
    command: '',
    logs: [],
    selectedIndex: 0,
    items: ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'],
    searchMode: false
}">
    {{-- Command input with Enter key --}}
    <input
        type="text"
        x-model="command"
        @keydown.enter="logs.push(command); command = ''"
        @keydown.escape="command = ''"
        placeholder="Type command, Enter to log, Esc to clear"
    >

    {{-- Keyboard navigation with arrow keys --}}
    <div
        tabindex="0"
        @keydown.arrow-up.prevent="selectedIndex = Math.max(0, selectedIndex - 1)"
        @keydown.arrow-down.prevent="selectedIndex = Math.min(items.length - 1, selectedIndex + 1)"
        @keydown.enter="logs.push('Selected: ' + items[selectedIndex])"
        class="list-container"
    >
        <template x-for="(item, index) in items" :key="index">
            <div :class="index === selectedIndex ? 'selected' : ''">
                <span x-text="item"></span>
            </div>
        </template>
    </div>

    {{-- Modifier key combinations --}}
    <textarea
        @keydown.ctrl.s.prevent="logs.push('Ctrl+S: Save triggered')"
        @keydown.shift.enter="logs.push('Shift+Enter: New line'); $event.preventDefault()"
        @keydown.escape.window="searchMode = false"
        placeholder="Ctrl+S to save, Shift+Enter for log"
    ></textarea>

    {{-- Log output --}}
    <div class="logs">
        <template x-for="log in logs">
            <div x-text="log"></div>
        </template>
    </div>
</div>
