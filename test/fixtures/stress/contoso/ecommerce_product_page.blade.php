{{-- E-Commerce Product Detail Page - MEGA stress fixture --}}
{{-- Exercises every Blade feature: directives, components, Livewire, Alpine, raw elements --}}
@extends('layouts.shop')

@section('title', $product->name . ' - ' . config('app.name'))

@section('meta', $product->meta_description)

@inject('cartService', 'App\Services\CartService')

@vite(['resources/css/app.css', 'resources/js/app.js'])

@push('meta')
    <meta property="og:title" content="{{ $product->name }}">
    <meta property="og:description" content="{{ $product->meta_description }}">
    <meta property="og:image" content="{{ $product->featured_image }}">
    <meta property="og:type" content="product">
    <link rel="canonical" href="{{ route('products.show', $product) }}">
@endpush

@php
    $hasVariants = $product->variants->isNotEmpty();
    $defaultVariant = $product->variants->first();
    $maxQty = min($product->stock, 10);
    $avgRating = $reviews->avg('rating');
    $ratingCounts = [];
    for ($star = 5; $star >= 1; $star--) {
        $ratingCounts[$star] = $reviews->where('rating', $star)->count();
    }
    $breadcrumbs = [
        ['label' => 'Home', 'url' => route('home')],
        ['label' => $product->category->parent?->name, 'url' => $product->category->parent?->url],
        ['label' => $product->category->name, 'url' => $product->category->url],
        ['label' => $product->name, 'url' => null],
    ];
@endphp

