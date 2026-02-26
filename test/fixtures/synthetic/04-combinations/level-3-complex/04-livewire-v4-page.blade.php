{{--
---
features:
  - livewire_v4_sfc
  - computed_attribute
  - validate_attribute
  - locked_attribute
  - wire_navigate
  - wire_current
  - wire_submit
  - wire_model_variants
  - wire_sort
  - wire_key
  - data_loading
  - teleport
  - wire_confirm
  - persist
  - entangle
  - wire_poll
  - debounce
description: Comprehensive Livewire v4 single-file component page with search, table, modal, Alpine integration, and audio player
complexity: complex
line_count: ~170
--}}
<?php

use Livewire\Volt\Component;
use Livewire\Attributes\{Computed, Validate, Locked, On, Url};
use App\Models\{Product, Category};

new class extends Component {
    #[Locked]
    public int $shopId;

    #[Url]
    public string $search = '';

    #[Url]
    public string $sortField = 'name';

    #[Url]
    public string $sortDirection = 'asc';

    public string $tab = 'products';

    public bool $showCreateModal = false;

    #[Validate('required|min:3|max:255')]
    public string $newName = '';

    #[Validate('required|numeric|min:0')]
    public string $newPrice = '';

    #[Validate('required|exists:categories,id')]
    public string $newCategory = '';

    public function mount(int $shopId): void
    {
        $this->shopId = $shopId;
    }

    #[Computed]
    public function products()
    {
        return Product::query()
            ->where('shop_id', $this->shopId)
            ->when($this->search, fn ($q) => $q->where('name', 'like', "%{$this->search}%"))
            ->orderBy($this->sortField, $this->sortDirection)
            ->paginate(15);
    }

    #[Computed]
    public function categories()
    {
        return Category::where('shop_id', $this->shopId)->get();
    }

    #[Computed]
    public function stats()
    {
        return [
            'total' => Product::where('shop_id', $this->shopId)->count(),
            'active' => Product::where('shop_id', $this->shopId)->where('active', true)->count(),
            'value' => Product::where('shop_id', $this->shopId)->sum('price'),
        ];
    }

    public function sort(string $field): void
    {
        $this->sortDirection = $this->sortField === $field && $this->sortDirection === 'asc' ? 'desc' : 'asc';
        $this->sortField = $field;
    }

    public function save(): void
    {
        $this->validate();

        Product::create([
            'shop_id' => $this->shopId,
            'name' => $this->newName,
            'price' => $this->newPrice,
            'category_id' => $this->newCategory,
        ]);

        $this->reset('newName', 'newPrice', 'newCategory', 'showCreateModal');
    }

    public function toggleActive(int $id): void
    {
        $product = Product::where('shop_id', $this->shopId)->findOrFail($id);
        $product->update(['active' => !$product->active]);
    }

    public function delete(int $id): void
    {
        Product::where('shop_id', $this->shopId)->findOrFail($id)->delete();
    }

    #[On('product-imported')]
    public function refreshProducts(): void
    {
        unset($this->products, $this->stats);
    }
}; ?>

