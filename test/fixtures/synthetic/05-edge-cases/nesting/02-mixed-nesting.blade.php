{{--
features: [if, foreach, unless, blade-directives, control-structures, mixed-nesting]
complexity: high
lines: 53
valid: true
description: Mix of @if, @foreach, and @unless directives nested 7 levels deep, representing a realistic e-commerce product filtering scenario
--}}

<div class="product-catalog">
  @if ($categories->isNotEmpty())
    <div class="category-grid">
      @foreach ($categories as $category)
        <div class="category-card">
          <h2>{{ $category->name }}</h2>

          @if ($category->products->isNotEmpty())
            <div class="products">
              @foreach ($category->products as $product)
                <article class="product-item">
                  <h3>{{ $product->name }}</h3>

                  @unless ($product->isOutOfStock())
                    <div class="product-details">
                      <p class="price">${{ $product->price }}</p>

                      @if ($product->hasVariants())
                        <div class="variants">
                          @foreach ($product->variants as $variant)
                            <div class="variant-option">
                              <span class="variant-name">{{ $variant->name }}</span>

                              @unless ($variant->isAvailable())
                                <span class="badge-unavailable">Out of Stock</span>
                              @else
                                @if ($user && $user->hasFavorite($variant->id))
                                  <button class="btn-favorite active">
                                    <i class="icon-heart-filled"></i>
                                    Favorited
                                  </button>
                                @else
                                  <button class="btn-favorite">
                                    <i class="icon-heart"></i>
                                    Add to Favorites
                                  </button>
                                @endif
                              @endunless
                            </div>
                          @endforeach
                        </div>
                      @endif

                      <button class="btn-add-cart">Add to Cart</button>
                    </div>
                  @else
                    <p class="out-of-stock">Currently Unavailable</p>
                  @endunless
                </article>
              @endforeach
            </div>
          @endif
        </div>
      @endforeach
    </div>
  @endif
</div>
