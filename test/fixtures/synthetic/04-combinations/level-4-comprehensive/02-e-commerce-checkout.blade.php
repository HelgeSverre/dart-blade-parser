---
description: "Complete e-commerce checkout flow with multi-step forms, payment methods, and order summary"
features:
  - "@extends layout with sections"
  - "Multi-step wizard with Alpine.js state"
  - "@switch/@case for payment method selection"
  - "Multiple Livewire components and wire:model bindings"
  - "Complex form validation with @error"
  - "Custom components (x-cart-item, x-payment-method, x-address-form)"
  - "@foreach loops for cart items and addresses"
  - "Alpine.js x-show and x-transition for step transitions"
  - "Conditional rendering with @if/@elseif/@else"
  - "@isset and @empty checks"
  - "wire:click for actions and navigation"
  - "Real-time price calculations"
  - "@push for scripts and styles"
level: 4
complexity: comprehensive
line_count: ~210
---
@extends('layouts.shop')

@section('title', 'Checkout')

@push('styles')
<style>
    [x-cloak] { display: none !important; }
    .step-indicator { @apply relative flex items-center justify-center w-10 h-10 rounded-full border-2 transition-all; }
    .step-indicator.active { @apply border-blue-600 bg-blue-600 text-white; }
    .step-indicator.completed { @apply border-green-600 bg-green-600 text-white; }
    .step-indicator.inactive { @apply border-gray-300 bg-white text-gray-400; }
</style>
@endpush

