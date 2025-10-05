{{-- Alpine.js x-effect Reactive Side Effects Test --}}
<div x-data="{
    theme: 'light',
    fontSize: 16,
    autoSave: true,
    content: '',
    lastSaved: null,
    wordCount: 0,
    characterCount: 0,
    saveStatus: 'idle',

    get contentStats() {
        return {
            words: this.content.trim().split(/\s+/).filter(w => w.length > 0).length,
            characters: this.content.length,
            lines: this.content.split('\n').length
        };
    },

    async saveContent() {
        if (!this.autoSave) return;

        this.saveStatus = 'saving';
        // Simulate API save
        await new Promise(resolve => setTimeout(resolve, 500));
        this.lastSaved = new Date().toLocaleTimeString();
        this.saveStatus = 'saved';

        setTimeout(() => { this.saveStatus = 'idle'; }, 2000);
    },

    applyTheme() {
        document.documentElement.classList.toggle('dark', this.theme === 'dark');
    }
}"
x-effect="
    // Watch content changes and update word/character count
    wordCount = contentStats.words;
    characterCount = contentStats.characters;
"
x-effect="
    // Auto-save when content changes (debounced effect simulation)
    if (content && autoSave) {
        saveContent();
    }
"
x-effect="
    // Apply theme changes to document
    applyTheme();
"
x-effect="
    // Log font size changes for debugging
    console.log('Font size changed to:', fontSize);
"
class="max-w-3xl mx-auto p-6">

    <div class="mb-6 flex items-center justify-between">
        <h2 class="text-2xl font-bold">Text Editor with Reactive Effects</h2>

        <div class="flex gap-4 items-center">
            <label class="flex items-center gap-2">
                <input type="checkbox" x-model="autoSave" class="rounded">
                <span class="text-sm">Auto-save</span>
            </label>

            <select x-model="theme" class="px-3 py-1 border rounded">
                <option value="light">Light</option>
                <option value="dark">Dark</option>
            </select>
        </div>
    </div>

    <div class="mb-4 p-4 bg-gray-50 rounded-lg">
        <div class="flex items-center gap-4 text-sm">
            <label class="flex items-center gap-2">
                <span>Font Size:</span>
                <input
                    type="range"
                    x-model.number="fontSize"
                    min="12"
                    max="24"
                    class="w-32"
                >
                <span x-text="fontSize + 'px'"></span>
            </label>

            <div class="ml-auto flex gap-4 text-gray-600">
                <span>Words: <strong x-text="wordCount"></strong></span>
                <span>Characters: <strong x-text="characterCount"></strong></span>
            </div>
        </div>
    </div>

    <textarea
        x-model="content"
        :style="`font-size: ${fontSize}px`"
        placeholder="Start typing... Your changes will be tracked reactively."
        class="w-full h-64 p-4 border rounded-lg resize-none focus:ring-2 focus:ring-blue-500"
    ></textarea>

    <div class="mt-4 flex items-center justify-between text-sm">
        <div class="flex items-center gap-2">
            <span class="inline-block w-2 h-2 rounded-full"
                :class="{
                    'bg-gray-400': saveStatus === 'idle',
                    'bg-yellow-400 animate-pulse': saveStatus === 'saving',
                    'bg-green-400': saveStatus === 'saved'
                }">
            </span>
            <span x-show="saveStatus === 'saving'">Saving...</span>
            <span x-show="saveStatus === 'saved'">Saved!</span>
            <span x-show="lastSaved" class="text-gray-500">
                Last saved at <span x-text="lastSaved"></span>
            </span>
        </div>

        <button
            @click="content = ''; wordCount = 0; characterCount = 0;"
            class="px-3 py-1 text-red-600 hover:bg-red-50 rounded"
        >
            Clear
        </button>
    </div>
</div>
