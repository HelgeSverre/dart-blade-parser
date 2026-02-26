<div
    id="contoso-mobile-menu"
    data-test-id="mobile-menu"
    class="relative z-40 md:hidden"
    role="dialog"
    aria-modal="true"
    x-show="open"
    x-trap.noscroll="open"
    x-cloak
>
    <div
        x-transition:enter="transition-opacity duration-300 ease-linear"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition-opacity duration-300 ease-linear"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        x-show="open"
        class="fixed inset-0 bg-gray-600 bg-opacity-75"
    ></div>

    <div class="fixed inset-0 z-40 flex">
        <div
            x-transition:enter="transform transition duration-300 ease-in-out"
            x-transition:enter-start="-translate-x-full"
            x-transition:enter-end="translate-x-0"
            x-transition:leave="transform transition duration-300 ease-in-out"
            x-transition:leave-start="translate-x-0"
            x-transition:leave-end="-translate-x-full"
            x-show="open"
            x-cloak
            class="relative flex w-full max-w-xs flex-1 flex-col bg-white pb-4 pt-5 font-sans"
            x-on:click.away="open = false"
        >
            <div
                x-transition:enter="duration-300 ease-in-out"
                x-transition:enter-start="opacity-0"
                x-transition:enter-end="opacity-100"
                x-transition:leave="duration-300 ease-in-out"
                x-transition:leave-start="opacity-100"
                x-transition:leave-end="opacity-0"
                x-show="open"
                x-cloak
                class="absolute right-0 top-0 -mr-12 pt-2"
            >
                <button
                    x-on:click="open = false"
                    type="button"
                    class="ml-1 flex size-10 items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                >
                    <span class="sr-only">Close menu</span>
                    @svg('heroicon-o-x-mark', 'size-6 text-white')
                </button>
            </div>

            <div class="flex flex-shrink-0 items-center px-4">
                <img
                    src="{{ asset('logo/color.svg') }}"
                    alt="Contoso"
                    class="block h-4 w-auto"
                />
            </div>
            <div class="mt-5 h-0 flex-1 overflow-y-auto">
                <nav
                    class="{{ $secondaryMenu->isNotEmpty() ? 'divide-y divide-gray-200' : '' }} flex-1 px-2 pb-4"
                >
                    <div class="space-y-1">
                        @foreach ($mainMenu as $link)
                            @if (isset($link['items']))
                                <div
                                    x-data="{ open: {{ $link['active'] ? 'true' : 'false' }} }"
                                >
                                    <div
                                        class="overflow-hidden rounded-md outline outline-1 outline-white transition-all duration-500"
                                        x-bind:class="{ '!outline-gray-200 bg-gray-50 mb-8 shadow-sm': open }"
                                    >
                                        <button
                                            type="button"
                                            x-on:click="open = !open"
                                            class="group flex w-full items-center border-b px-2 py-2 text-sm font-semibold tracking-wide text-gray-600 transition-all duration-200 hover:bg-gray-100 hover:text-gray-900"
                                            x-bind:class="{
                                                'border-gray-200 rounded-t-md': open,
                                                'border-white rounded-md': ! open,
                                            }"
                                        >
                                            <div class="flex items-center">
                                                @svg($link['icon'], 'mr-3 size-6 flex-shrink-0 text-gray-400 group-hover:text-gray-500')
                                                <span>
                                                    {{ $link['label'] }}
                                                </span>
                                            </div>

                                            <div class="ml-auto">
                                                <x-heroicon-o-chevron-down
                                                    class="size-5 text-gray-400 transition duration-200 ease-in-out"
                                                    x-bind:class="{'rotate-180': open}"
                                                />
                                            </div>
                                        </button>

                                        <div
                                            x-show="open"
                                            x-cloak
                                            x-collapse.duration.200ms
                                        >
                                            <div class="p-2 pt-0">
                                                @foreach ($link['items'] as $item)
                                                    @if ($item['visible'])
                                                        <a
                                                            wire:navigate
                                                            href="{{ $item['url'] }}"
                                                            @class([
                                                                'group my-1.5 flex items-center rounded-md px-1.5 py-1.5 text-xs font-semibold tracking-wide',
                                                                'text-gray-600 hover:bg-gray-200 hover:text-gray-900' => ! $item['active'],
                                                                'bg-navy-700 font-bold text-white dark:text-white' => $item['active'],
                                                            ])
                                                        >
                                                            @if ($item['active'])
                                                                @svg($item['icon'], 'mr-3 flex-shrink-0 size-5 text-white ')
                                                            @else
                                                                @svg($item['icon'], 'mr-3 size-5 flex-shrink-0 text-gray-400 group-hover:text-gray-500')
                                                            @endif

                                                            {{ $item['label'] }}
                                                        </a>
                                                    @endif
                                                @endforeach
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @else
                                <a
                                    href="{{ $link['url'] }}"
                                    wire:navigate
                                    @class([
                                        'group flex items-center rounded-md px-2 py-2 text-sm font-semibold tracking-wide',
                                        'text-gray-600 hover:bg-gray-100 hover:text-gray-900' => ! $link['active'],
                                        'bg-navy-700 font-bold text-white dark:text-white' => $link['active'],
                                    ])
                                >
                                    @if ($link['active'])
                                        @svg($link['icon'], 'mr-3 flex-shrink-0 size-6 text-white ')
                                    @else
                                        @svg($link['icon'], 'mr-3 size-6 flex-shrink-0 text-gray-400 group-hover:text-gray-500')
                                    @endif

                                    {{ $link['label'] }}
                                </a>
                            @endif
                        @endforeach
                    </div>

                    <div class="mt-6 space-y-1 pt-6">
                        @foreach ($secondaryMenu as $link)
                            <a
                                href="{{ $link['url'] }}"
                                wire:navigate
                                @class([
                                    'group flex items-center rounded-md px-2 py-2 text-sm font-semibold tracking-wide',
                                    'text-gray-600 hover:bg-gray-100 hover:text-gray-900' => ! $link['active'],
                                    'bg-gray-200 font-bold text-navy-900' => $link['active'],
                                ])
                            >
                                @if ($link['active'])
                                    @svg($link['icon'], 'mr-3 size-6 flex-shrink-0 text-navy-900')
                                @else
                                    @svg($link['icon'], 'mr-3 size-6 flex-shrink-0 text-gray-400 group-hover:text-gray-500')
                                @endif

                                {{ $link['label'] }}
                            </a>
                        @endforeach
                    </div>
                </nav>
            </div>
        </div>

        <div class="w-14 flex-shrink-0" aria-hidden="true">
            <!-- Dummy element to force sidebar to shrink to fit close icon -->
        </div>
    </div>
</div>
