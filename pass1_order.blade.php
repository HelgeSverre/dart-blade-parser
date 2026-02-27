--- test/fixtures/stress/contoso/order_form.blade.php ---
@props([
    'order' => null,
    'customers' => [],
    'products' => [],
    'currencies' => ['USD', 'EUR', 'GBP', 'NOK'],
    'taxRates' => [],
    'warehouses' => [],
    'mode' => 'create',
])

@php
    $isEdit = $mode === 'edit' && $order;
    $defaultCurrency = $isEdit ? $order->currency : config('contoso.default_currency', 'USD');
    $lineItems = $isEdit ? $order->lineItems->toArray() : [];
    $statusOptions = \App\Enums\OrderStatus::cases();
    $priorityLevels = [
        'low' => ['label' => 'Low', 'color' => 'gray'],
        'normal' => ['label' => 'Normal', 'color' => 'blue'],
        'high' => ['label' => 'High', 'color' => 'orange'],
        'urgent' => ['label' => 'Urgent', 'color' => 'red'],
    ];
@endphp

<form
    wire:submit.prevent="{{ $isEdit ? 'updateOrder' : 'createOrder' }}"
    x-data="{
        currency: @js($defaultCurrency),
        lineItems: @js($lineItems),
        discount: @js($isEdit ? $order->discount_percent : 0),
        taxRate: @js($isEdit ? $order->tax_rate : null),
        shippingCost: @js($isEdit ? $order->shipping_cost : 0),
        notes: @js($isEdit ? $order->internal_notes : ''),
        showNotes: @js($isEdit && $order->internal_notes),
        get subtotal() {
            return this.lineItems.reduce((sum, item) => sum + (item.quantity * item.unit_price), 0);
        },
        get discountAmount() {
            return this.subtotal * (this.discount / 100);
        },
        get taxableAmount() {
            return this.subtotal - this.discountAmount;
        },
        get taxAmount() {
            if (!this.taxRate) return 0;
            return this.taxableAmount * (this.taxRate / 100);
        },
        get total() {
            return this.taxableAmount + this.taxAmount + parseFloat(this.shippingCost || 0);
        },
        addLineItem() {
            this.lineItems.push({ product_id: '', description: '', quantity: 1, unit_price: 0, warehouse_id: '' });
        },
        removeLineItem(index) {
            this.lineItems.splice(index, 1);
        },
        formatCurrency(amount) {
            return new Intl.NumberFormat('en-US', { style: 'currency', currency: this.currency }).format(amount);
        },
    }">
    {{-- Order Header --}}
    <div class="space-y-8">
        <x-contoso.form-section heading="{{ $isEdit ? 'Edit Order #' . $order->number : 'New Order' }}">
            <x-slot:description>
                @if
                    ($isEdit)
                    <p class="text-sm text-gray-500">
                        Created {{ $order->created_at->diffForHumans() }}
                        by {{ $order->creator->name }}
                        .
                        @if
                            ($order->updated_at->gt($order->created_at))
                            Last modified {{ $order->updated_at->diffForHumans() }}
                            .
                        @endif
                    </p>
                @else
                    <p class="text-sm text-gray-500">
                        Fill in the order details below. Required fields are marked with an asterisk.
                    </p>
                @endif
            </x-slot>

            <div class="grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-6">
                {{-- Customer Selection --}}
                <div class="sm:col-span-3">
                    <x-contoso.form-label for="customer" required>Customer</x-contoso.form-label>

                    <x-contoso.entity-selector
                        wire:model.live="customer_id"
                        :entities="$customers"
                        placeholder="Search customers..."
                        display-field="name"
                        :create-url="route('customers.create')"
                        @if
                        isEdit
                        :disabled="$order->isLocked()"
                        @endif
                        {{ $attributes->whereStartsWith('customer-') }} />
                    @error('customer_id')
                        <x-contoso.form-error>
                            <x-slot:default>
                                {{ $message }}
                            </x-slot>
                        </x-contoso.form-error>
                    @enderror
                </div>
                {{-- Order Date --}}
                <div class="sm:col-span-3">
                    <x-contoso.form-label for="order_date" required>Order Date</x-contoso.form-label>

                    <x-contoso.date-picker
                        wire:model="order_date"
                        id="order_date"
                        :value="$isEdit ? $order->order_date->format('Y-m-d') : now()->format('Y-m-d')"
                        @class([
                            'w-full rounded-md border-gray-300 shadow-sm',
                            'focus:border-navy-500 focus:ring-navy-500' => ! $errors->has('order_date'),
                            'border-red-300 focus:border-red-500 focus:ring-red-500' => $errors->has('order_date'),
                        ]) />
                    @error('order_date')
                        <x-contoso.form-error>
                            <x-slot:default>
                                {{ $message }}
                            </x-slot>
                        </x-contoso.form-error>
                    @enderror
                </div>
                {{-- Status (edit only) --}}
                @if
                    ($isEdit)
                    <div class="sm:col-span-2">
                        <x-contoso.form-label for="status">Status</x-contoso.form-label>

                        <x-contoso.listbox
                            wire:model.live="status"
                            :options="collect($statusOptions)->map(fn ($s) => ['label' => $s->getLabel(), 'value' => $s->value])->toArray()"
                            :value="$order->status->value"
                            :enum="\App\Enums\OrderStatus::class" />
                    </div>
                @endif

                {{-- Priority --}}
                <div
                    @class([
                        'sm:col-span-2' => $isEdit,
                        'sm:col-span-3' => ! $isEdit,
                    ])>
                    <x-contoso.form-label for="priority">Priority</x-contoso.form-label>
                    <div class="flex gap-2">
                        @foreach
                            ($priorityLevels as $key => $priority)
                            <button
                                type="button"
                                wire:click="$set('priority', '{{ $key }}')"
                                @class([
                                    'inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ring-1 ring-inset transition-colors',
                                    'bg-gray-50 text-gray-600 ring-gray-500/10 hover:bg-gray-100' => $priority['color'] === 'gray',
                                    'bg-blue-50 text-blue-700 ring-blue-700/10 hover:bg-blue-100' => $priority['color'] === 'blue',
                                    'bg-orange-50 text-orange-700 ring-orange-700/10 hover:bg-orange-100' => $priority['color'] === 'orange',
                                    'bg-red-50 text-red-700 ring-red-700/10 hover:bg-red-100' => $priority['color'] === 'red',
                                ])
                                @if
                                isEdit
                                order->
                                priority : 'normal') === $key)
                                aria-pressed="true"
                                >
                                {{ $priority['label'] }}
                            </button>
                        @endforeach
                    </div>
                </div>
                {{-- Currency --}}
                <div
                    @class([
                        'sm:col-span-2' => $isEdit,
                        'sm:col-span-3' => ! $isEdit,
                    ])>
                    <x-contoso.form-label for="currency">Currency</x-contoso.form-label>
                    <select
                        wire:model.live="currency"
                        x-model="currency"
                        id="currency"
                        class="mt-1 block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-navy-500 focus:outline-none focus:ring-navy-500 sm:text-sm"
                        @if
                        isEdit
                        order->
                        hasPayments())
                        disabled
                        title="Currency cannot be changed after payments have been recorded"
                        >
                        @foreach
                            ($currencies as $curr)
                            <option
                                value="{{ $curr }}"
                                @selected(($isEdit ? $order->currency : $defaultCurrency) === $curr)>
                                {{ $curr }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>
        </x-contoso.form-section>
        {{-- Line Items --}}
        <x-contoso.form-section heading="Line Items">
            <x-slot:description>
                <p class="text-sm text-gray-500">Add products or custom line items to this order.</p>
            </x-slot>

            <div class="space-y-4">
                {{-- Table Header --}}
                <div class="hidden sm:grid sm:grid-cols-12 sm:gap-4 sm:border-b sm:border-gray-200 sm:pb-2">
                    <div class="col-span-4 text-xs font-medium uppercase tracking-wider text-gray-500">Product</div>

                    <div class="col-span-2 text-xs font-medium uppercase tracking-wider text-gray-500">Warehouse</div>

                    <div class="col-span-2 text-xs font-medium uppercase tracking-wider text-gray-500">Qty</div>

                    <div class="col-span-2 text-xs font-medium uppercase tracking-wider text-gray-500">Unit Price</div>

                    <div class="col-span-1 text-xs font-medium uppercase tracking-wider text-gray-500">Total</div>

                    <div class="col-span-1"></div>
                </div>
                {{-- Line Item Rows --}}
                <template x-for="(item, index) in lineItems" :key="index">
                    <div
                        class="grid grid-cols-1 gap-4 rounded-lg border border-gray-200 p-4 sm:grid-cols-12 sm:rounded-none sm:border-0 sm:border-b sm:p-0 sm:py-3"
                        x-data="{ expanded: false }">
                        {{-- Product --}}
                        <div class="sm:col-span-4">
                            <label class="mb-1 block text-xs font-medium text-gray-500 sm:hidden">Product</label>
                            <select
                                x-model="item.product_id"
                                x-bind:name="`line_items[${index}][product_id]`"
                                class="block w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-navy-500 focus:ring-navy-500"
                                x-on:change="
                                    const product = {{ Js::from($products) }}.find(p => p.id == item.product_id);
                                    if (product) {
                                        item.description = product.name;
                                        item.unit_price = product.price;
                                    }
                                ">
                                <option value="">Select a product...</option>
                                @foreach
                                    ($products as $product)
                                    <option value="{{ $product->id }}" data-price="{{ $product->price }}">
                                        {{ $product->sku }}
                                        - {{ $product->name }}
                                    </option>
                                @endforeach
                            </select>
                            {{-- Custom description toggle --}}
                            <button
                                type="button"
                                class="mt-1 text-xs text-navy-600 hover:text-navy-800"
                                x-on:click="expanded = !expanded"
                                x-text="expanded ? 'Hide description' : 'Edit description'"></button>
                            <div x-show="expanded" x-collapse>
                                <textarea
                                    x-model="item.description"
                                    x-bind:name="`line_items[${index}][description]`"
                                    rows="2"
                                    class="mt-1 block w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-navy-500 focus:ring-navy-500"
                                    placeholder="Custom description..."></textarea>
                            </div>
                        </div>
                        {{-- Warehouse --}}
                        <div class="sm:col-span-2">
                            <label class="mb-1 block text-xs font-medium text-gray-500 sm:hidden">Warehouse</label>
                            <select
                                x-model="item.warehouse_id"
                                x-bind:name="`line_items[${index}][warehouse_id]`"
                                class="block w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-navy-500 focus:ring-navy-500">
                                <option value="">Default</option>
                                @foreach
                                    ($warehouses as $warehouse)
                                    <option value="{{ $warehouse->id }}">
                                        {{ $warehouse->name }}
                                        @if
                                            ($warehouse->is_primary) (Primary)
                                        @endif
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        {{-- Quantity --}}
                        <div class="sm:col-span-2">
                            <label class="mb-1 block text-xs font-medium text-gray-500 sm:hidden">Quantity</label>
                            <input
                                type="number"
                                x-model.number="item.quantity"
                                x-bind:name="`line_items[${index}][quantity]`"
                                min="1"
                                step="1"
                                class="block w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-navy-500 focus:ring-navy-500">
                        </div>
                        {{-- Unit Price --}}
                        <div class="sm:col-span-2">
                            <label class="mb-1 block text-xs font-medium text-gray-500 sm:hidden">Unit Price</label>
                            <div class="relative">
                                <span
                                    class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500"
                                    x-text="currency"></span>
                                <input
                                    type="number"
                                    x-model.number="item.unit_price"
                                    x-bind:name="`line_items[${index}][unit_price]`"
                                    min="0"
                                    step="0.01"
                                    class="block w-full rounded-md border-gray-300 pl-12 text-sm shadow-sm focus:border-navy-500 focus:ring-navy-500">
                            </div>
                        </div>
                        {{-- Line Total --}}
                        <div class="sm:col-span-1">
                            <label class="mb-1 block text-xs font-medium text-gray-500 sm:hidden">Total</label>
                            <span
                                class="inline-block py-2 text-sm font-medium text-gray-900"
                                x-text="formatCurrency(item.quantity * item.unit_price)"></span>
                        </div>
                        {{-- Actions --}}
                        <div class="flex items-center justify-end sm:col-span-1">
                            <button
                                type="button"
                                x-on:click="removeLineItem(index)"
                                @class([
                                    'rounded p-1 text-gray-400 transition-colors',
                                    'hover:bg-red-50 hover:text-red-600' => true,
                                ])
                                x-bind:disabled="lineItems.length <= 1"
                                @if
                                isEdit
                                order->
                                isLocked())
                                disabled
                                title="Cannot modify items on a locked order"
                                >
                                <x-heroicon-o-trash class="size-5" />
                                <span class="sr-only">Remove item</span>
                            </button>
                        </div>
                    </div>
                </template>
                {{-- Add Line Item Button --}}
                <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                    <button
                        type="button"
                        x-on:click="addLineItem()"
                        class="inline-flex items-center gap-1 text-sm font-medium text-navy-600 hover:text-navy-800"
                        @unless
                        isEdit
                        order->
                        isLocked())
                        wire:loading.attr="disabled"
                        >
                        <x-heroicon-o-plus class="size-4" />
                        Add line item
                    </button>
                    @if
                        ($isEdit && $order->lineItems->count() > 0)
                        <span class="text-xs text-gray-500">
                            {{ $order->lineItems->count() }}
                            item(s) saved
                        </span>
                    @endif
                </div>
            </div>
        </x-contoso.form-section>
        {{-- Pricing Summary --}}
        <x-contoso.form-section heading="Pricing">
            <x-slot:default>
                <div class="space-y-4">
                    <div class="grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-6">
                        {{-- Discount --}}
                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="discount">Discount (%)</x-contoso.form-label>
                            <input
                                type="number"
                                wire:model.live.debounce.500ms="discount_percent"
                                x-model.number="discount"
                                id="discount"
                                min="0"
                                max="100"
                                step="0.5"
                                @class([
                                'mt-1 block w-full rounded-md shadow-sm sm:text-sm',
                                'border-gray-300 focus:border-navy-500 focus:ring-navy-500' => ! $errors->has('discount_percent'),
                                'border-red-300 focus:border-red-500 focus:ring-red-500' => $errors->has('discount_percent'),
                            ])>
                        </div>
                        {{-- Tax Rate --}}
                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="tax_rate">Tax Rate</x-contoso.form-label>
                            <select
                                wire:model.live="tax_rate_id"
                                x-on:change="taxRate = $event.target.selectedOptions[0]?.dataset?.rate || null"
                                id="tax_rate"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm">
                                <option value="">No tax</option>
                                @foreach
                                    ($taxRates as $rate)
                                    <option
                                        value="{{ $rate->id }}"
                                        data-rate="{{ $rate->percentage }}"
                                        @selected($isEdit && $order->tax_rate_id === $rate->id)>
                                        {{ $rate->name }}
                                        ({{ $rate->percentage }}
                                        %)
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        {{-- Shipping --}}
                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="shipping_cost">Shipping Cost</x-contoso.form-label>
                            <div class="relative mt-1">
                                <span
                                    class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500"
                                    x-text="currency"></span>
                                <input
                                    type="number"
                                    wire:model.live.debounce.500ms="shipping_cost"
                                    x-model.number="shippingCost"
                                    id="shipping_cost"
                                    min="0"
                                    step="0.01"
                                    class="block w-full rounded-md border-gray-300 pl-12 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm">
                            </div>
                        </div>
                    </div>
                    {{-- Totals --}}
                    <div class="rounded-lg bg-gray-50 p-4">
                        <dl class="space-y-2">
                            <div class="flex items-center justify-between text-sm">
                                <dt class="text-gray-600">Subtotal</dt>
                                <dd class="font-medium text-gray-900" x-text="formatCurrency(subtotal)"></dd>
                            </div>

                            <div class="flex items-center justify-between text-sm" x-show="discount > 0" x-transition>
                                <dt class="text-gray-600">
                                    Discount (
                                    <span x-text="discount"></span>
                                    %)
                                </dt>
                                <dd class="font-medium text-red-600" x-text="'-' + formatCurrency(discountAmount)"></dd>
                            </div>

                            <div class="flex items-center justify-between text-sm" x-show="taxRate > 0" x-transition>
                                <dt class="text-gray-600">
                                    Tax (
                                    <span x-text="taxRate"></span>
                                    %)
                                </dt>
                                <dd class="font-medium text-gray-900" x-text="formatCurrency(taxAmount)"></dd>
                            </div>

                            <div
                                class="flex items-center justify-between text-sm"
                                x-show="shippingCost > 0"
                                x-transition>
                                <dt class="text-gray-600">Shipping</dt>
                                <dd class="font-medium text-gray-900" x-text="formatCurrency(shippingCost)"></dd>
                            </div>

                            <div class="flex items-center justify-between border-t border-gray-200 pt-2">
                                <dt class="text-base font-semibold text-gray-900">Total</dt>
                                <dd class="text-base font-semibold text-gray-900" x-text="formatCurrency(total)"></dd>
                            </div>
                        </dl>
                    </div>
                </div>
            </x-slot>
        </x-contoso.form-section>
        {{-- Shipping Address --}}
        <x-contoso.form-section heading="Shipping Address">
            <x-slot:description>
                <div class="flex items-center gap-2">
                    <p class="text-sm text-gray-500">Where should this order be shipped?</p>
                    @isset($order)
                        @if
                            ($order->customer->addresses->count() > 1)
                            <x-contoso.action-button action="selectAddressAction" variant="link" size="xs">
                                <x-slot:default>
                                    Choose from saved
                                </x-slot>
                            </x-contoso.action-button>
                        @endif
                    @endisset
                </div>
            </x-slot>

            <div
                class="grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-6"
                x-data="{ sameAsBilling: @js($isEdit ? $order->same_as_billing : true) }">
                <div class="sm:col-span-6">
                    <label class="flex items-center gap-2">
                        <input
                            type="checkbox"
                            wire:model.live="same_as_billing"
                            x-model="sameAsBilling"
                            class="rounded border-gray-300 text-navy-600 focus:ring-navy-500">
                        <span class="text-sm text-gray-700">Same as billing address</span>
                    </label>
                </div>
                <template x-if="!sameAsBilling">
                    <div class="contents">
                        <div class="sm:col-span-6">
                            <x-contoso.form-label for="shipping_address_line1" required>Address Line 1</x-contoso.form-label>
                            <input
                                type="text"
                                wire:model="shipping_address.line1"
                                id="shipping_address_line1"
                                @class([
                                    'mt-1 block w-full rounded-md shadow-sm sm:text-sm',
                                    'border-gray-300 focus:border-navy-500 focus:ring-navy-500' => ! $errors->has('shipping_address.line1'),
                                    'border-red-300 focus:border-red-500 focus:ring-red-500' => $errors->has('shipping_address.line1'),
                                ])>
                            @error('shipping_address.line1')
                                <x-contoso.form-error>
                                    <x-slot:default>
                                        {{ $message }}
                                    </x-slot>
                                </x-contoso.form-error>
                            @enderror
                        </div>

                        <div class="sm:col-span-6">
                            <x-contoso.form-label for="shipping_address_line2">Address Line 2</x-contoso.form-label>
                            <input
                                type="text"
                                wire:model="shipping_address.line2"
                                id="shipping_address_line2"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm">
                        </div>

                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="shipping_address_city" required>City</x-contoso.form-label>
                            <input
                                type="text"
                                wire:model="shipping_address.city"
                                id="shipping_address_city"
                                @class([
                                    'mt-1 block w-full rounded-md shadow-sm sm:text-sm',
                                    'border-gray-300 focus:border-navy-500 focus:ring-navy-500' => ! $errors->has('shipping_address.city'),
                                    'border-red-300 focus:border-red-500 focus:ring-red-500' => $errors->has('shipping_address.city'),
                                ])>
                        </div>

                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="shipping_address_state">State / Region</x-contoso.form-label>
                            <input
                                type="text"
                                wire:model="shipping_address.state"
                                id="shipping_address_state"
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm">
                        </div>

                        <div class="sm:col-span-2">
                            <x-contoso.form-label for="shipping_address_postal" required>Postal Code</x-contoso.form-label>
                            <input
                                type="text"
                                wire:model="shipping_address.postal_code"
                                id="shipping_address_postal"
                                @class([
                                    'mt-1 block w-full rounded-md shadow-sm sm:text-sm',
                                    'border-gray-300 focus:border-navy-500 focus:ring-navy-500' => ! $errors->has('shipping_address.postal_code'),
                                    'border-red-300 focus:border-red-500 focus:ring-red-500' => $errors->has('shipping_address.postal_code'),
                                ])>
                        </div>
                    </div>
                </template>
            </div>
        </x-contoso.form-section>
        {{-- Internal Notes --}}
        <x-contoso.form-section heading="Internal Notes">
            <x-slot:default>
                <div>
                    <button
                        type="button"
                        class="mb-2 inline-flex items-center gap-1 text-sm text-navy-600 hover:text-navy-800"
                        x-on:click="showNotes = !showNotes"
                        x-show="!showNotes">
                        <x-heroicon-o-plus class="size-4" />
                        Add internal notes
                    </button>
                    <div x-show="showNotes" x-collapse>
                        <textarea
                            wire:model.blur="internal_notes"
                            x-model="notes"
                            rows="4"
                            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm"
                            placeholder="Notes visible only to staff members..."></textarea>
                    </div>
                </div>
            </x-slot>
        </x-contoso.form-section>
        {{-- Order Activity Timeline (edit only) --}}
        @if
            ($isEdit && $order->activities->isNotEmpty())
            <x-contoso.form-section heading="Activity">
                <x-slot:default>
                    <div class="flow-root">
                        <ul role="list" class="-mb-8">
                            @foreach
                                ($order->activities as $activity)
                                <li>
                                    <div class="relative pb-8">
                                        @unless
                                            ($loop->last)
                                            <span
                                                class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
                                                aria-hidden="true"></span>
                                        @endunless

                                        <div class="relative flex space-x-3">
                                            <div>
                                                <span
                                                    @class([
                                                    'flex size-8 items-center justify-center rounded-full ring-8 ring-white',
                                                    'bg-green-500' => $activity->type === 'created',
                                                    'bg-blue-500' => $activity->type === 'updated',
                                                    'bg-yellow-500' => $activity->type === 'status_changed',
                                                    'bg-gray-400' => ! in_array($activity->type, ['created', 'updated', 'status_changed']),
                                                ])>
                                                    @switch($activity->type)
                                                    @case('created')
                                                        <x-heroicon-s-plus class="size-5 text-white" />
                                                        @break
                                                    @case('updated')
                                                        <x-heroicon-s-pencil class="size-5 text-white" />
                                                        @break
                                                    @case('status_changed')
                                                        <x-heroicon-s-arrow-path class="size-5 text-white" />
                                                        @break
                                                    @default
                                                        <x-heroicon-s-information-circle class="size-5 text-white" />
                                                    @endswitch
                                                </span>
                                            </div>

                                            <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                                                <div>
                                                    <p class="text-sm text-gray-500">
                                                        {!! $activity->description !!}
                                                        @if
                                                            ($activity->causer)
                                                            by
                                                            <span class="font-medium text-gray-900">
                                                                {{ $activity->causer->name }}
                                                            </span>
                                                        @endif
                                                    </p>
                                                </div>

                                                <div class="whitespace-nowrap text-right text-sm text-gray-500">
                                                    <time datetime="{{ $activity->created_at->toIso8601String() }}">
                                                        {{ $activity->created_at->diffForHumans() }}
                                                    </time>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </li>
                            @endforeach
                        </ul>
                    </div>
                </x-slot>
            </x-contoso.form-section>
        @endif

        {{-- Form Actions --}}
        <div class="flex items-center justify-between border-t border-gray-200 pt-6">
            <div>
                @if
                    ($isEdit)
                    <x-contoso.action-button
                        action="deleteOrderAction"
                        variant="danger"
                        @if
                        order->
                        <x-slot:default>
                            isLocked())
                            disabled
                            wire:confirm="This order is locked. Are you absolutely sure?"
                            >
                            Delete Order
                        </x-slot>
                    </x-contoso.action-button>
                @endif
            </div>

            <div class="flex items-center gap-3">
                <a
                    href="{{ $isEdit ? route('orders.show', $order) : route('orders.index') }}"
                    class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50">
                    Cancel
                </a>
                @if
                    ($isEdit)
                    <x-contoso.action-button
                        type="submit"
                        variant="primary"
                        wire:loading.attr="disabled"
                        wire:target="updateOrder"
                        {{ $attributes->merge(['class' => 'relative']) }}>
                        <x-slot:default>
                            <span wire:loading.remove wire:target="updateOrder">Update Order</span>
                            <span wire:loading wire:target="updateOrder" class="inline-flex items-center gap-1">
                                <x-heroicon-o-arrow-path class="size-4 animate-spin" />
                                Saving...
                            </span>
                        </x-slot>
                    </x-contoso.action-button>
                @else
                    <button
                        type="submit"
                        wire:loading.attr="disabled"
                        wire:target="createOrder"
                        @class([
                            'relative inline-flex items-center rounded-md px-4 py-2 text-sm font-medium text-white shadow-sm',
                            'bg-navy-600 hover:bg-navy-700 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2',
                        ])>
                        <span wire:loading.remove wire:target="createOrder">Create Order</span>
                        <span wire:loading wire:target="createOrder" class="inline-flex items-center gap-1">
                            <x-heroicon-o-arrow-path class="size-4 animate-spin" />
                            Creating...
                        </span>
                    </button>
                @endif
            </div>
        </div>
    </div>
</form>

