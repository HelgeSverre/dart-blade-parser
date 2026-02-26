@props([
    'variant' => 'default',
    'modal' => null,
    'modalParams' => null,
    'action' => null,
    'tooltip' => null,
    'type' => 'button',
])

@php
    $baseClasses = implode(' ', [
        'whitespace-nowrap max-h-8 inline-flex items-center',
        'px-2.5 py-2 text-sm font-medium leading-4 rounded-md',
        'focus:outline-none focus:ring-2 focus:ring-offset-2',
    ]);

    $variants = [
        'primary' => 'justify-center border-transparent bg-navy-600 text-white focus:ring-navy-500 disabled:bg-navy-200 disabled:text-white/80 dark:disabled:bg-navy-200 dark:disabled:text-white/80',
        'danger' => 'justify-center border-transparent bg-red-600 text-white focus:ring-red-500 disabled:bg-red-300 disabled:text-white/80 dark:disabled:bg-red-300 dark:disabled:text-white/80',
        'default' => 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-navy-500 disabled:bg-gray-200 disabled:text-gray-400 dark:disabled:bg-gray-200 dark:disabled:text-gray-400',
    ];

    $classes = $baseClasses.' '.($variants[$variant] ?? $variants['default']);
@endphp

@if ($attributes->has('href'))
    <a
        {{ $attributes->merge(['class' => $classes]) }}
        @if ($tooltip)
            x-data
            x-tooltip.raw="{{ $tooltip }}"
        @endif
    >
        {{ $slot }}
    </a>
@else
    <button
        type="{{ $type ?? 'button' }}"
        {{ $attributes->merge(['class' => $classes]) }}
        @if ($modal)
            wire:click="$dispatch('openModal', { component: '{{ $modal }}', arguments: @js($modalParams) })"
        @endif
        @if ($action)
            wire:click="mountAction('{{ $action }}')"
        @endif
        @if ($tooltip)
            x-data
            x-tooltip.raw="{{ $tooltip }}"
        @endif
    >
        {{ $slot }}
    </button>
@endif
