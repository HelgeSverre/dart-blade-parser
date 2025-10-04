{{--
---
features:
  - if_directive
  - alpine_x_data
  - wire_model_live
  - error_directive
description: Conditional form fields with Alpine.js state and Livewire validation
complexity: moderate
line_count: 70
--}}

<div
    x-data="{
        accountType: @entangle('accountType'),
        showBusinessFields: false,
        agreedToTerms: false
    }"
    class="registration-form"
>
    <h2 class="text-2xl font-bold mb-6">Create Account</h2>

    <div class="form-group">
        <label class="block mb-2">Account Type</label>
        <select
            wire:model.live="accountType"
            x-model="accountType"
            class="form-select w-full"
        >
            <option value="">Select type...</option>
            <option value="personal">Personal</option>
            <option value="business">Business</option>
            <option value="nonprofit">Non-Profit</option>
        </select>
        @error('accountType')
            <span class="text-red-500 text-sm">{{ $message }}</span>
        @enderror
    </div>

    @if ($accountType === 'personal')
        <div class="form-group mt-4">
            <label class="block mb-2">Full Name</label>
            <input
                type="text"
                wire:model.live="fullName"
                class="form-input w-full"
                placeholder="John Doe"
            >
            @error('fullName')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div class="form-group mt-4">
            <label class="block mb-2">Date of Birth</label>
            <input
                type="date"
                wire:model="dateOfBirth"
                class="form-input w-full"
            >
            @error('dateOfBirth')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>
    @endif

    @if ($accountType === 'business' || $accountType === 'nonprofit')
        <div class="form-group mt-4">
            <label class="block mb-2">Organization Name</label>
            <input
                type="text"
                wire:model.live="organizationName"
                class="form-input w-full"
                placeholder="Acme Corporation"
            >
            @error('organizationName')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div class="form-group mt-4">
            <label class="block mb-2">Tax ID / EIN</label>
            <input
                type="text"
                wire:model="taxId"
                class="form-input w-full"
                placeholder="XX-XXXXXXX"
            >
            @error('taxId')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>
    @endif

    <div class="mt-6">
        <button
            type="submit"
            wire:click="register"
            x-bind:disabled="!agreedToTerms"
            class="btn btn-primary w-full"
        >
            Create Account
        </button>
    </div>
</div>
