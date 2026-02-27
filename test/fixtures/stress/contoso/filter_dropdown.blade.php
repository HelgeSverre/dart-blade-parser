@props([
    'filters' => [],
    'currentFilter' => null,
    'max' => 10,
    'wireModel' => null,
])

@php
    $formattedFilters = collect($filters)->map(function ($value, $key) {
        if (is_array($value)) {
            return [
                'label' => $key,
                'value' => $value['value'] ?? $key,
                'color' => $value['color'] ?? null,
            ];
        }

        return [
            'label' => $key,
            'value' => $value,
            'color' => null,
        ];
    })->values();

    $visibleFilters = $formattedFilters->take($max);
    $dropdownFilters = $formattedFilters->skip($max);
@endphp

<div class="w-full">
    {{-- Mobile --}}
    <div class="w-full md:hidden">
        <select
            @if ($wireModel)
                wire:model.live="{{ $wireModel }}"
            @else
                x-model="selectedFilter"
                x-on:change="$dispatch('filter-changed', { filter: $event.target.value })"
            @endif
            class="block w-full rounded-md border-gray-300 bg-white py-2 pl-3 pr-10 text-sm text-gray-700 focus:border-navy-500 focus:outline-none focus:ring-navy-500"
        >
            @foreach ($formattedFilters as $filter)
                <option
                    @if ($filter['color'])
                        style="background-color: {{ $filter['color'] }};"
                    @endif
                    value="{{ $filter['value'] }}"
                >
                    {{ $filter['label'] }}
                </option>
            @endforeach
        </select>
    </div>

    {{-- Desktop --}}
    <span class="relative z-0 hidden rounded-md shadow-sm md:inline-flex">
        @foreach ($visibleFilters as $filter)
            <button
                type="button"
                x-on:click="
                    @if ($wireModel)
                        $wire.set('{{ $wireModel }}',
                        '{{ $filter['value'] }}')
                    @else
                        $dispatch('filter-changed',
                        {
                        filter: '{{ $filter['value'] }}'
                        })
                    @endif
                "
                @class([
                    'relative -ml-px inline-flex items-center truncate border border-gray-300 px-1 py-1.5 text-xs font-medium hover:bg-gray-50 focus:z-10 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2 lg:px-3 lg:text-sm',
                    'bg-gray-100 text-gray-900' => $currentFilter == $filter['value'],
                    'bg-white text-gray-700' => $currentFilter != $filter['value'],
                    'rounded-l-md' => $loop->first,
                    'rounded-r-md' => $dropdownFilters->isEmpty() && $loop->last,
                ])
            >
                <span>{{ $filter['label'] }}</span>
                @if ($filter['color'])
                    <span class="ml-1">
                        <svg
                            class="size-3"
                            fill="currentColor"
                            viewBox="0 0 8 8"
                            style="color: {{ $filter['color'] }}"
                        >
                            <circle cx="4" cy="4" r="3" />
                        </svg>
                    </span>
                @endif
            </button>
        @endforeach

        @if ($dropdownFilters->isNotEmpty())
            <div class="relative -ml-px" x-data="{ open: false }">
                <button
                    type="button"
                    x-on:click="open = !open"
                    x-on:click.outside="open = false"
                    class="relative inline-flex h-full items-center rounded-r-md border border-gray-300 bg-white px-1 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2 lg:px-3 lg:text-sm"
                >
                    <svg
                        class="size-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 9l-7 7-7-7"
                        />
                    </svg>
                </button>

                <div
                    x-cloak
                    x-show="open"
                    x-transition
                    x-trap="open"
                    class="absolute right-0 mt-2 w-48 origin-top-right rounded-md border border-gray-200 bg-white shadow-lg focus:outline-none"
                    role="menu"
                >
                    <div class="py-1">
                        @foreach ($dropdownFilters as $filter)
                            <button
                                type="button"
                                x-on:click="
                                    @if ($wireModel)
                                        $wire.set('{{ $wireModel }}',
                                        '{{ $filter['value'] }}')
                                    @else
                                        $dispatch('filter-changed',
                                        {
                                        filter: '{{ $filter['value'] }}'
                                        })
                                    @endif
                                    open = false
                                "
                                @class([
                                    'block w-full px-4 py-2 text-left text-sm hover:bg-gray-50',
                                    'bg-gray-100 text-gray-900' => $currentFilter === $filter['value'],
                                    'text-gray-700' => $currentFilter !== $filter['value'],
                                ])
                            >
                                <span class="flex items-center justify-between">
                                    <span>{{ $filter['label'] }}</span>
                                    @if ($filter['color'])
                                        <span class="ml-1">
                                            <svg
                                                class="size-3"
                                                fill="currentColor"
                                                viewBox="0 0 8 8"
                                                style="
                                                    color: {{ $filter['color'] }};
                                                "
                                            >
                                                <circle cx="4" cy="4" r="3" />
                                            </svg>
                                        </span>
                                    @endif
                                </span>
                            </button>
                        @endforeach
                    </div>
                </div>
            </div>
        @endif
    </span>
</div>
