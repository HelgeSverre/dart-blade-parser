{{-- Component Attributes Bag Usage --}}
{{-- Component Definition: resources/views/components/modal.blade.php --}}
@props([
    'show' => false,
    'maxWidth' => 'md',
    'closeable' => true
])

@php
    $maxWidthClasses = match($maxWidth) {
        'sm' => 'max-w-sm',
        'md' => 'max-w-md',
        'lg' => 'max-w-lg',
        'xl' => 'max-w-xl',
        '2xl' => 'max-w-2xl',
        default => 'max-w-md'
    };
@endphp

<div
    x-data="{ show: @js($show) }"
    x-show="show"
    {{ $attributes->class(['modal-overlay fixed inset-0 z-50 overflow-y-auto'])
        ->merge(['style' => 'display: none;']) }}
>
    <div class="flex items-center justify-center min-h-screen px-4">
        {{-- Backdrop --}}
        <div
            x-show="show"
            class="fixed inset-0 bg-black opacity-50"
            @if($closeable)
                @click="show = false"
            @endif
        ></div>

        {{-- Modal Content --}}
        <div
            {{ $attributes->only(['id', 'data-*'])->class([
                'modal-content bg-white rounded-lg shadow-xl relative z-10 w-full',
                $maxWidthClasses
            ]) }}
            x-show="show"
            x-transition:enter="transition ease-out duration-300"
            x-transition:enter-start="opacity-0 transform scale-95"
            x-transition:enter-end="opacity-100 transform scale-100"
        >
            @if($closeable)
                <button
                    @click="show = false"
                    class="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
                    {{ $attributes->filter(fn($value, $key) => str_starts_with($key, 'aria-')) }}
                >
                    <svg class="h-6 w-6">...</svg>
                </button>
            @endif

            <div {{ $attributes->except(['class', 'style', 'id', 'data-*', 'aria-*']) }}>
                {{ $slot }}
            </div>
        </div>
    </div>
</div>

{{-- Component Usage Examples --}}
<div class="page">
    <x-modal
        :show="$errors->any()"
        maxWidth="lg"
        id="error-modal"
        data-modal-type="error"
        aria-labelledby="modal-title"
        class="error-modal"
        style="z-index: 9999;"
    >
        <div class="p-6">
            <h2 id="modal-title" class="text-2xl font-bold text-red-600 mb-4">
                Error Occurred
            </h2>
            <p class="text-gray-700">{{ $errors->first() }}</p>
        </div>
    </x-modal>

    <x-modal :show="false" :closeable="false" maxWidth="sm">
        <div class="text-center p-8">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p class="mt-4 text-gray-600">Processing...</p>
        </div>
    </x-modal>
</div>
