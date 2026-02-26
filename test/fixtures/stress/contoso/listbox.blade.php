@props([
    'options' => [],
    'value' => null,
    'placeholder' => null,
    'enum' => null,
    'tooltip' => null,
    'icon' => false,
    'nullable' => true,
])

@php
    if ($enum) {
        $formattedOptions = collect($enum::cases())->map(fn ($case) => [
            'label' => method_exists($case, 'getLabel') ? $case->getLabel() : $case->name,
            'value' => $case->value,
        ]);
    } else {
        $formattedOptions = array_is_list($options)
            ? collect($options)
            : collect($options)->map(function ($label, $value) {
                return [
                    'label' => $value,
                    'value' => $label,
                ];
            });
    }
    $displayLabel = $formattedOptions->firstWhere('value', $value)['label'] ?? $placeholder;
@endphp

<div
    wire:ignore.self
    {{ $attributes->merge(['class' => 'relative']) }}
    x-data="dropdown"
>
    <button
        x-bind="trigger"
        type="button"
        class="inline-flex items-center justify-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium leading-5 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2"
        @if ($tooltip)
            x-tooltip.raw="{{ $tooltip }}"
        @endif
    >
        @unless ($icon === false)
            @svg($icon, 'size-5 fill-gray-50 text-gray-400')
        @endunless

        @if ($displayLabel)
            <span
                @class([
                    'block truncate ',
                    'text-gray-400' => ! $value && $placeholder,
                    'text-gray-700' => $value,
                ])
            >
                {{ $displayLabel }}
            </span>
        @endif
    </button>

    <div
        x-cloak
        x-bind="dialog"
        class="absolute left-0 z-20 mt-2 w-56 origin-top-left divide-y divide-gray-100 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
    >
        <div class="py-1">
            @foreach ($formattedOptions as $option)
                <div
                    @class([
                        'group flex w-full items-center justify-between text-sm hover:bg-gray-50',
                        'bg-gray-100' => $value === $option['value'],
                    ])
                >
                    <button
                        class="block w-full whitespace-nowrap px-4 py-2 text-left"
                        type="button"
                        x-on:click="
                        @if ($attributes->wire('model')->value())
                            $wire.set('{{ $attributes->wire('model')->value() }}',
                            '{{ $option['value'] }}')
                        @endif
                        $dispatch('input', '{{ $option['value'] }}')
                        closeDialog()
                    "
                    >
                        {{ $option['label'] }}
                    </button>

                    @if ($nullable === true && $value === $option['value'])
                        <button
                            type="button"
                            class="px-2 py-2 text-gray-400 hover:text-gray-600"
                            x-on:click="
                            @if ($attributes->wire('model')->value())
                                $wire.set('{{ $attributes->wire('model')->value() }}',
                                null)
                            @endif
                            $dispatch('input', null)
                            closeDialog()
                        "
                        >
                            @svg('heroicon-o-x-mark', 'size-5')
                        </button>
                    @endif
                </div>
            @endforeach
        </div>
    </div>
</div>
