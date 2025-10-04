{{--
---
features:
  - foreach_directive
  - component_tags
  - wire_key
  - wire_click
description: Product catalog with interactive cards using Livewire keys and click handlers
complexity: moderate
line_count: 65
--}}

<div class="product-catalog">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        @foreach ($products as $product)
            <x-card
                wire:key="product-{{ $product->id }}"
                class="product-card hover:shadow-lg transition-shadow"
            >
                <x-slot:header>
                    <h3 class="text-xl font-bold">{{ $product->name }}</h3>
                    <span class="text-sm text-gray-500">{{ $product->category }}</span>
                </x-slot:header>

                <div class="product-content">
                    <img
                        src="{{ $product->image }}"
                        alt="{{ $product->name }}"
                        class="w-full h-48 object-cover rounded"
                    >

                    <p class="mt-4 text-gray-700">
                        {{ Str::limit($product->description, 100) }}
                    </p>

                    <div class="mt-4 flex items-center justify-between">
                        <span class="text-2xl font-bold text-primary">
                            ${{ number_format($product->price, 2) }}
                        </span>

                        @if ($product->stock > 0)
                            <span class="text-green-600 text-sm">
                                {{ $product->stock }} in stock
                            </span>
                        @else
                            <span class="text-red-600 text-sm">Out of stock</span>
                        @endif
                    </div>
                </div>

                <x-slot:footer>
                    <div class="flex gap-2">
                        <button
                            wire:click="addToCart({{ $product->id }})"
                            class="btn btn-primary flex-1"
                            @if ($product->stock === 0) disabled @endif
                        >
                            Add to Cart
                        </button>

                        <button
                            wire:click="toggleWishlist({{ $product->id }})"
                            class="btn btn-outline"
                        >
                            @if (in_array($product->id, $wishlist))
                                <span class="text-red-500">♥</span>
                            @else
                                <span class="text-gray-400">♡</span>
                            @endif
                        </button>
                    </div>
                </x-slot:footer>
            </x-card>
        @endforeach
    </div>
</div>
