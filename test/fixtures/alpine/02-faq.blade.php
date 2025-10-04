@php
    $faqs = \App\Models\Faq::published()
        ->billingRelated()
        ->get();
@endphp

@if ($faqs->isNotEmpty())
    <section class="my-12 rounded-2xl bg-light-50 p-8 lg:p-12">
        <h3
            class="text-2xl font-bold text-gray-800 md:text-3xl md:leading-tight"
        >
            Billing FAQ
        </h3>

        <div class="mt-6 divide-y divide-light-200">
            <section>
                <div class="divide-y divide-gray-200">
                    @foreach ($faqs as $faq)
                        <article
                            class="py-3 pt-6 first:pt-0 last:pb-0"
                            x-data="{ open: false }"
                        >
                            <button
                                @click="open = !open"
                                class="group inline-flex w-full items-center justify-between gap-x-3 rounded-lg pb-3 text-start font-semibold text-gray-800 transition hover:text-gray-500 md:text-lg"
                                aria-controls=""
                            >
                                {{ $faq->question }}

                                <x-lucide-chevron-down
                                    class="block size-5 flex-shrink-0 text-gray-600 transition duration-200 group-hover:text-gray-500"
                                    x-bind:class="{
                                        'transform -rotate-180': open,
                                    }"
                                />
                            </button>
                            <div
                                x-show="open"
                                x-cloak
                                x-collapse
                                class="w-full overflow-hidden transition-[height] duration-300"
                            >
                                <div
                                    class="prose prose-blue mb-6 mt-3 text-gray-600"
                                >
                                    {!! $faq->answer !!}
                                </div>
                            </div>
                        </article>
                    @endforeach
                </div>
            </section>
        </div>
    </section>
@endif
