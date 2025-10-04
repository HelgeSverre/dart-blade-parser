{{-- Alpine.js x-data Basic Reactivity Test --}}
<div x-data="{
    searchQuery: '',
    items: ['Laravel', 'Alpine.js', 'Livewire', 'Tailwind CSS', 'Vue.js', 'React'],
    selectedItem: null,
    isLoading: false,
    get filteredItems() {
        if (this.searchQuery === '') return this.items;
        return this.items.filter(item =>
            item.toLowerCase().includes(this.searchQuery.toLowerCase())
        );
    },
    get itemCount() {
        return this.filteredItems.length;
    },
    selectItem(item) {
        this.selectedItem = item;
        this.searchQuery = '';
    },
    clearSelection() {
        this.selectedItem = null;
    },
    async simulateApiCall() {
        this.isLoading = true;
        await new Promise(resolve => setTimeout(resolve, 1000));
        this.isLoading = false;
    }
}" class="max-w-md mx-auto p-6">
    <h2 class="text-2xl font-bold mb-4">Search Framework</h2>

    <input
        type="text"
        x-model="searchQuery"
        placeholder="Type to search..."
        class="w-full px-4 py-2 border rounded-lg mb-4"
        @focus="clearSelection()"
    >

    <div x-show="searchQuery" class="mb-4">
        <p class="text-sm text-gray-600" x-text="`Found ${itemCount} item(s)`"></p>
        <ul class="border rounded-lg divide-y">
            <template x-for="item in filteredItems" :key="item">
                <li @click="selectItem(item)"
                    class="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                    x-text="item"></li>
            </template>
        </ul>
    </div>

    <div x-show="selectedItem" class="p-4 bg-blue-50 rounded-lg">
        <p class="font-semibold">Selected: <span x-text="selectedItem"></span></p>
        <button @click="clearSelection()" class="mt-2 text-sm text-blue-600">Clear</button>
    </div>

    <button
        @click="simulateApiCall()"
        :disabled="isLoading"
        class="mt-4 px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
        x-text="isLoading ? 'Loading...' : 'Simulate API Call'">
    </button>
</div>
