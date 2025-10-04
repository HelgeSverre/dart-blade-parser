---
description: Product grid using foreach loop with component rendering
features:
  - foreach-directive
  - component-tag
difficulty: level-1-simple
---
<div class="product-catalog">
    <h1>Featured Products</h1>

    <div class="product-grid">
        @foreach($products as $product)
            <x-product-card
                :product="$product"
                :price="$product->price"
                :discount="$product->discount"
            />
        @endforeach
    </div>

    <h2>Categories</h2>
    <div class="category-list">
        @foreach($categories as $category)
            <x-category-badge
                :name="$category->name"
                :count="$category->productCount"
                :icon="$category->icon"
            />
        @endforeach
    </div>

    <h2>Recent Reviews</h2>
    <div class="reviews-section">
        @foreach($reviews as $review)
            <x-review-item
                :author="$review->user->name"
                :rating="$review->rating"
                :comment="$review->comment"
                :date="$review->created_at"
            />
        @endforeach
    </div>

    <div class="featured-brands">
        <h3>Our Partner Brands</h3>
        <div class="brand-logos">
            @foreach($brands as $brand)
                <x-brand-logo :brand="$brand" :url="$brand->website" />
            @endforeach
        </div>
    </div>
</div>
