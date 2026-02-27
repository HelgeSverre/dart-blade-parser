@props([
    'sortings' => [],
    'currentSort' => null,
    'currentDir' => null,
    'wireModel' => null,
])

@php
    $isActiveSort = function ($sort, $dir) use ($currentSort, $currentDir) {
        return $currentSort === $sort && $currentDir === $dir;
    };
@endphp

<div class="relative rounded-md" x-data="dropdown">
    <button
        x-bind="trigger"
        type="button"
        class="inline-flex items-center justify-center rounded-md border border-gray-300 bg-white px-2.5 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2"
    >
        @svg('heroicon-o-arrows-up-down', 'size-5 text-gray-400')
    </button>

    <div
        x-bind="dialog"
        x-cloak
        class="absolute left-0 z-20 mt-2 w-56 origin-top-left divide-y divide-gray-100 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        role="menu"
        tabindex="-1"
    >
        <div class="py-1">
            @foreach ($sortings as $label => $option)
                <button
                    type="button"
                    x-on:click="
                        @if ($wireModel)
                            $wire.call('setSort',
                            '{{ $option['sort'] }}',
                            '{{ $option['dir'] }}')
                        @else
                            $dispatch('sort-changed',
                            {
                            sort: '{{ $option['sort'] }}',
                            dir: '{{ $option['dir'] }}'
                            })
                        @endif
                        closeDialog()
                    "
                    @class([
                        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-100',
                        'block w-full px-4 py-2 text-left text-sm',
                        'bg-gray-100 text-gray-900' => $isActiveSort($option['sort'], $option['dir']),
                        'text-gray-700' => ! $isActiveSort($option['sort'], $option['dir']),
                    ])
                >
                    {{ $label }}
                </button>
            @endforeach
        </div>
    </div>
</div>
