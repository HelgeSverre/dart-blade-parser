{{-- Inventory Management System - comprehensive stress fixture --}}
@extends('layouts.app')

@section('title', 'Inventory Management')

@push('styles')
    <style>
        .stock-critical { background-color: #fef2f2; border-left: 4px solid #ef4444; }
        .stock-low { background-color: #fffbeb; border-left: 4px solid #f59e0b; }
        .stock-ok { background-color: #f0fdf4; border-left: 4px solid #22c55e; }
        .drag-handle { cursor: grab; }
        .drag-handle:active { cursor: grabbing; }
    </style>
@endpush

@php
    $warehouses = [
        ['id' => 1, 'name' => 'Main Warehouse', 'code' => 'WH-001', 'capacity' => 10000],
        ['id' => 2, 'name' => 'East Distribution', 'code' => 'WH-002', 'capacity' => 5000],
        ['id' => 3, 'name' => 'West Fulfillment', 'code' => 'WH-003', 'capacity' => 7500],
    ];
    $statusColors = [
        'active' => 'green',
        'discontinued' => 'red',
        'draft' => 'gray',
        'backorder' => 'yellow',
    ];
    $currencySymbol = '$';
@endphp

@inject('inventoryService', 'App\Services\InventoryService')

@section('content')
    <div
        class="min-h-screen bg-gray-50"
        x-data="{
            searchQuery: '',
            selectedCategory: 'all',
            selectedWarehouse: 'all',
            showFilters: false,
            showBatchActions: false,
            selectedItems: [],
            viewMode: 'table',
            sortField: 'name',
            sortDirection: 'asc',
            showProductModal: false,
            editingProduct: null,
            showImportModal: false,
            confirmDelete: null,
            stockAlertThreshold: 10,
        }"
        x-init="$watch('selectedItems', value => showBatchActions = value.length > 0)"
    >
        {{-- Page Header --}}
        <header class="sticky top-0 z-20 border-b border-gray-200 bg-white shadow-sm">
            <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
                <div class="flex items-center justify-between">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">Inventory Management</h1>
                        <p class="mt-1 text-sm text-gray-500">
                            {{ number_format($totalProducts) }} products across {{ count($warehouses) }} warehouses
                        </p>
                    </div>

                    <div class="flex items-center space-x-3">
                        @can('export', App\Models\Product::class)
                            <x-button
                                variant="outline"
                                wire:click="exportInventory"
                                wire:loading.attr="disabled"
                                wire:target="exportInventory"
                            >
                                <x-icon name="download" class="mr-2 size-4" />
                                <span wire:loading.remove wire:target="exportInventory">Export</span>
                                <span wire:loading wire:target="exportInventory">Exporting...</span>
                            </x-button>
                        @endcan

                        @can('import', App\Models\Product::class)
                            <x-button variant="outline" @click="showImportModal = true">
                                <x-icon name="upload" class="mr-2 size-4" />
                                Import
                            </x-button>
                        @endcan

                        @can('create', App\Models\Product::class)
                            <x-button
                                variant="primary"
                                @click="showProductModal = true; editingProduct = null"
                            >
                                <x-icon name="plus" class="mr-2 size-4" />
                                Add Product
                            </x-button>
                        @endcan
                    </div>
                </div>
            </div>
        </header>

        <main class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-4">
                {{-- Sidebar: Categories & Filters --}}
                <aside class="lg:col-span-1">
                    <nav class="sticky top-24 space-y-4">
                        {{-- Category Tree --}}
                        <div class="rounded-lg bg-white p-4 shadow">
                            <h3 class="mb-3 font-semibold text-gray-900">Categories</h3>
                            @forelse($categories as $category)
                                <div
                                    @class([
                                        'flex cursor-pointer items-center justify-between rounded-md px-3 py-2 text-sm transition-colors',
                                        'bg-blue-50 font-medium text-blue-700' => $currentCategory?->id === $category->id,
                                        'text-gray-600 hover:bg-gray-50' => $currentCategory?->id !== $category->id,
                                    ])
                                    wire:click="selectCategory({{ $category->id }})"
                                    wire:key="cat-{{ $category->id }}"
                                >
                                    <span>{{ $category->name }}</span>
                                    <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-500">
                                        {{ $category->products_count }}
                                    </span>
                                </div>

                                @if($category->children->isNotEmpty())
                                    <div class="ml-4 border-l border-gray-200 pl-2">
                                        @foreach($category->children as $child)
                                            <div
                                                @class([
                                                    'flex cursor-pointer items-center justify-between rounded-md px-3 py-1.5 text-xs transition-colors',
                                                    'bg-blue-50 text-blue-700' => $currentCategory?->id === $child->id,
                                                    'text-gray-500 hover:bg-gray-50' => $currentCategory?->id !== $child->id,
                                                ])
                                                wire:click="selectCategory({{ $child->id }})"
                                                wire:key="subcat-{{ $child->id }}"
                                            >
                                                <span>{{ $child->name }}</span>
                                                <span class="text-gray-400">{{ $child->products_count }}</span>
                                            </div>
                                        @endforeach
                                    </div>
                                @endif
                            @empty
                                <p class="text-sm italic text-gray-400">No categories defined</p>
                            @endforelse
                        </div>

                        {{-- Stock Alerts --}}
                        <div class="rounded-lg bg-white p-4 shadow">
                            <h3 class="mb-3 font-semibold text-gray-900">Stock Alerts</h3>
                            @foreach($stockAlerts as $alert)
                                <div
                                    wire:key="alert-{{ $alert->product_id }}"
                                    @class([
                                        'mb-2 rounded-md p-2 text-xs',
                                        'stock-critical' => $alert->quantity <= 0,
                                        'stock-low' => $alert->quantity > 0 && $alert->quantity <= $alert->reorder_point,
                                    ])
                                >
                                    <div class="font-medium">{{ $alert->product_name }}</div>
                                    <div class="mt-1 flex items-center justify-between">
                                        <span>
                                            @if($alert->quantity <= 0)
                                                <strong class="text-red-700">Out of Stock</strong>
                                            @else
                                                {{ $alert->quantity }} remaining
                                            @endif
                                        </span>
                                        @can('update', $alert->product)
                                            <button
                                                wire:click="reorder({{ $alert->product_id }})"
                                                class="text-blue-600 underline hover:text-blue-800"
                                            >
                                                Reorder
                                            </button>
                                        @endcan
                                    </div>
                                </div>
                            @endforeach

                            @includeWhen($stockAlerts->isEmpty(), 'inventory.partials.no-alerts')
                        </div>

                        {{-- Warehouse Filter --}}
                        <div class="rounded-lg bg-white p-4 shadow">
                            <h3 class="mb-3 font-semibold text-gray-900">Warehouse</h3>
                            <select
                                x-model="selectedWarehouse"
                                wire:model.live="warehouseFilter"
                                class="w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            >
                                <option value="all">All Warehouses</option>
                                @foreach($warehouses as $wh)
                                    <option value="{{ $wh['id'] }}">{{ $wh['name'] }} ({{ $wh['code'] }})</option>
                                @endforeach
                            </select>
                        </div>

                        @env('local')
                            <div class="rounded-lg border-2 border-dashed border-yellow-300 bg-yellow-50 p-4">
                                <p class="text-xs font-mono text-yellow-800">
                                    Debug: {{ $products->total() }} total, {{ $products->count() }} shown
                                    <br>Cache: {{ cache()->get('inventory_last_sync', 'never') }}
                                </p>
                            </div>
                        @endenv
                    </nav>
                </aside>

                {{-- Main Content --}}
                <section class="lg:col-span-3">
                    {{-- Search & Toolbar --}}
                    <div class="mb-4 flex flex-wrap items-center gap-3">
                        <div class="relative flex-1">
                            <x-icon name="search" class="pointer-events-none absolute left-3 top-1/2 size-5 -translate-y-1/2 text-gray-400" />
                            <input
                                type="search"
                                wire:model.live.debounce.300ms="search"
                                x-model="searchQuery"
                                placeholder="Search products by name, SKU, or barcode..."
                                class="w-full rounded-lg border-gray-300 py-2.5 pl-10 pr-4 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            >
                        </div>

                        <button
                            @click="showFilters = !showFilters"
                            @class([
                                'flex items-center rounded-lg border px-3 py-2.5 text-sm transition-colors',
                                'border-blue-500 bg-blue-50 text-blue-700' => $activeFiltersCount > 0,
                                'border-gray-300 text-gray-700 hover:bg-gray-50' => $activeFiltersCount === 0,
                            ])
                        >
                            <x-icon name="funnel" class="mr-2 size-4" />
                            Filters
                            @if($activeFiltersCount > 0)
                                <span class="ml-1.5 rounded-full bg-blue-600 px-1.5 py-0.5 text-xs text-white">
                                    {{ $activeFiltersCount }}
                                </span>
                            @endif
                        </button>

                        {{-- View Mode Toggle --}}
                        <div class="flex rounded-lg border border-gray-300 bg-white">
                            <button
                                @click="viewMode = 'table'"
                                :class="viewMode === 'table' ? 'bg-gray-100 text-gray-900' : 'text-gray-500'"
                                class="rounded-l-lg px-3 py-2"
                            >
                                <x-icon name="table-cells" class="size-5" />
                            </button>
                            <button
                                @click="viewMode = 'grid'"
                                :class="viewMode === 'grid' ? 'bg-gray-100 text-gray-900' : 'text-gray-500'"
                                class="rounded-r-lg px-3 py-2"
                            >
                                <x-icon name="squares-2x2" class="size-5" />
                            </button>
                        </div>
                    </div>

                    {{-- Expanded Filters Panel --}}
                    <div x-show="showFilters" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 -translate-y-2" x-transition:enter-end="opacity-100 translate-y-0" x-cloak class="mb-4 rounded-lg bg-white p-4 shadow">
                        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                            <div>
                                <label class="mb-1 block text-xs font-medium text-gray-700">Status</label>
                                <select wire:model.live="statusFilter" class="w-full rounded-md border-gray-300 text-sm">
                                    <option value="">All Statuses</option>
                                    @foreach($statusColors as $status => $color)
                                        <option value="{{ $status }}">{{ ucfirst($status) }}</option>
                                    @endforeach
                                </select>
                            </div>

                            <div>
                                <label class="mb-1 block text-xs font-medium text-gray-700">Price Range</label>
                                <div class="flex items-center space-x-2">
                                    <input
                                        type="number"
                                        wire:model.blur="minPrice"
                                        placeholder="Min"
                                        class="w-full rounded-md border-gray-300 text-sm"
                                        min="0"
                                        step="0.01"
                                    >
                                    <span class="text-gray-400">-</span>
                                    <input
                                        type="number"
                                        wire:model.blur="maxPrice"
                                        placeholder="Max"
                                        class="w-full rounded-md border-gray-300 text-sm"
                                        min="0"
                                        step="0.01"
                                    >
                                </div>
                            </div>

                            <div>
                                <label class="mb-1 block text-xs font-medium text-gray-700">Stock Level</label>
                                <select wire:model.live="stockFilter" class="w-full rounded-md border-gray-300 text-sm">
                                    <option value="">All Levels</option>
                                    <option value="out">Out of Stock</option>
                                    <option value="low">Low Stock</option>
                                    <option value="ok">In Stock</option>
                                    <option value="overstock">Overstocked</option>
                                </select>
                            </div>

                            <div>
                                <label class="mb-1 block text-xs font-medium text-gray-700">Supplier</label>
                                <select wire:model.live="supplierFilter" class="w-full rounded-md border-gray-300 text-sm">
                                    <option value="">All Suppliers</option>
                                    @each('inventory.partials.supplier-option', $suppliers, 'supplier')
                                </select>
                            </div>
                        </div>

                        <div class="mt-3 flex justify-end">
                            <button wire:click="clearFilters" class="text-sm text-blue-600 hover:text-blue-800">
                                Clear All Filters
                            </button>
                        </div>
                    </div>

                    {{-- Batch Actions Bar --}}
                    <div
                        x-show="showBatchActions"
                        x-transition
                        class="mb-4 flex items-center justify-between rounded-lg bg-blue-600 px-4 py-3 text-white shadow"
                    >
                        <span class="text-sm font-medium">
                            <span x-text="selectedItems.length"></span> item(s) selected
                        </span>
                        <div class="flex items-center space-x-2">
                            @can('update', App\Models\Product::class)
                                <button
                                    wire:click="batchUpdateStatus"
                                    class="rounded bg-blue-500 px-3 py-1.5 text-xs hover:bg-blue-400"
                                >
                                    Update Status
                                </button>
                                <button
                                    wire:click="batchTransfer"
                                    class="rounded bg-blue-500 px-3 py-1.5 text-xs hover:bg-blue-400"
                                >
                                    Transfer Stock
                                </button>
                            @endcan
                            @can('delete', App\Models\Product::class)
                                <button
                                    wire:click="batchDelete"
                                    wire:confirm="Are you sure you want to delete the selected products?"
                                    class="rounded bg-red-500 px-3 py-1.5 text-xs hover:bg-red-400"
                                >
                                    Delete
                                </button>
                            @endcan
                            <button @click="selectedItems = []" class="rounded px-3 py-1.5 text-xs hover:bg-blue-500">
                                Cancel
                            </button>
                        </div>
                    </div>

                    {{-- Products Table --}}
                    <div x-show="viewMode === 'table'" class="overflow-hidden rounded-lg bg-white shadow">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="w-12 px-4 py-3">
                                        <input
                                            type="checkbox"
                                            @change="selectedItems = $event.target.checked ? @json($products->pluck('id')) : []"
                                            :checked="selectedItems.length === {{ $products->count() }}"
                                            class="rounded border-gray-300"
                                        >
                                    </th>
                                    @foreach(['name' => 'Product', 'sku' => 'SKU', 'price' => 'Price', 'stock' => 'Stock', 'status' => 'Status'] as $field => $label)
                                        <th
                                            wire:click="sortBy('{{ $field }}')"
                                            class="cursor-pointer px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500 hover:text-gray-700"
                                        >
                                            <div class="flex items-center space-x-1">
                                                <span>{{ $label }}</span>
                                                @if($sortField === $field)
                                                    <x-icon
                                                        :name="$sortDirection === 'asc' ? 'chevron-up' : 'chevron-down'"
                                                        class="size-3"
                                                    />
                                                @endif
                                            </div>
                                        </th>
                                    @endforeach
                                    <th class="px-4 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                                        Actions
                                    </th>
                                </tr>
                            </thead>

                            <tbody class="divide-y divide-gray-200">
                                @forelse($products as $product)
                                    <tr
                                        wire:key="product-{{ $product->id }}"
                                        :class="selectedItems.includes({{ $product->id }}) ? 'bg-blue-50' : ''"
                                        class="transition-colors hover:bg-gray-50"
                                    >
                                        <td class="px-4 py-3">
                                            <input
                                                type="checkbox"
                                                value="{{ $product->id }}"
                                                x-model.number="selectedItems"
                                                class="rounded border-gray-300"
                                            >
                                        </td>
                                        <td class="px-4 py-3">
                                            <div class="flex items-center">
                                                @isset($product->thumbnail)
                                                    <img
                                                        src="{{ $product->thumbnail }}"
                                                        alt="{{ $product->name }}"
                                                        class="mr-3 size-10 rounded-md object-cover"
                                                        loading="lazy"
                                                    >
                                                @endisset
                                                <div>
                                                    <a
                                                        href="{{ route('products.show', $product) }}"
                                                        wire:navigate
                                                        class="font-medium text-gray-900 hover:text-blue-600"
                                                    >
                                                        {{ $product->name }}
                                                    </a>
                                                    @unless($product->variants->isEmpty())
                                                        <span class="ml-1 text-xs text-gray-400">
                                                            ({{ $product->variants->count() }} variants)
                                                        </span>
                                                    @endunless
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-4 py-3 font-mono text-sm text-gray-500">{{ $product->sku }}</td>
                                        <td class="px-4 py-3 text-sm">
                                            {{ $currencySymbol }}{{ number_format($product->price, 2) }}
                                            @if($product->compare_at_price)
                                                <br>
                                                <span class="text-xs text-gray-400 line-through">
                                                    {{ $currencySymbol }}{{ number_format($product->compare_at_price, 2) }}
                                                </span>
                                            @endif
                                        </td>
                                        <td class="px-4 py-3">
                                            @switch(true)
                                                @case($product->total_stock <= 0)
                                                    <x-badge color="red">Out of Stock</x-badge>
                                                    @break
                                                @case($product->total_stock <= $product->reorder_point)
                                                    <x-badge color="yellow">Low: {{ $product->total_stock }}</x-badge>
                                                    @break
                                                @default
                                                    <x-badge color="green">{{ $product->total_stock }}</x-badge>
                                            @endswitch
                                        </td>
                                        <td class="px-4 py-3">
                                            <x-badge :color="$statusColors[$product->status] ?? 'gray'">
                                                {{ ucfirst($product->status) }}
                                            </x-badge>
                                        </td>
                                        <td class="px-4 py-3 text-right">
                                            <div class="flex items-center justify-end space-x-1">
                                                @can('update', $product)
                                                    <button
                                                        wire:click="editProduct({{ $product->id }})"
                                                        class="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-blue-600"
                                                        title="Edit"
                                                    >
                                                        <x-icon name="pencil" class="size-4" />
                                                    </button>
                                                @endcan
                                                @cannot('update', $product)
                                                    <button
                                                        wire:click="viewProduct({{ $product->id }})"
                                                        class="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
                                                        title="View"
                                                    >
                                                        <x-icon name="eye" class="size-4" />
                                                    </button>
                                                @endcannot
                                                @can('delete', $product)
                                                    <button
                                                        wire:click="deleteProduct({{ $product->id }})"
                                                        wire:confirm="Delete {{ $product->name }}? This action cannot be undone."
                                                        class="rounded p-1 text-gray-400 hover:bg-red-50 hover:text-red-600"
                                                        title="Delete"
                                                    >
                                                        <x-icon name="trash" class="size-4" />
                                                    </button>
                                                @endcan
                                            </div>
                                        </td>
                                    </tr>

                                    {{-- Expandable variant rows --}}
                                    @if($expandedProduct === $product->id)
                                        @foreach($product->variants as $variant)
                                            <tr wire:key="variant-{{ $variant->id }}" class="bg-gray-50">
                                                <td class="px-4 py-2"></td>
                                                <td class="px-4 py-2 pl-16 text-sm text-gray-600">
                                                    {{ $variant->name }}
                                                    @if($loop->last)
                                                        <hr class="mt-2">
                                                    @endif
                                                </td>
                                                <td class="px-4 py-2 font-mono text-xs text-gray-400">{{ $variant->sku }}</td>
                                                <td class="px-4 py-2 text-sm">
                                                    @if($variant->price !== $product->price)
                                                        {{ $currencySymbol }}{{ number_format($variant->price, 2) }}
                                                    @else
                                                        <span class="text-gray-400">—</span>
                                                    @endif
                                                </td>
                                                <td class="px-4 py-2 text-sm">{{ $variant->stock }}</td>
                                                <td class="px-4 py-2">
                                                    <span @class([
                                                        'inline-block size-3 rounded-full',
                                                        'bg-green-400' => $variant->is_active,
                                                        'bg-gray-300' => !$variant->is_active,
                                                    ])></span>
                                                </td>
                                                <td></td>
                                            </tr>
                                        @endforeach
                                    @endif
                                @empty
                                    <tr>
                                        <td colspan="7" class="px-4 py-12 text-center">
                                            <x-icon name="cube" class="mx-auto size-12 text-gray-300" />
                                            <h3 class="mt-2 text-sm font-medium text-gray-900">No products found</h3>
                                            <p class="mt-1 text-sm text-gray-500">
                                                @if($search)
                                                    No results for <strong>"{{ $search }}"</strong>. Try a different search term.
                                                @else
                                                    Get started by adding your first product.
                                                @endif
                                            </p>
                                            @can('create', App\Models\Product::class)
                                                <x-button variant="primary" class="mt-4" @click="showProductModal = true">
                                                    <x-icon name="plus" class="mr-1 size-4" />
                                                    Add Product
                                                </x-button>
                                            @endcan
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>

                        {{-- Pagination --}}
                        @if($products->hasPages())
                            <div class="border-t border-gray-200 bg-gray-50 px-4 py-3">
                                {{ $products->links() }}
                            </div>
                        @endif
                    </div>

                    {{-- Grid View --}}
                    <div x-show="viewMode === 'grid'" x-cloak class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                        @foreach($products as $product)
                            <div
                                wire:key="grid-{{ $product->id }}"
                                class="group overflow-hidden rounded-lg bg-white shadow transition-shadow hover:shadow-md"
                            >
                                <div class="relative aspect-square bg-gray-100">
                                    @isset($product->thumbnail)
                                        <img
                                            src="{{ $product->thumbnail }}"
                                            alt="{{ $product->name }}"
                                            class="size-full object-cover"
                                            loading="lazy"
                                        >
                                    @endisset
                                    <div class="absolute right-2 top-2">
                                        <x-badge :color="$statusColors[$product->status] ?? 'gray'">
                                            {{ ucfirst($product->status) }}
                                        </x-badge>
                                    </div>
                                </div>
                                <div class="p-4">
                                    <h3 class="truncate font-medium text-gray-900">{{ $product->name }}</h3>
                                    <p class="mt-1 text-sm text-gray-500">{{ $product->sku }}</p>
                                    <div class="mt-2 flex items-center justify-between">
                                        <span class="text-lg font-bold text-gray-900">
                                            {{ $currencySymbol }}{{ number_format($product->price, 2) }}
                                        </span>
                                        <span @class([
                                            'text-xs font-medium',
                                            'text-red-600' => $product->total_stock <= 0,
                                            'text-yellow-600' => $product->total_stock > 0 && $product->total_stock <= $product->reorder_point,
                                            'text-green-600' => $product->total_stock > $product->reorder_point,
                                        ])>
                                            {{ $product->total_stock }} in stock
                                        </span>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </section>
            </div>
        </main>

        {{-- Product Modal --}}
        <div
            x-show="showProductModal"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100"
            x-transition:leave="transition ease-in duration-200"
            x-transition:leave-start="opacity-100"
            x-transition:leave-end="opacity-0"
            @keydown.escape.window="showProductModal = false"
            x-cloak
            class="fixed inset-0 z-50 overflow-y-auto"
        >
            <div class="flex min-h-screen items-center justify-center px-4">
                <div class="fixed inset-0 bg-gray-500 bg-opacity-75" @click="showProductModal = false"></div>

                <div
                    class="relative w-full max-w-2xl transform rounded-xl bg-white shadow-2xl transition-all"
                    @click.stop
                    x-transition:enter="transition ease-out duration-300"
                    x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                    x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
                >
                    <form wire:submit.prevent="saveProduct">
                        @csrf
                        <div class="border-b border-gray-200 px-6 py-4">
                            <h2 class="text-lg font-semibold text-gray-900" x-text="editingProduct ? 'Edit Product' : 'New Product'"></h2>
                        </div>

                        <div class="space-y-4 px-6 py-4">
                            <div>
                                <label for="product-name" class="block text-sm font-medium text-gray-700">
                                    Product Name <span class="text-red-500">*</span>
                                </label>
                                <input
                                    id="product-name"
                                    type="text"
                                    wire:model="form.name"
                                    @required(true)
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                >
                                @error('form.name')
                                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                @enderror
                            </div>

                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label for="product-sku" class="block text-sm font-medium text-gray-700">SKU</label>
                                    <input
                                        id="product-sku"
                                        type="text"
                                        wire:model="form.sku"
                                        class="mt-1 block w-full rounded-md border-gray-300 font-mono shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                    >
                                    @error('form.sku')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label for="product-price" class="block text-sm font-medium text-gray-700">Price</label>
                                    <input
                                        id="product-price"
                                        type="number"
                                        wire:model="form.price"
                                        step="0.01"
                                        min="0"
                                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                    >
                                    @error('form.price')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                            </div>

                            <div>
                                <label for="product-category" class="block text-sm font-medium text-gray-700">Category</label>
                                <select
                                    id="product-category"
                                    wire:model="form.category_id"
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                >
                                    <option value="">Select category</option>
                                    @foreach($categories as $cat)
                                        <option value="{{ $cat->id }}" @selected(old('category_id') == $cat->id)>
                                            {{ $cat->name }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div>
                                <label for="product-description" class="block text-sm font-medium text-gray-700">Description</label>
                                <textarea
                                    id="product-description"
                                    wire:model="form.description"
                                    rows="4"
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                    placeholder="Enter product description..."
                                ></textarea>
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-gray-700">Status</label>
                                <div class="mt-2 flex space-x-4">
                                    @for($i = 0; $i < count($statusColors); $i++)
                                        @php $statusKey = array_keys($statusColors)[$i]; @endphp
                                        <label class="flex items-center">
                                            <input
                                                type="radio"
                                                wire:model="form.status"
                                                value="{{ $statusKey }}"
                                                @checked($i === 0)
                                                class="border-gray-300 text-blue-600 focus:ring-blue-500"
                                            >
                                            <span class="ml-2 text-sm text-gray-700">{{ ucfirst($statusKey) }}</span>
                                        </label>
                                    @endfor
                                </div>
                            </div>
                        </div>

                        <div class="flex justify-end space-x-3 border-t border-gray-200 px-6 py-4">
                            <x-button type="button" variant="outline" @click="showProductModal = false">
                                Cancel
                            </x-button>
                            <x-button type="submit" variant="primary" wire:loading.attr="disabled">
                                <span wire:loading.remove>Save Product</span>
                                <span wire:loading>Saving...</span>
                            </x-button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        @includeIf('inventory.partials.import-modal')
    </div>

    @once
        @push('scripts')
            <script>
                document.addEventListener('livewire:initialized', () => {
                    Livewire.on('product-saved', () => {
                        Alpine.store('notifications').add('Product saved successfully', 'success');
                    });
                    Livewire.on('product-deleted', () => {
                        Alpine.store('notifications').add('Product deleted', 'info');
                    });
                });
            </script>
        @endpush
    @endonce

    @production
        <!-- Analytics tracking for inventory page -->
        @include('analytics.pageview', ['page' => 'inventory'])
    @endproduction
@endsection