@section('content')
    {{-- Structured Data --}}
    @push('head')
        <script type="application/ld+json">
            @json([
                '@context' => 'https://schema.org',
                '@type' => 'Product',
                'name' => $product->name,
                'image' => $product->images->pluck('url'),
                'description' => $product->description,
                'sku' => $product->sku,
                'brand' => ['@type' => 'Brand', 'name' => $product->brand?->name],
                'offers' => [
                    '@type' => 'Offer',
                    'price' => $product->price,
                    'priceCurrency' => 'USD',
                    'availability' => $product->in_stock ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
                ],
            ], JSON_PRETTY_PRINT)
        </script>
    @endpush

    <div
        class="min-h-screen bg-white"
        x-data="{
            selectedVariant: @json($defaultVariant?->id),
            selectedColor: @json($defaultVariant?->color),
            selectedSize: @json($defaultVariant?->size),
            quantity: 1,
            currentImage: 0,
            showZoom: false,
            zoomX: 0,
            zoomY: 0,
            activeTab: 'description',
            showSizeGuide: false,
            showShareMenu: false,
            isWishlisted: @json($isWishlisted),
            showReviewForm: false,
            reviewRating: 0,
            showAllSpecs: false,
            recentlyViewed: [],
        }"
        x-init="
            recentlyViewed = JSON.parse(localStorage.getItem('recently_viewed') || '[]');
            $watch('selectedColor', () => updateVariant());
            $watch('selectedSize', () => updateVariant());
        "
    >
        {{-- Breadcrumbs --}}
        <nav class="mx-auto max-w-7xl px-4 py-3 sm:px-6 lg:px-8">
            <ol class="flex items-center space-x-2 text-sm">
                @foreach($breadcrumbs as $crumb)
                    @if($loop->last)
                        <li class="text-gray-500">{{ $crumb['label'] }}</li>
                    @else
                        @isset($crumb['url'])
                            <li>
                                <a href="{{ $crumb['url'] }}" class="text-gray-400 hover:text-gray-600">
                                    {{ $crumb['label'] }}
                                </a>
                            </li>
                            <li><x-icon name="chevron-right" class="size-3 text-gray-300" /></li>
                        @endisset
                    @endif
                @endforeach
            </ol>
        </nav>

        {{-- Main Product Section --}}
        <main class="mx-auto max-w-7xl px-4 pb-16 sm:px-6 lg:px-8">
            <div class="lg:grid lg:grid-cols-2 lg:gap-x-12">
                {{-- Image Gallery --}}
                <section class="relative" aria-label="Product images">
                    {{-- Main Image --}}
                    <div
                        class="relative aspect-square overflow-hidden rounded-2xl bg-gray-100"
                        @mousemove="if(showZoom) { zoomX = $event.offsetX / $el.offsetWidth * 100; zoomY = $event.offsetY / $el.offsetHeight * 100; }"
                        @mouseenter="showZoom = true"
                        @mouseleave="showZoom = false"
                    >
                        @foreach($product->images as $image)
                            <img
                                x-show="currentImage === {{ $loop->index }}"
                                x-transition:enter="transition ease-out duration-300"
                                x-transition:enter-start="opacity-0"
                                x-transition:enter-end="opacity-100"
                                src="{{ $image->url }}"
                                alt="{{ $product->name }} - Image {{ $loop->iteration }}"
                                class="size-full object-cover"
                                @if($loop->first) loading="eager" @else loading="lazy" @endif
                            >
                        @endforeach

                        {{-- Zoom Overlay --}}
                        <div
                            x-show="showZoom"
                            x-cloak
                            class="pointer-events-none absolute inset-0 bg-cover bg-no-repeat"
                            :style="`background-image: url('${@json($product->images->pluck('zoom_url'))}[currentImage]'); background-position: ${zoomX}% ${zoomY}%; background-size: 200%;`"
                        ></div>

                        {{-- Sale Badge --}}
                        @if($product->on_sale)
                            <div class="absolute left-4 top-4">
                                <x-badge color="red" size="lg">
                                    -{{ $product->discount_percent }}%
                                </x-badge>
                            </div>
                        @endif

                        @production
                            {{-- Watermark for production images --}}
                        @endproduction

                        {{-- Navigation Arrows --}}
                        @if($product->images->count() > 1)
                            <button
                                @click="currentImage = currentImage > 0 ? currentImage - 1 : {{ $product->images->count() - 1 }}"
                                class="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-2 shadow-lg backdrop-blur-sm hover:bg-white"
                            >
                                <x-icon name="chevron-left" class="size-5" />
                            </button>
                            <button
                                @click="currentImage = currentImage < {{ $product->images->count() - 1 }} ? currentImage + 1 : 0"
                                class="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-2 shadow-lg backdrop-blur-sm hover:bg-white"
                            >
                                <x-icon name="chevron-right" class="size-5" />
                            </button>
                        @endif
                    </div>

                    {{-- Thumbnails --}}
                    <div class="mt-4 flex gap-3 overflow-x-auto pb-2">
                        @foreach($product->images as $image)
                            <button
                                @click="currentImage = {{ $loop->index }}"
                                :class="currentImage === {{ $loop->index }}
                                    ? 'ring-2 ring-blue-500 ring-offset-2'
                                    : 'ring-1 ring-gray-200 hover:ring-gray-300'"
                                class="size-20 flex-shrink-0 overflow-hidden rounded-lg"
                            >
                                <img
                                    src="{{ $image->thumbnail_url }}"
                                    alt=""
                                    class="size-full object-cover"
                                    loading="lazy"
                                >
                            </button>
                        @endforeach
                    </div>
                </section>

                {{-- Product Info --}}
                <section class="mt-8 lg:mt-0">
                    {{-- Brand --}}
                    @isset($product->brand)
                        <a
                            href="{{ route('brands.show', $product->brand) }}"
                            wire:navigate
                            class="text-sm font-medium uppercase tracking-wider text-blue-600 hover:text-blue-800"
                        >
                            {{ $product->brand->name }}
                        </a>
                    @endisset

                    {{-- Title --}}
                    <h1 class="mt-1 text-3xl font-bold text-gray-900">{{ $product->name }}</h1>

                    {{-- Rating Summary --}}
                    @if($reviews->count() > 0)
                        <div class="mt-3 flex items-center gap-3">
                            <div class="flex items-center">
                                @for($star = 1; $star <= 5; $star++)
                                    <x-icon
                                        name="star"
                                        @class([
                                            'size-5',
                                            'text-yellow-400' => $star <= round($avgRating),
                                            'text-gray-200' => $star > round($avgRating),
                                        ])
                                    />
                                @endfor
                            </div>
                            <span class="text-sm text-gray-500">
                                {{ number_format($avgRating, 1) }} ({{ $reviews->count() }} {{ Str::plural('review', $reviews->count()) }})
                            </span>
                        </div>
                    @endif

                    {{-- Price --}}
                    <div class="mt-4">
                        @if($product->on_sale)
                            <div class="flex items-baseline gap-3">
                                <span class="text-3xl font-bold text-red-600">${{ number_format($product->sale_price, 2) }}</span>
                                <span class="text-lg text-gray-400 line-through">${{ number_format($product->price, 2) }}</span>
                                <x-badge color="red">Save ${{ number_format($product->price - $product->sale_price, 2) }}</x-badge>
                            </div>
                        @else
                            <span class="text-3xl font-bold text-gray-900">${{ number_format($product->price, 2) }}</span>
                        @endif

                        @auth
                            @if($product->member_price && $product->member_price < $product->effective_price)
                                <p class="mt-1 text-sm text-green-600">
                                    <x-icon name="tag" class="inline size-4" />
                                    Member price: <strong>${{ number_format($product->member_price, 2) }}</strong>
                                </p>
                            @endif
                        @endauth

                        @guest
                            @if($product->member_price)
                                <p class="mt-1 text-sm text-gray-500">
                                    <a href="{{ route('login') }}" class="text-blue-600 underline">Sign in</a> for member pricing
                                </p>
                            @endif
                        @endguest
                    </div>

                    {{-- Short Description --}}
                    <div class="mt-4 text-sm leading-relaxed text-gray-600">
                        {!! $product->short_description !!}
                    </div>

                    <hr class="my-6">

                    {{-- Variant Selection --}}
                    @if($hasVariants)
                        {{-- Color Selector --}}
                        @if($product->available_colors->isNotEmpty())
                            <div class="mb-6">
                                <div class="flex items-center justify-between">
                                    <label class="text-sm font-medium text-gray-900">
                                        Color: <span x-text="selectedColor" class="font-normal text-gray-500"></span>
                                    </label>
                                </div>
                                <div class="mt-3 flex gap-3">
                                    @foreach($product->available_colors as $color)
                                        <button
                                            @click="selectedColor = '{{ $color->name }}'"
                                            :class="selectedColor === '{{ $color->name }}'
                                                ? 'ring-2 ring-blue-500 ring-offset-2'
                                                : 'ring-1 ring-gray-300'"
                                            @style(["background-color: {$color->hex}"])
                                            class="size-10 rounded-full"
                                            title="{{ $color->name }}"
                                            @disabled(!$color->in_stock)
                                        >
                                            @unless($color->in_stock)
                                                <span class="flex size-full items-center justify-center text-white">
                                                    <x-icon name="x-mark" class="size-5" />
                                                </span>
                                            @endunless
                                        </button>
                                    @endforeach
                                </div>
                            </div>
                        @endif

                        {{-- Size Selector --}}
                        @if($product->available_sizes->isNotEmpty())
                            <div class="mb-6">
                                <div class="flex items-center justify-between">
                                    <label class="text-sm font-medium text-gray-900">Size</label>
                                    <button
                                        @click="showSizeGuide = true"
                                        class="text-sm text-blue-600 underline hover:text-blue-800"
                                    >
                                        Size guide
                                    </button>
                                </div>
                                <div class="mt-3 grid grid-cols-5 gap-2">
                                    @foreach($product->available_sizes as $size)
                                        <button
                                            @click="selectedSize = '{{ $size->value }}'"
                                            :class="selectedSize === '{{ $size->value }}'
                                                ? 'border-blue-500 bg-blue-50 text-blue-700'
                                                : '{{ $size->in_stock ? "border-gray-300 text-gray-700 hover:border-gray-400" : "border-gray-200 bg-gray-50 text-gray-300 cursor-not-allowed" }}'"
                                            class="rounded-lg border px-3 py-2 text-center text-sm font-medium"
                                            @disabled(!$size->in_stock)
                                        >
                                            {{ $size->value }}
                                        </button>
                                    @endforeach
                                </div>
                                @error('variant')
                                    <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                                @enderror
                            </div>
                        @endif
                    @endif

                    {{-- Add to Cart Form --}}
                    <form wire:submit.prevent="addToCart" class="mt-6">
                        @csrf
                        <input type="hidden" name="variant_id" x-bind:value="selectedVariant">

                        {{-- Stock Status --}}
                        <div class="mb-4">
                            @if($product->in_stock)
                                @if($product->stock <= 5)
                                    <p class="flex items-center text-sm text-orange-600">
                                        <x-icon name="exclamation-triangle" class="mr-1.5 size-4" />
                                        Only <strong>{{ $product->stock }}</strong> left in stock — order soon
                                    </p>
                                @else
                                    <p class="flex items-center text-sm text-green-600">
                                        <x-icon name="check-circle" class="mr-1.5 size-4" />
                                        In Stock
                                    </p>
                                @endif
                            @else
                                <p class="flex items-center text-sm text-red-600">
                                    <x-icon name="x-circle" class="mr-1.5 size-4" />
                                    Out of Stock
                                </p>
                            @endif
                        </div>

                        {{-- Quantity + Add to Cart --}}
                        <div class="flex items-stretch gap-3">
                            <div class="flex items-center rounded-lg border border-gray-300">
                                <button
                                    type="button"
                                    @click="if(quantity > 1) quantity--"
                                    class="px-3 py-2 text-gray-500 hover:text-gray-700"
                                    :disabled="quantity <= 1"
                                >
                                    <x-icon name="minus" class="size-4" />
                                </button>
                                <input
                                    type="number"
                                    x-model.number="quantity"
                                    wire:model.number="quantity"
                                    min="1"
                                    max="{{ $maxQty }}"
                                    @readonly(!$product->in_stock)
                                    class="w-16 border-0 text-center text-sm focus:ring-0"
                                >
                                <button
                                    type="button"
                                    @click="if(quantity < {{ $maxQty }}) quantity++"
                                    class="px-3 py-2 text-gray-500 hover:text-gray-700"
                                    :disabled="quantity >= {{ $maxQty }}"
                                >
                                    <x-icon name="plus" class="size-4" />
                                </button>
                            </div>

                            <x-button
                                type="submit"
                                variant="primary"
                                size="lg"
                                class="flex-1"
                                @disabled(!$product->in_stock)
                                wire:loading.attr="disabled"
                            >
                                <span wire:loading.remove wire:target="addToCart">
                                    <x-icon name="shopping-cart" class="mr-2 inline size-5" />
                                    Add to Cart
                                </span>
                                <span wire:loading wire:target="addToCart">Adding...</span>
                            </x-button>

                            {{-- Wishlist Toggle --}}
                            @auth
                                <button
                                    type="button"
                                    wire:click="toggleWishlist"
                                    @click="isWishlisted = !isWishlisted"
                                    class="rounded-lg border border-gray-300 px-3 transition-colors hover:bg-gray-50"
                                    :class="isWishlisted ? 'text-red-500' : 'text-gray-400'"
                                >
                                    <x-icon name="heart" class="size-6" x-bind:class="isWishlisted ? 'fill-current' : ''" />
                                </button>
                            @endauth
                        </div>

                        @error('quantity')
                            <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </form>

                    {{-- Delivery Estimation --}}
                    <div class="mt-6 rounded-lg border border-gray-200 p-4">
                        <h3 class="text-sm font-medium text-gray-900">Delivery</h3>
                        <div class="mt-3 space-y-2">
                            @foreach($deliveryOptions as $option)
                                <div class="flex items-center justify-between text-sm" wire:key="delivery-{{ $loop->index }}">
                                    <div class="flex items-center gap-2">
                                        <x-icon :name="$option['icon']" class="size-4 text-gray-400" />
                                        <span class="text-gray-700">{{ $option['label'] }}</span>
                                    </div>
                                    <div class="text-right">
                                        @if($option['free'])
                                            <span class="font-medium text-green-600">Free</span>
                                        @else
                                            <span class="text-gray-500">${{ number_format($option['price'], 2) }}</span>
                                        @endif
                                        <br>
                                        <span class="text-xs text-gray-400">{{ $option['estimate'] }}</span>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    </div>

                    {{-- Share --}}
                    <div class="mt-6 flex items-center gap-4">
                        <span class="text-sm text-gray-500">Share:</span>
                        @foreach(['facebook' => 'Facebook', 'twitter' => 'X', 'pinterest' => 'Pinterest', 'email' => 'Email'] as $platform => $label)
                            <a
                                href="{{ route('share', ['platform' => $platform, 'product' => $product->id]) }}"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="text-gray-400 transition-colors hover:text-gray-600"
                                title="Share on {{ $label }}"
                            >
                                <x-dynamic-component :component="'icon.' . $platform" class="size-5" />
                            </a>
                        @endforeach
                    </div>
                </section>
            </div>

            {{-- Product Details Tabs --}}
            <div class="mt-16 border-t border-gray-200 pt-10">
                <nav class="flex space-x-8 border-b border-gray-200">
                    @foreach(['description' => 'Description', 'specs' => 'Specifications', 'reviews' => 'Reviews (' . $reviews->count() . ')', 'qa' => 'Q&A'] as $tab => $label)
                        <button
                            @click="activeTab = '{{ $tab }}'"
                            :class="activeTab === '{{ $tab }}'
                                ? 'border-blue-500 text-blue-600'
                                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'"
                            class="border-b-2 px-1 pb-4 text-sm font-medium transition-colors"
                        >
                            {{ $label }}
                        </button>
                    @endforeach
                </nav>

                {{-- Description Tab --}}
                <div x-show="activeTab === 'description'" x-transition class="py-8">
                    <article class="prose prose-sm max-w-none">
                        {!! $product->description !!}
                    </article>

                    @isset($product->features)
                        <div class="mt-8">
                            <h3 class="text-lg font-semibold text-gray-900">Key Features</h3>
                            <ul class="mt-4 space-y-3">
                                @foreach($product->features as $feature)
                                    <li class="flex items-start gap-3">
                                        <x-icon name="check-circle" class="mt-0.5 size-5 flex-shrink-0 text-green-500" />
                                        <span class="text-sm text-gray-700">{{ $feature }}</span>
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                    @endisset

                    @verbatim
                        <div class="mt-6 rounded-lg bg-gray-50 p-4">
                            <p class="text-xs text-gray-400">
                                Template syntax preserved: {{ variable }} and @directive are shown literally.
                            </p>
                        </div>
                    @endverbatim
                </div>

                {{-- Specifications Tab --}}
                <div x-show="activeTab === 'specs'" x-transition x-cloak class="py-8">
                    @empty($product->specifications)
                        <p class="text-sm italic text-gray-400">No specifications available for this product.</p>
                    @else
                        <dl class="divide-y divide-gray-200">
                            @foreach($product->specifications as $spec)
                                @continue($loop->index >= 8 && !$showAllSpecs)
                                <div class="flex py-3 text-sm" wire:key="spec-{{ $loop->index }}">
                                    <dt class="w-1/3 font-medium text-gray-500">{{ $spec['label'] }}</dt>
                                    <dd class="w-2/3 text-gray-900">{{ $spec['value'] }}</dd>
                                </div>
                            @endforeach
                        </dl>

                        @if(count($product->specifications) > 8)
                            <button
                                @click="showAllSpecs = !showAllSpecs"
                                class="mt-4 text-sm text-blue-600 hover:text-blue-800"
                            >
                                <span x-text="showAllSpecs ? 'Show less' : 'Show all specifications'"></span>
                            </button>
                        @endif
                    @endempty
                </div>

                {{-- Reviews Tab --}}
                <div x-show="activeTab === 'reviews'" x-transition x-cloak class="py-8">
                    <div class="lg:grid lg:grid-cols-3 lg:gap-12">
                        {{-- Rating Summary --}}
                        <div class="lg:col-span-1">
                            <div class="text-center">
                                <span class="text-5xl font-bold text-gray-900">{{ number_format($avgRating, 1) }}</span>
                                <div class="mt-2 flex items-center justify-center">
                                    @for($star = 1; $star <= 5; $star++)
                                        <x-icon
                                            name="star"
                                            @class([
                                                'size-5',
                                                'text-yellow-400' => $star <= round($avgRating),
                                                'text-gray-200' => $star > round($avgRating),
                                            ])
                                        />
                                    @endfor
                                </div>
                                <p class="mt-1 text-sm text-gray-500">{{ $reviews->count() }} {{ Str::plural('review', $reviews->count()) }}</p>
                            </div>

                            {{-- Rating Breakdown --}}
                            <div class="mt-6 space-y-2">
                                @while($star = array_key_first($ratingCounts))
                                    @php
                                        $count = array_shift($ratingCounts);
                                        $pct = $reviews->count() > 0 ? round($count / $reviews->count() * 100) : 0;
                                    @endphp
                                    <div class="flex items-center gap-2 text-sm">
                                        <span class="w-8 text-right text-gray-500">{{ $star }}★</span>
                                        <div class="h-2 flex-1 rounded-full bg-gray-200">
                                            <div
                                                @style(["width: {$pct}%"])
                                                class="h-2 rounded-full bg-yellow-400"
                                            ></div>
                                        </div>
                                        <span class="w-8 text-gray-400">{{ $count }}</span>
                                    </div>
                                @endwhile
                            </div>

                            @auth
                                @canany(['create', 'review'], $product)
                                    <x-button
                                        variant="outline"
                                        class="mt-6 w-full"
                                        @click="showReviewForm = !showReviewForm"
                                    >
                                        Write a Review
                                    </x-button>
                                @endcanany
                            @endauth
                        </div>

                        {{-- Review List --}}
                        <div class="mt-8 lg:col-span-2 lg:mt-0">
                            {{-- Review Form --}}
                            @auth
                                <div x-show="showReviewForm" x-transition x-cloak class="mb-8 rounded-lg border border-gray-200 p-6">
                                    <h3 class="text-lg font-semibold text-gray-900">Write a Review</h3>
                                    <form wire:submit.prevent="submitReview" class="mt-4 space-y-4">
                                        @csrf

                                        <div>
                                            <label class="block text-sm font-medium text-gray-700">Rating</label>
                                            <div class="mt-1 flex gap-1">
                                                @for($i = 1; $i <= 5; $i++)
                                                    <button
                                                        type="button"
                                                        @click="reviewRating = {{ $i }}"
                                                        :class="reviewRating >= {{ $i }} ? 'text-yellow-400' : 'text-gray-300'"
                                                        class="transition-colors hover:text-yellow-400"
                                                    >
                                                        <x-icon name="star" class="size-8" x-bind:class="reviewRating >= {{ $i }} ? 'fill-current' : ''" />
                                                    </button>
                                                @endfor
                                            </div>
                                            @error('rating')
                                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                            @enderror
                                        </div>

                                        <div>
                                            <label for="review-title" class="block text-sm font-medium text-gray-700">Title</label>
                                            <input
                                                id="review-title"
                                                type="text"
                                                wire:model="reviewForm.title"
                                                @required(true)
                                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                                placeholder="Summarize your experience"
                                            >
                                            @error('reviewForm.title')
                                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                            @enderror
                                        </div>

                                        <div>
                                            <label for="review-body" class="block text-sm font-medium text-gray-700">Review</label>
                                            <textarea
                                                id="review-body"
                                                wire:model="reviewForm.body"
                                                rows="4"
                                                @required(true)
                                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                                placeholder="What did you like or dislike? What did you use this product for?"
                                            ></textarea>
                                            @error('reviewForm.body')
                                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                            @enderror
                                        </div>

                                        <div class="flex items-center gap-2">
                                            <input
                                                type="checkbox"
                                                id="review-recommend"
                                                wire:model="reviewForm.recommend"
                                                @checked(true)
                                                class="rounded border-gray-300 text-blue-600"
                                            >
                                            <label for="review-recommend" class="text-sm text-gray-600">I recommend this product</label>
                                        </div>

                                        <div class="flex justify-end gap-3">
                                            <x-button type="button" variant="outline" @click="showReviewForm = false">Cancel</x-button>
                                            <x-button type="submit" variant="primary" wire:loading.attr="disabled">
                                                Submit Review
                                            </x-button>
                                        </div>
                                    </form>
                                </div>
                            @endauth

                            {{-- Reviews --}}
                            @forelse($reviews as $review)
                                <article
                                    wire:key="review-{{ $review->id }}"
                                    @class([
                                        'border-b border-gray-100 py-6',
                                        'first:pt-0' => $loop->first,
                                        'last:border-0' => $loop->last,
                                    ])
                                >
                                    <div class="flex items-start justify-between">
                                        <div>
                                            <div class="flex items-center gap-1">
                                                @for($star = 1; $star <= 5; $star++)
                                                    <x-icon
                                                        name="star"
                                                        @class([
                                                            'size-4',
                                                            'text-yellow-400' => $star <= $review->rating,
                                                            'text-gray-200' => $star > $review->rating,
                                                        ])
                                                    />
                                                @endfor
                                            </div>
                                            <h4 class="mt-1 text-sm font-medium text-gray-900">{{ $review->title }}</h4>
                                        </div>
                                        @if($review->verified_purchase)
                                            <x-badge color="green" size="sm">Verified Purchase</x-badge>
                                        @endif
                                    </div>

                                    <p class="mt-2 text-sm text-gray-600">{{ $review->body }}</p>

                                    <div class="mt-3 flex items-center gap-4 text-xs text-gray-400">
                                        <span>{{ $review->author_name }}</span>
                                        <span>&middot;</span>
                                        <time datetime="{{ $review->created_at->toIso8601String() }}">
                                            {{ $review->created_at->format('M d, Y') }}
                                        </time>
                                        @if($review->recommend)
                                            <span>&middot;</span>
                                            <span class="text-green-500">
                                                <x-icon name="hand-thumb-up" class="inline size-3.5" /> Recommends
                                            </span>
                                        @endif
                                    </div>

                                    {{-- Helpful votes --}}
                                    <div class="mt-3 flex items-center gap-3 text-xs">
                                        <span class="text-gray-400">Helpful?</span>
                                        <button
                                            wire:click="voteHelpful({{ $review->id }}, true)"
                                            class="text-gray-500 hover:text-blue-600"
                                        >
                                            Yes ({{ $review->helpful_count }})
                                        </button>
                                        <button
                                            wire:click="voteHelpful({{ $review->id }}, false)"
                                            class="text-gray-500 hover:text-blue-600"
                                        >
                                            No ({{ $review->unhelpful_count }})
                                        </button>
                                    </div>
                                </article>
                            @empty
                                <div class="py-12 text-center">
                                    <x-icon name="chat-bubble-bottom-center-text" class="mx-auto size-12 text-gray-300" />
                                    <h3 class="mt-2 text-sm font-medium text-gray-900">No reviews yet</h3>
                                    <p class="mt-1 text-sm text-gray-500">Be the first to review this product.</p>
                                </div>
                            @endforelse

                            @if($reviews->hasPages())
                                <div class="mt-6">
                                    {{ $reviews->fragment('reviews')->links() }}
                                </div>
                            @endif
                        </div>
                    </div>
                </div>

                {{-- Q&A Tab --}}
                <div x-show="activeTab === 'qa'" x-transition x-cloak class="py-8">
                    <div class="mb-6">
                        <h3 class="text-lg font-semibold text-gray-900">Customer Questions & Answers</h3>
                    </div>

                    @forelse($questions as $question)
                        <div wire:key="qa-{{ $question->id }}" class="border-b border-gray-100 py-4 last:border-0">
                            <div class="flex gap-3">
                                <span class="mt-0.5 flex-shrink-0 text-sm font-bold text-gray-900">Q:</span>
                                <div class="flex-1">
                                    <p class="text-sm font-medium text-gray-900">{{ $question->body }}</p>
                                    <p class="mt-1 text-xs text-gray-400">
                                        Asked by {{ $question->author_name }} on {{ $question->created_at->format('M d, Y') }}
                                    </p>

                                    @foreach($question->answers as $answer)
                                        <div class="mt-3 flex gap-3 rounded-lg bg-gray-50 p-3">
                                            <span class="mt-0.5 flex-shrink-0 text-sm font-bold text-blue-600">A:</span>
                                            <div>
                                                <p class="text-sm text-gray-700">{{ $answer->body }}</p>
                                                <p class="mt-1 text-xs text-gray-400">
                                                    {{ $answer->author_name }}
                                                    @if($answer->is_seller)
                                                        <x-badge color="blue" size="sm">Seller</x-badge>
                                                    @endif
                                                    &middot; {{ $answer->created_at->format('M d, Y') }}
                                                </p>
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                        </div>
                    @empty
                        <p class="py-8 text-center text-sm italic text-gray-400">No questions yet. Be the first to ask!</p>
                    @endforelse

                    @auth
                        @can('ask', $product)
                            <form wire:submit.prevent="askQuestion" class="mt-6">
                                @csrf
                                <div class="flex gap-3">
                                    <input
                                        type="text"
                                        wire:model="questionForm.body"
                                        placeholder="Have a question? Ask here..."
                                        @required(true)
                                        class="flex-1 rounded-lg border-gray-300 text-sm focus:border-blue-500 focus:ring-blue-500"
                                    >
                                    <x-button type="submit" variant="outline" wire:loading.attr="disabled">
                                        Ask
                                    </x-button>
                                </div>
                                @error('questionForm.body')
                                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                @enderror
                            </form>
                        @endcan
                    @endauth
                </div>
            </div>

            {{-- Related Products --}}
            @if($relatedProducts->isNotEmpty())
                <section class="mt-16 border-t border-gray-200 pt-10">
                    <h2 class="text-2xl font-bold text-gray-900">Related Products</h2>
                    <div class="mt-6 grid grid-cols-2 gap-6 sm:grid-cols-3 lg:grid-cols-4">
                        @foreach($relatedProducts as $related)
                            <div wire:key="related-{{ $related->id }}" class="group">
                                <a href="{{ route('products.show', $related) }}" wire:navigate class="block">
                                    <div class="aspect-square overflow-hidden rounded-xl bg-gray-100">
                                        <img
                                            src="{{ $related->featured_image }}"
                                            alt="{{ $related->name }}"
                                            class="size-full object-cover transition-transform group-hover:scale-105"
                                            loading="lazy"
                                        >
                                    </div>
                                    <h3 class="mt-3 text-sm font-medium text-gray-900 group-hover:text-blue-600">
                                        {{ $related->name }}
                                    </h3>
                                    <p class="mt-1 text-sm font-bold text-gray-900">
                                        ${{ number_format($related->effective_price, 2) }}
                                        @if($related->on_sale)
                                            <span class="ml-1 text-xs font-normal text-gray-400 line-through">
                                                ${{ number_format($related->price, 2) }}
                                            </span>
                                        @endif
                                    </p>
                                </a>
                            </div>
                            @if($loop->iteration >= 4)
                                @break
                            @endif
                        @endforeach
                    </div>
                </section>
            @endif

            {{-- Recently Viewed --}}
            <section
                x-show="recentlyViewed.length > 0"
                x-cloak
                class="mt-16 border-t border-gray-200 pt-10"
            >
                <h2 class="text-2xl font-bold text-gray-900">Recently Viewed</h2>
                <div class="mt-6 flex gap-4 overflow-x-auto pb-4">
                    <template x-for="item in recentlyViewed.slice(0, 8)" :key="item.id">
                        <a :href="item.url" class="w-40 flex-shrink-0">
                            <div class="aspect-square overflow-hidden rounded-lg bg-gray-100">
                                <img :src="item.image" :alt="item.name" class="size-full object-cover" loading="lazy">
                            </div>
                            <p class="mt-2 truncate text-xs text-gray-700" x-text="item.name"></p>
                            <p class="text-xs font-bold text-gray-900" x-text="'$' + item.price"></p>
                        </a>
                    </template>
                </div>
            </section>
        </main>

        {{-- Size Guide Modal --}}
        <div x-show="showSizeGuide" x-cloak class="fixed inset-0 z-50 flex items-center justify-center">
            <div class="fixed inset-0 bg-black/50" @click="showSizeGuide = false"></div>
            <div class="relative max-h-[80vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-2xl" @click.stop>
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-900">Size Guide</h3>
                    <button @click="showSizeGuide = false" class="text-gray-400 hover:text-gray-600">
                        <x-icon name="x-mark" class="size-6" />
                    </button>
                </div>
                @includeFirst(['products.size-guides.' . $product->category->slug, 'products.size-guides.default'])
            </div>
        </div>

        {{-- blade-formatter:off --}}
        <pre class="hidden">
            Debug: product={{ $product->id }} variants={{ $product->variants->count() }}
        </pre>
        {{-- blade-formatter:on --}}
    </div>

    @once
        @prepend('scripts')
            <script>
                document.addEventListener('livewire:initialized', () => {
                    Livewire.on('added-to-cart', (event) => {
                        Alpine.store('cart').refresh();
                        Alpine.store('toast').success(event.message || 'Added to cart');
                    });
                });
            </script>
        @endprepend
    @endonce

    @pushOnce('scripts')
        <script>
            function updateVariant() {
                const color = Alpine.evaluate(document.querySelector('[x-data]'), 'selectedColor');
                const size = Alpine.evaluate(document.querySelector('[x-data]'), 'selectedSize');
                Livewire.dispatch('variant-changed', { color, size });
            }
        </script>
    @endPushOnce

    @production
        @include('analytics.product-view', ['product' => $product])
    @endproduction
@endsection
