---
description: "Complex modal form with validation, file uploads, and transitions"
features:
  - "Custom component <x-modal> with slots"
  - "Livewire wire:submit for form handling"
  - "Livewire wire:model for two-way binding"
  - "Alpine.js x-data for modal state"
  - "Alpine.js x-transition for animations"
  - "@error directive for field validation"
  - "File upload with preview"
  - "Dynamic field toggling"
level: 3
complexity: complex
line_count: ~135
---
<div x-data="{ open: @entangle('showModal'), imagePreview: null }">
    {{-- Trigger Button --}}
    <button @click="open = true" class="btn-primary">
        <svg class="h-5 w-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
        </svg>
        Create New Product
    </button>

    {{-- Modal Component --}}
    <x-modal :show="$showModal" max-width="2xl">
        <x-slot name="title">
            <div class="flex items-center justify-between">
                <h3 class="text-lg font-medium text-gray-900">
                    {{ $editMode ? 'Edit Product' : 'Create New Product' }}
                </h3>
                <button @click="open = false" class="text-gray-400 hover:text-gray-500">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>
        </x-slot>

        <x-slot name="content">
            <form wire:submit.prevent="saveProduct">
                <div class="space-y-6">
                    {{-- Product Name --}}
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700">
                            Product Name <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            id="name"
                            wire:model.blur="form.name"
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 @error('form.name') border-red-300 @enderror"
                            placeholder="Enter product name"
                        >
                        @error('form.name')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Description --}}
                    <div>
                        <label for="description" class="block text-sm font-medium text-gray-700">
                            Description
                        </label>
                        <textarea
                            id="description"
                            wire:model.blur="form.description"
                            rows="4"
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 @error('form.description') border-red-300 @enderror"
                            placeholder="Enter product description"
                        ></textarea>
                        @error('form.description')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Price and Category Grid --}}
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label for="price" class="block text-sm font-medium text-gray-700">
                                Price <span class="text-red-500">*</span>
                            </label>
                            <div class="mt-1 relative rounded-md shadow-sm">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <span class="text-gray-500 sm:text-sm">$</span>
                                </div>
                                <input
                                    type="number"
                                    id="price"
                                    wire:model.blur="form.price"
                                    step="0.01"
                                    min="0"
                                    class="pl-7 block w-full rounded-md border-gray-300 focus:border-blue-500 focus:ring-blue-500 @error('form.price') border-red-300 @enderror"
                                    placeholder="0.00"
                                >
                            </div>
                            @error('form.price')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div>
                            <label for="category" class="block text-sm font-medium text-gray-700">
                                Category <span class="text-red-500">*</span>
                            </label>
                            <select
                                id="category"
                                wire:model.live="form.category_id"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 @error('form.category_id') border-red-300 @enderror"
                            >
                                <option value="">Select a category</option>
                                @foreach($categories as $category)
                                    <option value="{{ $category->id }}">{{ $category->name }}</option>
                                @endforeach
                            </select>
                            @error('form.category_id')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>
                    </div>

                    {{-- Stock and SKU --}}
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label for="stock" class="block text-sm font-medium text-gray-700">
                                Stock Quantity
                            </label>
                            <input
                                type="number"
                                id="stock"
                                wire:model.blur="form.stock"
                                min="0"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                placeholder="0"
                            >
                        </div>

                        <div>
                            <label for="sku" class="block text-sm font-medium text-gray-700">
                                SKU
                            </label>
                            <input
                                type="text"
                                id="sku"
                                wire:model.blur="form.sku"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                placeholder="PROD-001"
                            >
                        </div>
                    </div>

                    {{-- Product Image --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">
                            Product Image
                        </label>
                        <div class="flex items-start space-x-4">
                            <div class="flex-shrink-0">
                                <template x-if="imagePreview">
                                    <img :src="imagePreview" class="h-32 w-32 object-cover rounded-lg border-2 border-gray-300">
                                </template>
                                <template x-if="!imagePreview && '{{ $form->image_url ?? '' }}'">
                                    <img src="{{ $form->image_url ?? '' }}" class="h-32 w-32 object-cover rounded-lg border-2 border-gray-300">
                                </template>
                                <template x-if="!imagePreview && !'{{ $form->image_url ?? '' }}'">
                                    <div class="h-32 w-32 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center">
                                        <svg class="h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                                        </svg>
                                    </div>
                                </template>
                            </div>
                            <div class="flex-1">
                                <input
                                    type="file"
                                    wire:model="form.image"
                                    accept="image/*"
                                    class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                                    @change="imagePreview = URL.createObjectURL($event.target.files[0])"
                                >
                                <p class="mt-1 text-xs text-gray-500">PNG, JPG, GIF up to 10MB</p>
                                @error('form.image')
                                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                @enderror
                            </div>
                        </div>
                    </div>

                    {{-- Additional Options --}}
                    <div class="space-y-4">
                        <div class="flex items-center">
                            <input
                                type="checkbox"
                                id="featured"
                                wire:model.live="form.is_featured"
                                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            >
                            <label for="featured" class="ml-2 block text-sm text-gray-900">
                                Feature this product on homepage
                            </label>
                        </div>

                        <div class="flex items-center">
                            <input
                                type="checkbox"
                                id="active"
                                wire:model.live="form.is_active"
                                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            >
                            <label for="active" class="ml-2 block text-sm text-gray-900">
                                Active (visible to customers)
                            </label>
                        </div>
                    </div>

                    {{-- Discount Section (conditionally shown) --}}
                    <div x-show="$wire.form.is_featured" x-transition class="bg-blue-50 p-4 rounded-lg">
                        <label for="discount" class="block text-sm font-medium text-gray-700 mb-2">
                            Featured Discount (%)
                        </label>
                        <input
                            type="number"
                            id="discount"
                            wire:model.blur="form.discount_percentage"
                            min="0"
                            max="100"
                            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            placeholder="10"
                        >
                        @error('form.discount_percentage')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </form>
        </x-slot>

        <x-slot name="footer">
            <div class="flex justify-end space-x-3">
                <button
                    type="button"
                    @click="open = false; imagePreview = null"
                    class="btn-secondary"
                >
                    Cancel
                </button>
                <button
                    type="button"
                    wire:click="saveProduct"
                    wire:loading.attr="disabled"
                    class="btn-primary"
                >
                    <span wire:loading.remove wire:target="saveProduct">
                        {{ $editMode ? 'Update Product' : 'Create Product' }}
                    </span>
                    <span wire:loading wire:target="saveProduct">
                        <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Saving...
                    </span>
                </button>
            </div>
        </x-slot>
    </x-modal>
</div>
