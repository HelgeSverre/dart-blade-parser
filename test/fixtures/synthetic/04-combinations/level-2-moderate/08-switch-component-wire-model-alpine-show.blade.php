{{--
---
features:
  - switch_directive
  - component_tags
  - wire_model
  - alpine_x_show
description: Dynamic UI with switch-case rendering, components, and conditional visibility
complexity: moderate
line_count: 80
--}}

<div
    x-data="{
        viewMode: @entangle('viewMode'),
        showFilters: false,
        selectedCategory: 'all'
    }"
    class="content-browser"
>
    <div class="browser-header mb-6">
        <div class="flex items-center justify-between mb-4">
            <h2 class="text-2xl font-bold">Content Library</h2>

            <div class="view-switcher flex gap-2 border rounded-lg p-1">
                <button
                    wire:click="setViewMode('grid')"
                    :class="viewMode === 'grid' ? 'bg-blue-500 text-white' : 'text-gray-600'"
                    class="px-4 py-2 rounded transition"
                >
                    Grid
                </button>
                <button
                    wire:click="setViewMode('list')"
                    :class="viewMode === 'list' ? 'bg-blue-500 text-white' : 'text-gray-600'"
                    class="px-4 py-2 rounded transition"
                >
                    List
                </button>
                <button
                    wire:click="setViewMode('table')"
                    :class="viewMode === 'table' ? 'bg-blue-500 text-white' : 'text-gray-600'"
                    class="px-4 py-2 rounded transition"
                >
                    Table
                </button>
            </div>
        </div>

        <button
            @click="showFilters = !showFilters"
            class="btn btn-outline"
        >
            <span x-text="showFilters ? 'Hide Filters' : 'Show Filters'"></span>
        </button>

        <div
            x-show="showFilters"
            x-transition:enter="transition ease-out duration-200"
            x-transition:enter-start="opacity-0 transform -translate-y-2"
            x-transition:enter-end="opacity-100 transform translate-y-0"
            class="filters-panel mt-4 p-4 bg-gray-50 rounded-lg"
        >
            <div class="grid grid-cols-3 gap-4">
                <div>
                    <label class="block text-sm font-medium mb-2">Category</label>
                    <select wire:model.live="filterCategory" class="form-select w-full">
                        <option value="all">All Categories</option>
                        <option value="documents">Documents</option>
                        <option value="images">Images</option>
                        <option value="videos">Videos</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Date Range</label>
                    <select wire:model.live="filterDateRange" class="form-select w-full">
                        <option value="all">All Time</option>
                        <option value="today">Today</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Sort By</label>
                    <select wire:model.live="sortBy" class="form-select w-full">
                        <option value="date">Date</option>
                        <option value="name">Name</option>
                        <option value="size">Size</option>
                    </select>
                </div>
            </div>
        </div>
    </div>

    <div class="content-display">
        @switch($viewMode)
            @case('grid')
                <div class="grid grid-cols-4 gap-6">
                    @foreach ($items as $item)
                        <x-content-card
                            wire:key="grid-{{ $item->id }}"
                            :item="$item"
                            layout="grid"
                        >
                            <x-slot:actions>
                                <button wire:click="viewItem({{ $item->id }})" class="btn-icon">
                                    View
                                </button>
                            </x-slot:actions>
                        </x-content-card>
                    @endforeach
                </div>
                @break

            @case('list')
                <div class="space-y-3">
                    @foreach ($items as $item)
                        <x-content-card
                            wire:key="list-{{ $item->id }}"
                            :item="$item"
                            layout="list"
                        >
                            <x-slot:metadata>
                                <span>{{ $item->size }}</span>
                                <span>{{ $item->created_at->format('M d, Y') }}</span>
                            </x-slot:metadata>
                        </x-content-card>
                    @endforeach
                </div>
                @break

            @case('table')
                <x-table class="w-full">
                    <x-slot:header>
                        <th>Name</th>
                        <th>Type</th>
                        <th>Size</th>
                        <th>Modified</th>
                        <th>Actions</th>
                    </x-slot:header>

                    @foreach ($items as $item)
                        <tr wire:key="table-{{ $item->id }}">
                            <td>{{ $item->name }}</td>
                            <td>{{ $item->type }}</td>
                            <td>{{ $item->size }}</td>
                            <td>{{ $item->updated_at->format('M d, Y H:i') }}</td>
                            <td>
                                <button wire:click="downloadItem({{ $item->id }})" class="text-blue-600">
                                    Download
                                </button>
                            </td>
                        </tr>
                    @endforeach
                </x-table>
                @break

            @default
                <p class="text-gray-500">Please select a view mode</p>
        @endswitch
    </div>
</div>
