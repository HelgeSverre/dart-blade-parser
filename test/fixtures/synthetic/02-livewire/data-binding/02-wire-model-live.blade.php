<div class="product-search">
    <h2>Product Search</h2>

    {{-- Live Search Input --}}
    <div class="search-box">
        <input
            type="text"
            wire:model.live="searchTerm"
            placeholder="Search products..."
            class="search-input"
        >
        <span class="search-count">{{ count($results) }} results</span>
    </div>

    {{-- Live Filter Options --}}
    <div class="filters">
        <label>Category:</label>
        <select wire:model.live="category" class="filter-select">
            <option value="">All Categories</option>
            <option value="electronics">Electronics</option>
            <option value="clothing">Clothing</option>
            <option value="books">Books</option>
        </select>

        <label>Price Range:</label>
        <select wire:model.live="priceRange" class="filter-select">
            <option value="">Any Price</option>
            <option value="0-50">$0 - $50</option>
            <option value="50-100">$50 - $100</option>
            <option value="100+">$100+</option>
        </select>
    </div>

    {{-- Live Results --}}
    <div class="results">
        @forelse($results as $product)
            <div class="product-card">
                <h3>{{ $product->name }}</h3>
                <p>${{ $product->price }}</p>
            </div>
        @empty
            <p class="no-results">No products found</p>
        @endforelse
    </div>
</div>
