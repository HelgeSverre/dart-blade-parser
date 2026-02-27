@props([
    'title' => '',
    'actions' => [
        // example:
        // [
        //     'label' => 'Edit',
        //     'mountAction' => 'createItemAction',
        //     'visible' => true,
        // ],
        // [
        //     'label' => 'Delete',
        //     'action' => 'delete',
        //     'visible' => true,
        //     'confirm' => 'Are you sure?',
        // ],
    ],
])
<div class="relative text-left" x-data="dropdown">
    <div>
        <button
            x-bind="trigger"
            type="button"
            class="-my-2 flex items-center rounded-md p-2 text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-navy-500"
            title="{{ $title }}"
        >
            @svg('heroicon-s-ellipsis-vertical', 'size-5')
        </button>
    </div>

    <div
        x-bind="dialog"
        x-cloak
        class="absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        role="menu"
    >
        <div class="py-1" role="none">
            @foreach ($actions as $action)
                @if ($action['visible'] ?? true)
                    <button
                        @if ($action['mountAction'] ?? false)
                            wire:click="mountAction('{{ $action['mountAction'] }}')"
                        @elseif ($action['action'] ?? false)
                            wire:click="{{ $action['action'] }}"
                        @endif
                        @if ($action['confirm'] ?? false)
                            wire:confirm="{{ $action['confirm'] }}"
                        @endif
                        type="button"
                        class="flex w-full justify-between px-4 py-2 text-left text-sm text-gray-700"
                        role="menuitem"
                    >
                        {{ $action['label'] }}
                    </button>
                @endif
            @endforeach
        </div>
    </div>
</div>