@section('content')
<div class="min-h-screen bg-gray-50 py-8" x-data="checkoutWizard()" x-init="init()">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {{-- Checkout Header --}}
        <div class="mb-8">
            <h1 class="text-3xl font-bold text-gray-900">Checkout</h1>
            <p class="mt-2 text-gray-600">Complete your purchase in just a few steps</p>
        </div>

        {{-- Progress Indicator --}}
        <div class="mb-8 bg-white rounded-lg shadow-sm p-6">
            <div class="flex items-center justify-between">
                @foreach(['Cart', 'Shipping', 'Payment', 'Review'] as $index => $stepName)
                    <div class="flex items-center" :class="{ 'flex-1': {{ $index }} < 3 }">
                        <div class="flex items-center">
                            <div class="step-indicator"
                                :class="{
                                    'active': currentStep === {{ $index + 1 }},
                                    'completed': currentStep > {{ $index + 1 }},
                                    'inactive': currentStep < {{ $index + 1 }}
                                }">
                                <template x-if="currentStep > {{ $index + 1 }}">
                                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                                    </svg>
                                </template>
                                <template x-if="currentStep <= {{ $index + 1 }}">
                                    <span>{{ $index + 1 }}</span>
                                </template>
                            </div>
                            <span class="ml-2 text-sm font-medium" :class="{ 'text-blue-600': currentStep === {{ $index + 1 }}, 'text-gray-500': currentStep !== {{ $index + 1 }} }">
                                {{ $stepName }}
                            </span>
                        </div>
                        @if($index < 3)
                            <div class="flex-1 h-0.5 mx-4 bg-gray-200" :class="{ 'bg-green-600': currentStep > {{ $index + 1 }} }"></div>
                        @endif
                    </div>
                @endforeach
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {{-- Main Form Area --}}
            <div class="lg:col-span-2 space-y-6">
                {{-- Step 1: Cart Review --}}
                <div x-show="currentStep === 1" x-transition class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-xl font-semibold mb-4">Shopping Cart</h2>

                    @if(count($cartItems) > 0)
                        <div class="space-y-4">
                            @foreach($cartItems as $item)
                                <x-cart-item :item="$item" wire:key="cart-item-{{ $item->id }}">
                                    <x-slot name="actions">
                                        <div class="flex items-center space-x-2">
                                            <button wire:click="decreaseQuantity({{ $item->id }})" class="p-1 rounded-md hover:bg-gray-100">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4"></path>
                                                </svg>
                                            </button>
                                            <input type="number" wire:model.blur="cartItems.{{ $loop->index }}.quantity" min="1" class="w-16 text-center border-gray-300 rounded-md">
                                            <button wire:click="increaseQuantity({{ $item->id }})" class="p-1 rounded-md hover:bg-gray-100">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                                                </svg>
                                            </button>
                                            <button wire:click="removeItem({{ $item->id }})" class="ml-4 text-red-600 hover:text-red-800">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                                </svg>
                                            </button>
                                        </div>
                                    </x-slot>
                                </x-cart-item>
                            @endforeach
                        </div>
                    @else
                        <div class="text-center py-12">
                            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path>
                            </svg>
                            <p class="mt-2 text-gray-500">Your cart is empty</p>
                        </div>
                    @endif
                </div>

                {{-- Step 2: Shipping Information --}}
                <div x-show="currentStep === 2" x-transition class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-xl font-semibold mb-4">Shipping Information</h2>

                    {{-- Saved Addresses --}}
                    @isset($savedAddresses)
                        @if(count($savedAddresses) > 0)
                            <div class="mb-6">
                                <label class="block text-sm font-medium text-gray-700 mb-3">Select Saved Address</label>
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    @foreach($savedAddresses as $address)
                                        <div wire:click="selectAddress({{ $address->id }})"
                                            class="border-2 rounded-lg p-4 cursor-pointer transition-all hover:border-blue-500"
                                            :class="{ 'border-blue-600 bg-blue-50': $wire.selectedAddressId === {{ $address->id }} }">
                                            <div class="flex items-start justify-between">
                                                <div class="flex-1">
                                                    <p class="font-medium text-gray-900">{{ $address->name }}</p>
                                                    <p class="text-sm text-gray-600">{{ $address->street }}</p>
                                                    <p class="text-sm text-gray-600">{{ $address->city }}, {{ $address->state }} {{ $address->zip }}</p>
                                                    <p class="text-sm text-gray-600">{{ $address->country }}</p>
                                                </div>
                                                <input type="radio" name="address" :checked="$wire.selectedAddressId === {{ $address->id }}" class="mt-1">
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                        @endif
                    @endisset

                    {{-- New Address Form --}}
                    <div x-show="showNewAddressForm || {{ empty($savedAddresses) ? 'true' : 'false' }}" x-transition>
                        <x-address-form wire:model="shippingAddress">
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">First Name *</label>
                                    <input type="text" wire:model.blur="shippingAddress.first_name" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.first_name') border-red-300 @enderror">
                                    @error('shippingAddress.first_name')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">Last Name *</label>
                                    <input type="text" wire:model.blur="shippingAddress.last_name" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.last_name') border-red-300 @enderror">
                                    @error('shippingAddress.last_name')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div class="md:col-span-2">
                                    <label class="block text-sm font-medium text-gray-700">Street Address *</label>
                                    <input type="text" wire:model.blur="shippingAddress.street" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.street') border-red-300 @enderror">
                                    @error('shippingAddress.street')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">City *</label>
                                    <input type="text" wire:model.blur="shippingAddress.city" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.city') border-red-300 @enderror">
                                    @error('shippingAddress.city')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">State *</label>
                                    <select wire:model.blur="shippingAddress.state" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.state') border-red-300 @enderror">
                                        <option value="">Select State</option>
                                        @foreach($states as $code => $name)
                                            <option value="{{ $code }}">{{ $name }}</option>
                                        @endforeach
                                    </select>
                                    @error('shippingAddress.state')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">ZIP Code *</label>
                                    <input type="text" wire:model.blur="shippingAddress.zip" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.zip') border-red-300 @enderror">
                                    @error('shippingAddress.zip')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700">Phone *</label>
                                    <input type="tel" wire:model.blur="shippingAddress.phone" class="mt-1 block w-full rounded-md border-gray-300 @error('shippingAddress.phone') border-red-300 @enderror">
                                    @error('shippingAddress.phone')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                            </div>
                        </x-address-form>
                    </div>
                </div>

                {{-- Step 3: Payment Method --}}
                <div x-show="currentStep === 3" x-transition class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-xl font-semibold mb-4">Payment Method</h2>

                    <div class="space-y-4">
                        @switch($paymentMethods ?? 'card')
                            @case('card')
                                <x-payment-method method="card" :selected="$selectedPaymentMethod === 'card'" wire:click="selectPaymentMethod('card')">
                                    <div class="mt-4" x-show="$wire.selectedPaymentMethod === 'card'" x-transition>
                                        <div class="space-y-4">
                                            <div>
                                                <label class="block text-sm font-medium text-gray-700">Card Number *</label>
                                                <input type="text" wire:model.blur="payment.card_number" placeholder="1234 5678 9012 3456" class="mt-1 block w-full rounded-md border-gray-300 @error('payment.card_number') border-red-300 @enderror">
                                                @error('payment.card_number')
                                                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                                @enderror
                                            </div>
                                            <div class="grid grid-cols-2 gap-4">
                                                <div>
                                                    <label class="block text-sm font-medium text-gray-700">Expiry Date *</label>
                                                    <input type="text" wire:model.blur="payment.expiry" placeholder="MM/YY" class="mt-1 block w-full rounded-md border-gray-300 @error('payment.expiry') border-red-300 @enderror">
                                                    @error('payment.expiry')
                                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                                    @enderror
                                                </div>
                                                <div>
                                                    <label class="block text-sm font-medium text-gray-700">CVV *</label>
                                                    <input type="text" wire:model.blur="payment.cvv" placeholder="123" class="mt-1 block w-full rounded-md border-gray-300 @error('payment.cvv') border-red-300 @enderror">
                                                    @error('payment.cvv')
                                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                                    @enderror
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </x-payment-method>
                            @break

                            @case('paypal')
                                <x-payment-method method="paypal" :selected="$selectedPaymentMethod === 'paypal'" wire:click="selectPaymentMethod('paypal')">
                                    <div class="mt-4" x-show="$wire.selectedPaymentMethod === 'paypal'" x-transition>
                                        <p class="text-sm text-gray-600">You will be redirected to PayPal to complete your purchase.</p>
                                    </div>
                                </x-payment-method>
                            @break

                            @case('bank')
                                <x-payment-method method="bank" :selected="$selectedPaymentMethod === 'bank'" wire:click="selectPaymentMethod('bank')">
                                    <div class="mt-4" x-show="$wire.selectedPaymentMethod === 'bank'" x-transition>
                                        <p class="text-sm text-gray-600">Bank transfer details will be provided after order confirmation.</p>
                                    </div>
                                </x-payment-method>
                            @break

                            @default
                                <x-payment-method method="card" :selected="true" wire:click="selectPaymentMethod('card')">
                                    <p class="text-sm text-gray-600">Credit or Debit Card</p>
                                </x-payment-method>
                        @endswitch
                    </div>
                </div>

                {{-- Step 4: Review & Confirm --}}
                <div x-show="currentStep === 4" x-transition class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-xl font-semibold mb-4">Review Your Order</h2>

                    {{-- Order Summary Details --}}
                    <div class="space-y-6">
                        <div>
                            <h3 class="font-medium text-gray-900 mb-2">Shipping Address</h3>
                            <div class="text-sm text-gray-600">
                                <p>{{ $shippingAddress['first_name'] ?? '' }} {{ $shippingAddress['last_name'] ?? '' }}</p>
                                <p>{{ $shippingAddress['street'] ?? '' }}</p>
                                <p>{{ $shippingAddress['city'] ?? '' }}, {{ $shippingAddress['state'] ?? '' }} {{ $shippingAddress['zip'] ?? '' }}</p>
                            </div>
                        </div>

                        <div>
                            <h3 class="font-medium text-gray-900 mb-2">Payment Method</h3>
                            <p class="text-sm text-gray-600 capitalize">{{ $selectedPaymentMethod ?? 'Not selected' }}</p>
                        </div>

                        <div>
                            <h3 class="font-medium text-gray-900 mb-2">Order Items</h3>
                            <div class="space-y-2">
                                @foreach($cartItems as $item)
                                    <div class="flex justify-between text-sm">
                                        <span>{{ $item->name }} x {{ $item->quantity }}</span>
                                        <span>${{ number_format($item->price * $item->quantity, 2) }}</span>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    </div>
                </div>

                {{-- Navigation Buttons --}}
                <div class="flex justify-between items-center">
                    <button
                        x-show="currentStep > 1"
                        @click="previousStep()"
                        class="btn-secondary">
                        Previous
                    </button>
                    <div x-show="currentStep === 1"></div>

                    <button
                        x-show="currentStep < 4"
                        @click="nextStep()"
                        class="btn-primary">
                        Next
                    </button>
                    <button
                        x-show="currentStep === 4"
                        wire:click="placeOrder"
                        wire:loading.attr="disabled"
                        class="btn-primary">
                        <span wire:loading.remove wire:target="placeOrder">Place Order</span>
                        <span wire:loading wire:target="placeOrder">Processing...</span>
                    </button>
                </div>
            </div>

            {{-- Order Summary Sidebar --}}
            <div class="lg:col-span-1">
                <div class="bg-white rounded-lg shadow-sm p-6 sticky top-6">
                    <h2 class="text-lg font-semibold mb-4">Order Summary</h2>

                    <div class="space-y-3 mb-4">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Subtotal</span>
                            <span class="font-medium">${{ number_format($subtotal, 2) }}</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Shipping</span>
                            <span class="font-medium">${{ number_format($shipping, 2) }}</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Tax</span>
                            <span class="font-medium">${{ number_format($tax, 2) }}</span>
                        </div>
                        @if($discount > 0)
                            <div class="flex justify-between text-sm text-green-600">
                                <span>Discount</span>
                                <span class="font-medium">-${{ number_format($discount, 2) }}</span>
                            </div>
                        @endif
                        <div class="border-t pt-3 flex justify-between">
                            <span class="font-semibold">Total</span>
                            <span class="font-bold text-lg">${{ number_format($total, 2) }}</span>
                        </div>
                    </div>

                    {{-- Promo Code --}}
                    <div class="mt-4">
                        <label class="block text-sm font-medium text-gray-700 mb-2">Promo Code</label>
                        <div class="flex space-x-2">
                            <input type="text" wire:model="promoCode" placeholder="Enter code" class="flex-1 rounded-md border-gray-300">
                            <button wire:click="applyPromoCode" class="btn-secondary">Apply</button>
                        </div>
                        @error('promoCode')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    function checkoutWizard() {
        return {
            currentStep: 1,
            init() {
                // Initialize payment processing
                this.setupPaymentProcessor();
            },
            nextStep() {
                if (this.validateCurrentStep()) {
                    this.currentStep++;
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            },
            previousStep() {
                this.currentStep--;
                window.scrollTo({ top: 0, behavior: 'smooth' });
            },
            validateCurrentStep() {
                return @this.validateStep(this.currentStep);
            },
            setupPaymentProcessor() {
                // Setup Stripe or other payment processor
            }
        }
    }
</script>
@endpush
