{{-- Advanced component patterns --}}

{{-- Self-closing component with many attribute types --}}
<x-icon
    name="heroicon-o-bell"
    :size="$iconSize"
    class="text-gray-500"
    @class(['animate-bounce' => $hasNotifications])
/>

{{-- Component with multiple named slots --}}
<x-modal>
    <x-slot:trigger>
        <button type="button">Open Modal</button>
    </x-slot>

    <x-slot:title>
        {{ $modalTitle }}
    </x-slot>

    <x-slot:body>
        @if($hasForm)
            <form wire:submit="submitModal">
                @csrf
                <x-input
                    label="Name"
                    wire:model="name"
                    @required(true)
                    @class(['border-red-500' => $errors->has('name')])
                />
                <x-input label="Email" wire:model="email" type="email" />
            </form>
        @else
            <p>{{ $modalContent }}</p>
        @endif
    </x-slot>

    <x-slot:footer>
        <x-button variant="secondary" @click="$dispatch('close-modal')">
            Cancel
        </x-button>
        <x-button variant="primary" wire:click="confirm" @disabled($isProcessing)>
            Confirm
        </x-button>
    </x-slot>
</x-modal>

{{-- Nested components --}}
<x-layout.app>
    <x-layout.sidebar>
        @foreach($menuItems as $item)
            <x-nav-link
                :href="$item->url"
                :active="request()->is($item->pattern)"
                wire:navigate
            >
                <x-icon :name="$item->icon" class="w-5 h-5" />
                {{ $item->label }}
            </x-nav-link>
        @endforeach
    </x-layout.sidebar>

    <x-layout.main>
        {{ $slot }}
    </x-layout.main>
</x-layout.app>

{{-- Dynamic component --}}
@foreach($widgets as $widget)
    <x-dynamic-component
        :component="$widget->component"
        :data="$widget->data"
        wire:key="widget-{{ $widget->id }}"
        @class(['col-span-2' => $widget->isWide()])
    />
@endforeach

{{-- Component with conditional rendering and complex attributes --}}
<x-data-table
    :columns="$columns"
    :rows="$rows"
    :sortable="true"
    :searchable="true"
    wire:model.live="search"
    @if($paginated)
        :per-page="$perPage"
    @endif
>
    <x-slot:empty>
        <div class="text-center py-8">
            <x-icon name="heroicon-o-inbox" class="mx-auto h-12 w-12 text-gray-400" />
            <p class="mt-2 text-gray-500">{{ __('No records found.') }}</p>
        </div>
    </x-slot>
</x-data-table>