<div x-data="{ playerVisible: $wire.entangle('showCreateModal') }" wire:poll.30s="refreshProducts">
    <nav class="flex gap-4 border-b mb-6">
        <a href="/shop/{{ $shopId }}/products" wire:navigate wire:current="font-bold border-b-2 border-blue-500">
            Products
        </a>
        <a href="/shop/{{ $shopId }}/orders" wire:navigate wire:current="font-bold border-b-2 border-blue-500">
            Orders
        </a>
        <a href="/shop/{{ $shopId }}/settings" wire:navigate wire:current="font-bold border-b-2 border-blue-500">
            Settings
        </a>
    </nav>

    <div class="flex items-center justify-between mb-4">
        <input
            type="search"
            wire:model.live.debounce.250ms="search"
            placeholder="Search products..."
            class="border rounded px-3 py-2 w-64"
        >
        <button wire:click="$set('showCreateModal', true)" class="btn-primary">Add Product</button>
    </div>

    <div class="grid grid-cols-3 gap-4 mb-6" wire:poll.15s>
        <div class="bg-white p-4 rounded shadow">
            <span class="text-sm text-gray-500">Total Products</span>
            <p class="text-xl font-bold">{{ $this->stats['total'] }}</p>
        </div>
        <div class="bg-white p-4 rounded shadow">
            <span class="text-sm text-gray-500">Active</span>
            <p class="text-xl font-bold text-green-600">{{ $this->stats['active'] }}</p>
        </div>
        <div class="bg-white p-4 rounded shadow">
            <span class="text-sm text-gray-500">Inventory Value</span>
            <p class="text-xl font-bold">${{ number_format($this->stats['value'], 2) }}</p>
        </div>
    </div>

    <table class="w-full bg-white rounded shadow">
        <thead>
            <tr class="border-b">
                <th class="p-3 text-left cursor-pointer" wire:click="sort('name')">
                    Name
                    @if ($sortField === 'name')
                        <span>{{ $sortDirection === 'asc' ? '&#9650;' : '&#9660;' }}</span>
                    @endif
                </th>
                <th class="p-3 text-left cursor-pointer" wire:click="sort('price')">
                    Price
                    @if ($sortField === 'price')
                        <span>{{ $sortDirection === 'asc' ? '&#9650;' : '&#9660;' }}</span>
                    @endif
                </th>
                <th class="p-3 text-left">Category</th>
                <th class="p-3 text-left">Status</th>
                <th class="p-3 text-right">Actions</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($this->products as $product)
                <tr wire:key="product-{{ $product->id }}" class="border-b hover:bg-gray-50">
                    <td class="p-3">
                        <a href="/shop/{{ $shopId }}/products/{{ $product->id }}" wire:navigate>{{ $product->name }}</a>
                    </td>
                    <td class="p-3">${{ number_format($product->price, 2) }}</td>
                    <td class="p-3">{{ $product->category->name }}</td>
                    <td class="p-3">
                        <button wire:click="toggleActive({{ $product->id }})" class="data-loading:opacity-50">
                            @if ($product->active)
                                <span class="text-green-600 text-sm font-medium">Active</span>
                            @else
                                <span class="text-gray-400 text-sm">Inactive</span>
                            @endif
                        </button>
                    </td>
                    <td class="p-3 text-right">
                        <button
                            wire:click="delete({{ $product->id }})"
                            wire:confirm="Delete {{ $product->name }}? This cannot be undone."
                            class="text-red-500 text-sm data-loading:opacity-50"
                        >
                            Delete
                        </button>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="p-8 text-center text-gray-400">No products found.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div class="mt-4">{{ $this->products->links() }}</div>

    @persist('audio-player')
        <div class="fixed bottom-0 left-0 right-0 bg-gray-900 text-white p-3">
            <audio src="/notification.mp3" x-ref="audio"></audio>
            <span class="text-sm">Notification sound active</span>
        </div>
    @endpersist

    @teleport('body')
        <div x-show="playerVisible" x-cloak class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @keydown.escape.window="playerVisible = false">
            <form wire:submit="save" class="bg-white rounded-lg p-6 w-[28rem] shadow-xl" @click.outside="playerVisible = false">
                <h2 class="text-lg font-semibold mb-4">Add Product</h2>

                <div class="space-y-3">
                    <div>
                        <label class="block text-sm font-medium mb-1">Name</label>
                        <input type="text" wire:model.blur="newName" class="w-full border rounded p-2">
                        @error('newName') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Price</label>
                        <input type="number" wire:model.blur="newPrice" step="0.01" class="w-full border rounded p-2">
                        @error('newPrice') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Category</label>
                        <select wire:model="newCategory" class="w-full border rounded p-2">
                            <option value="">Select...</option>
                            @foreach ($this->categories as $cat)
                                <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                            @endforeach
                        </select>
                        @error('newCategory') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                    </div>
                </div>

                <div class="flex justify-end gap-2 mt-5">
                    <button type="button" @click="playerVisible = false" class="btn-secondary">Cancel</button>
                    <button type="submit" class="btn-primary data-loading:opacity-50">Save Product</button>
                </div>
            </form>
        </div>
    @endteleport
</div>
