<x-layouts.app>
    <div x-data="{ yearly: false }">
        <x-ui.header
            heading="Choose a plan"
            description="Choose a plan that works best for you."
        >
            <div class="flex items-center justify-end">
                <label
                    class="min-w-[3.5rem] text-base font-medium text-gray-700 dark:text-gray-400"
                >
                    Monthly
                </label>

                <input
                    type="checkbox"
                    class="relative mx-4 h-7 w-[3.25rem] cursor-pointer rounded-full border-transparent bg-gray-100 p-px text-transparent transition-colors duration-200 ease-in-out before:inline-block before:h-6 before:w-6 before:translate-x-0 before:transform before:rounded-full before:bg-white before:shadow before:ring-0 before:transition before:duration-200 before:ease-in-out checked:border-primary-500 checked:bg-none checked:text-primary-500 checked:before:translate-x-full checked:before:bg-white focus:ring-primary-500 focus:checked:border-primary-500 disabled:pointer-events-none disabled:opacity-50"
                    x-model="yearly"
                />

                <label
                    class="relative min-w-[3.5rem] text-base font-medium text-gray-700 dark:text-gray-400"
                >
                    Annual
                </label>
            </div>
        </x-ui.header>

        <!-- Pricing -->
        <section
            class="my-12 space-y-20 lg:grid lg:grid-cols-3 lg:gap-x-8 lg:space-y-0"
        >
            @foreach (config('services.lemonsqueeze.plans') as $key => $plan)
                <div
                    class="relative flex flex-col rounded-2xl border border-light-200 bg-white p-8 shadow-sm"
                >
                    <div class="flex-1">
                        @if ($plan['badge'] ?? false)
                            <span
                                class="absolute top-0 -translate-y-1/2 translate-x-1/2 transform rounded-full bg-primary-700 px-4 py-1.5 text-sm font-semibold text-white"
                            >
                                {{ $plan['badge'] }}
                            </span>
                        @endif

                        <h3 class="text-xl font-semibold text-light-900">
                            {{ $plan['title'] }}
                        </h3>

                        <p
                            class="mt-4 flex items-baseline text-light-900"
                            x-show="!yearly"
                        >
                            <span class="text-5xl font-bold tracking-tight">
                                <span>€ {{ $plan['price']['monthly'] }}</span>
                            </span>
                            <span class="ml-1 text-xl font-semibold">
                                /month
                            </span>
                        </p>
                        <p
                            class="mt-4 flex items-baseline text-light-900"
                            x-show="yearly"
                            x-cloak
                        >
                            <span class="text-5xl font-bold tracking-tight">
                                <span>€ {{ $plan['price']['yearly'] }}</span>
                            </span>
                            <span class="ml-1 text-xl font-semibold">
                                /year
                            </span>
                        </p>

                        <!-- Feature list -->
                        <ul role="list" class="mt-6 space-y-2">
                            @foreach ($plan['features'] as $feature => $check)
                                <li class="flex">
                                    @if ($check)
                                        <x-heroicon-m-check
                                            class="size-6 flex-shrink-0 text-primary-500"
                                        />
                                    @else
                                        <x-heroicon-m-x-mark
                                            class="size-6 flex-shrink-0 text-gray-500"
                                        />
                                    @endif
                                    <span class="ml-3 text-light-500">
                                        {{ $feature }}
                                    </span>
                                </li>
                            @endforeach
                        </ul>
                    </div>

                    <a
                        x-show="!yearly"
                        href="{{ route('billing.checkout', ['variant' => $plan['monthly_variant_id']]) }}"
                        class="mt-8 block w-full rounded-md border border-transparent bg-primary-700 px-6 py-3 text-center font-medium text-white hover:bg-primary-600"
                    >
                        {{ $plan['monthly_checkout'] }}
                    </a>
                    <a
                        x-show="yearly"
                        x-cloak
                        href="{{ route('billing.checkout', ['variant' => $plan['yearly_variant_id']]) }}"
                        class="mt-8 block w-full rounded-md border border-transparent bg-primary-700 px-6 py-3 text-center font-medium text-white hover:bg-primary-600"
                    >
                        {{ $plan['yearly_checkout'] }}
                    </a>
                </div>
            @endforeach
        </section>

        <x-billing.faq />
    </div>
</x-layouts.app>
