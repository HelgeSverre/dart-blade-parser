{{-- Basic Component Usage --}}
{{-- Component Definition: resources/views/components/alert.blade.php --}}
<div {{ $attributes->merge(['class' => 'alert']) }}>
    <div class="alert-icon">
        @if($type === 'success')
            <svg class="icon-success">...</svg>
        @elseif($type === 'error')
            <svg class="icon-error">...</svg>
        @else
            <svg class="icon-info">...</svg>
        @endif
    </div>
    <div class="alert-content">
        {{ $slot }}
    </div>
</div>

{{-- Component Usage Examples --}}
<div class="container">
    {{-- Basic usage --}}
    <x-alert type="success">
        Your changes have been saved successfully!
    </x-alert>

    {{-- With additional attributes --}}
    <x-alert type="error" class="mb-4" id="error-alert">
        An error occurred while processing your request.
    </x-alert>

    {{-- With data attributes --}}
    <x-alert
        type="info"
        data-dismissible="true"
        data-timeout="5000"
    >
        This notification will auto-dismiss in 5 seconds.
    </x-alert>

    {{-- Nested components --}}
    <x-alert type="success" class="border-2">
        <strong>Success!</strong>
        <span>Your profile has been updated.</span>
        <x-button variant="link">View Profile</x-button>
    </x-alert>
</div>
