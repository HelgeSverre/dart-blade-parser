<x-layouts.base>
    <x-slot:title>
        @if (isset($checklist) && $checklist->exists)
            Rediger Sjekkliste {{ $checklist->title }}
        @else
                Opprett Sjekkliste
        @endif
    </x-slot>

    <x-layouts.page>
        <x-slot:actions>
            <x-layouts.breadcrumb-links
                :links="
                    isset($checklist) && $checklist->exists ? [
                        ['label' => 'Sjekklister', 'url' => route('checklist.index')],
                        ['label' => $checklist->title, 'url' => route('checklist.edit', $checklist)],
                    ] : [
                        ['label' => 'Sjekklister', 'url' => route('checklist.index')],
                        ['label' => 'Opprett sjekkliste', 'url' => route('checklist.create')],
                    ]
                "
            />
        </x-slot>

        <div class="mb-4">
            <livewire:checklists.form :checklist="$checklist?->id ?? null" />
        </div>
    </x-layouts.page>
</x-layouts.base>
