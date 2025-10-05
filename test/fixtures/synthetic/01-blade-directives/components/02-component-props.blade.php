{{-- Component with @props Directive --}}
{{-- Component Definition: resources/views/components/button.blade.php --}}
@props([
    'type' => 'button',
    'variant' => 'primary',
    'size' => 'md',
    'disabled' => false,
    'loading' => false,
    'icon' => null
])

@php
    $classes = match($variant) {
        'primary' => 'bg-blue-600 hover:bg-blue-700 text-white',
        'secondary' => 'bg-gray-600 hover:bg-gray-700 text-white',
        'danger' => 'bg-red-600 hover:bg-red-700 text-white',
        'outline' => 'border-2 border-blue-600 text-blue-600 hover:bg-blue-50',
        default => 'bg-gray-200 hover:bg-gray-300 text-gray-800'
    };

    $sizeClasses = match($size) {
        'sm' => 'px-3 py-1 text-sm',
        'md' => 'px-4 py-2 text-base',
        'lg' => 'px-6 py-3 text-lg',
        default => 'px-4 py-2'
    };
@endphp

<button
    type="{{ $type }}"
    {{ $attributes->merge([
        'class' => "btn {$classes} {$sizeClasses} rounded-md font-medium transition-colors"
    ]) }}
    @if($disabled || $loading) disabled @endif
>
    @if($loading)
        <svg class="animate-spin h-5 w-5 mr-2 inline-block">...</svg>
    @endif

    @if($icon)
        <x-icon :name="$icon" class="mr-2" />
    @endif

    {{ $slot }}
</button>

{{-- Component Usage Examples --}}
<div class="button-examples">
    <x-button>Default Button</x-button>

    <x-button variant="primary" size="lg">
        Primary Large
    </x-button>

    <x-button variant="danger" :disabled="true">
        Disabled Danger
    </x-button>

    <x-button variant="outline" :loading="$isProcessing" type="submit">
        Submit Form
    </x-button>

    <x-button variant="secondary" icon="trash" class="mt-4">
        Delete Item
    </x-button>
</div>
