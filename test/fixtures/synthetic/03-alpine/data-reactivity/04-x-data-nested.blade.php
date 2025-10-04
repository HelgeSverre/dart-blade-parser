{{-- Alpine.js Nested Components with Parent-Child Communication --}}
<div x-data="{
    cartItems: [],
    totalPrice: 0,
    currency: 'USD',
    discount: 0,

    get itemCount() {
        return this.cartItems.reduce((sum, item) => sum + item.quantity, 0);
    },

    get subtotal() {
        return this.cartItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    },

    get finalTotal() {
        return Math.max(0, this.subtotal - this.discount);
    },

    addItem(product) {
        const existing = this.cartItems.find(item => item.id === product.id);
        if (existing) {
            existing.quantity++;
        } else {
            this.cartItems.push({ ...product, quantity: 1 });
        }
        this.updateTotal();
    },

    removeItem(productId) {
        this.cartItems = this.cartItems.filter(item => item.id !== productId);
        this.updateTotal();
    },

    updateTotal() {
        this.totalPrice = this.finalTotal;
    },

    applyDiscount(amount) {
        this.discount = amount;
        this.updateTotal();
    }
}" class="max-w-4xl mx-auto p-6">

    <h2 class="text-3xl font-bold mb-6">Shopping Cart System</h2>

    {{-- Parent component manages cart state --}}
    <div class="grid grid-cols-2 gap-6">

        {{-- Child Component: Product List --}}
        <div x-data="{
            products: [
                { id: 1, name: 'Alpine.js Course', price: 49.99, category: 'Education' },
                { id: 2, name: 'Laravel Masterclass', price: 79.99, category: 'Education' },
                { id: 3, name: 'Tailwind UI Kit', price: 29.99, category: 'Design' },
                { id: 4, name: 'Icon Pack Pro', price: 19.99, category: 'Design' }
            ],
            selectedCategory: 'all',

            get filteredProducts() {
                if (this.selectedCategory === 'all') return this.products;
                return this.products.filter(p => p.category === this.selectedCategory);
            }
        }" class="bg-white rounded-lg shadow-lg p-6">
            <h3 class="text-xl font-semibold mb-4">Products</h3>

            <select x-model="selectedCategory" class="w-full mb-4 px-3 py-2 border rounded">
                <option value="all">All Categories</option>
                <option value="Education">Education</option>
                <option value="Design">Design</option>
            </select>

            <div class="space-y-3">
                <template x-for="product in filteredProducts" :key="product.id">
                    <div class="p-3 border rounded hover:bg-gray-50">
                        <div class="flex justify-between items-start mb-2">
                            <div>
                                <h4 class="font-semibold" x-text="product.name"></h4>
                                <span class="text-xs text-gray-500" x-text="product.category"></span>
                            </div>
                            <span class="font-bold text-green-600" x-text="'$' + product.price"></span>
                        </div>
                        <button
                            @click="$parent.addItem(product)"
                            class="w-full px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
                        >
                            Add to Cart
                        </button>
                    </div>
                </template>
            </div>
        </div>

        {{-- Child Component: Cart Summary --}}
        <div class="bg-white rounded-lg shadow-lg p-6">
            <h3 class="text-xl font-semibold mb-4">Cart (<span x-text="itemCount"></span>)</h3>

            <div x-show="cartItems.length === 0" class="text-center py-8 text-gray-400">
                Your cart is empty
            </div>

            <div x-show="cartItems.length > 0" class="space-y-4">
                <div class="space-y-2 max-h-64 overflow-y-auto">
                    <template x-for="item in cartItems" :key="item.id">
                        <div class="flex justify-between items-center p-2 bg-gray-50 rounded">
                            <div class="flex-1">
                                <p class="font-medium text-sm" x-text="item.name"></p>
                                <p class="text-xs text-gray-600">
                                    <span x-text="item.quantity"></span> x
                                    <span x-text="'$' + item.price"></span>
                                </p>
                            </div>
                            <div class="flex items-center gap-2">
                                <span class="font-semibold" x-text="'$' + (item.price * item.quantity).toFixed(2)"></span>
                                <button
                                    @click="removeItem(item.id)"
                                    class="text-red-500 hover:text-red-700 text-xs"
                                >
                                    Remove
                                </button>
                            </div>
                        </div>
                    </template>
                </div>

                <div class="border-t pt-4 space-y-2">
                    <div class="flex justify-between text-sm">
                        <span>Subtotal:</span>
                        <span x-text="'$' + subtotal.toFixed(2)"></span>
                    </div>
                    <div x-show="discount > 0" class="flex justify-between text-sm text-green-600">
                        <span>Discount:</span>
                        <span x-text="'-$' + discount.toFixed(2)"></span>
                    </div>
                    <div class="flex justify-between text-lg font-bold border-t pt-2">
                        <span>Total:</span>
                        <span x-text="'$' + finalTotal.toFixed(2)"></span>
                    </div>

                    <button
                        @click="applyDiscount(10)"
                        class="w-full mt-2 px-4 py-1 text-sm bg-green-100 text-green-700 rounded hover:bg-green-200"
                    >
                        Apply $10 Discount
                    </button>

                    <button class="w-full mt-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
                        Checkout
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
