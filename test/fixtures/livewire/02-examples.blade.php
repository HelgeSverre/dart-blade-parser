<div class="mx-auto mt-12 grid max-w-screen-xl grid-cols-3 gap-6">
    <div class="col-span-full">
        <h1
            class="mx-auto mb-12 max-w-4xl text-center text-4xl font-bold tracking-tight md:text-5xl xl:text-6xl"
        >
            See Chatflow in action.
        </h1>
    </div>

    @php
        $categories = [
            'Documentation' => [
                'livewire.com',
                'laravel.com',
                'filamentphp.com',
                'alpinejs.dev',
                'docker.com',
            ],

            'E-commerce' => [
                'ties.com',
                'vincerocollective.com',
                'tiege.com',
            ],

            'Local Business' => [
                'fanablikk.no',
                'brudevold.no',
                'rentokil.com',
            ],
        ];
    @endphp

    @foreach ($categories as $category => $sites)
        <div>
            <div class="p-3 leading-relaxed">
                <strong class="text-sm uppercase text-light-500">
                    {{ $category }}
                </strong>
            </div>
            <div class="rounded-lg border border-light-200 bg-white/50 p-6">
                <div class="flex max-w-lg flex-row flex-wrap gap-2">
                    @foreach ($sites as $site)
                        <button
                            wire:click="makePreview('{{ $site }}')"
                            class="inline-flex items-center gap-x-1.5 rounded bg-primary-100 px-3 py-1.5 text-base font-semibold text-primary-700 hover:bg-primary-50"
                        >
                            {{ $site }}
                        </button>
                    @endforeach
                </div>
            </div>
        </div>
    @endforeach
</div>
