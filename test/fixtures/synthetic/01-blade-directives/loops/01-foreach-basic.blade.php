---
description: "Basic @foreach loop rendering product cards with realistic data"
tags: ["foreach", "loops", "products", "html-structure"]
---
<div class="product-grid">
    @foreach($products as $product)
    <article class="product-card">
        <div class="product-image">
            <img src="{{ $product->image_url }}" alt="{{ $product->name }}">
            @if($product->on_sale)
            <span class="badge badge-sale">Sale</span>
            @endif
            @if($product->stock < 5)
            <span class="badge badge-low-stock">Only {{ $product->stock }} left</span>
            @endif
        </div>

        <div class="product-details">
            <h3 class="product-title">{{ $product->name }}</h3>
            <p class="product-category">{{ $product->category }}</p>

            <div class="product-pricing">
                @if($product->on_sale)
                <span class="price-original">${{ number_format($product->original_price, 2) }}</span>
                <span class="price-sale">${{ number_format($product->sale_price, 2) }}</span>
                <span class="discount-percent">{{ $product->discount_percent }}% off</span>
                @else
                <span class="price">${{ number_format($product->price, 2) }}</span>
                @endif
            </div>

            <div class="product-rating">
                <span class="stars">{{ str_repeat('★', $product->rating) }}{{ str_repeat('☆', 5 - $product->rating) }}</span>
                <span class="review-count">({{ $product->review_count }} reviews)</span>
            </div>

            <button class="btn btn-primary" data-product-id="{{ $product->id }}">
                Add to Cart
            </button>
        </div>
    </article>
    @endforeach
</div>
