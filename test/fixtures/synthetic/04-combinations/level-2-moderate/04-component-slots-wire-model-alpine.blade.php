{{--
---
features:
  - component_tags
  - named_slots
  - wire_model
  - alpine_x_data
description: Interactive modal with multiple slots, two-way binding, and Alpine state management
complexity: moderate
line_count: 80
--}}

<div
    x-data="{
        open: @entangle('showModal'),
        selectedPlan: @entangle('selectedPlan'),
        billingCycle: 'monthly'
    }"
    class="pricing-section"
>
    <button
        @click="open = true"
        class="btn btn-primary"
    >
        View Pricing Plans
    </button>

    <x-modal
        wire:model="showModal"
        x-show="open"
        @click.away="open = false"
        max-width="2xl"
    >
        <x-slot:title>
            <div class="flex items-center justify-between">
                <h2 class="text-2xl font-bold">Choose Your Plan</h2>
                <button
                    @click="open = false"
                    class="text-gray-500 hover:text-gray-700"
                >
                    ✕
                </button>
            </div>
        </x-slot:title>

        <x-slot:header>
            <div class="billing-toggle flex items-center justify-center gap-4 py-4">
                <span :class="billingCycle === 'monthly' ? 'font-bold' : 'text-gray-500'">
                    Monthly
                </span>
                <button
                    @click="billingCycle = billingCycle === 'monthly' ? 'annual' : 'monthly'"
                    class="toggle-switch"
                >
                    <span class="sr-only">Toggle billing cycle</span>
                </button>
                <span :class="billingCycle === 'annual' ? 'font-bold' : 'text-gray-500'">
                    Annual <span class="text-green-600 text-sm">(Save 20%)</span>
                </span>
            </div>
        </x-slot:header>

        <div class="plans-grid grid grid-cols-3 gap-6 py-6">
            @foreach ($plans as $plan)
                <div
                    wire:key="plan-{{ $plan->id }}"
                    @click="selectedPlan = '{{ $plan->id }}'"
                    :class="selectedPlan === '{{ $plan->id }}' ? 'border-blue-500 ring-2 ring-blue-200' : 'border-gray-200'"
                    class="plan-card border-2 rounded-lg p-6 cursor-pointer transition-all hover:shadow-lg"
                >
                    <h3 class="text-xl font-bold mb-2">{{ $plan->name }}</h3>

                    <div class="price mb-4">
                        <span class="text-3xl font-bold">
                            $<span x-text="billingCycle === 'monthly' ? '{{ $plan->monthly_price }}' : '{{ $plan->annual_price }}'"></span>
                        </span>
                        <span class="text-gray-500" x-text="'/' + billingCycle"></span>
                    </div>

                    <ul class="features space-y-2 mb-6">
                        @foreach ($plan->features as $feature)
                            <li class="flex items-center gap-2">
                                <span class="text-green-500">✓</span>
                                <span class="text-sm">{{ $feature }}</span>
                            </li>
                        @endforeach
                    </ul>

                    <span
                        x-show="selectedPlan === '{{ $plan->id }}'"
                        class="text-sm text-blue-600 font-semibold"
                    >
                        Selected ✓
                    </span>
                </div>
            @endforeach
        </div>

        <x-slot:footer>
            <div class="flex items-center justify-between">
                <button
                    @click="open = false"
                    class="btn btn-outline"
                >
                    Cancel
                </button>

                <button
                    wire:click="subscribeToPlan"
                    :disabled="!selectedPlan"
                    class="btn btn-primary"
                >
                    Continue to Checkout
                </button>
            </div>
        </x-slot:footer>
    </x-modal>
</div>
