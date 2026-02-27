{{-- Livewire wire:sort drag-and-drop sorting examples --}}
<div>
    {{-- Basic sortable list --}}
    <ul wire:sort="updateTaskOrder">
        @foreach($tasks as $task)
            <li wire:key="task-{{ $task->id }}" wire:sort:item="{{ $task->id }}">
                {{ $task->title }}
            </li>
        @endforeach
    </ul>

    {{-- Sortable with handle --}}
    <div wire:sort="reorderItems">
        @foreach($items as $item)
            <div wire:key="item-{{ $item->id }}"
                 wire:sort:item="{{ $item->id }}"
                 class="flex items-center gap-2 p-2 border rounded">
                <span wire:sort:handle class="cursor-grab">
                    <svg class="w-4 h-4" viewBox="0 0 24 24">
                        <path d="M8 6h2v2H8zm6 0h2v2h-2zM8 11h2v2H8zm6 0h2v2h-2zm-6 5h2v2H8zm6 0h2v2h-2z"></path>
                    </svg>
                </span>
                <span>{{ $item->name }}</span>
            </div>
        @endforeach
    </div>

    {{-- Sortable groups (Kanban board) --}}
    <div class="flex gap-4">
        <div wire:sort="updateCardOrder" wire:sort:group="kanban">
            <h3>To Do</h3>
            @foreach($todoCards as $card)
                <div wire:key="card-{{ $card->id }}"
                     wire:sort:item="{{ $card->id }}"
                     wire:sort:group-id="todo"
                     class="p-3 bg-white rounded shadow">
                    <p>{{ $card->title }}</p>
                    <span>{{ $card->assignee }}</span>
                </div>
            @endforeach
        </div>

        <div wire:sort="updateCardOrder" wire:sort:group="kanban">
            <h3>In Progress</h3>
            @foreach($inProgressCards as $card)
                <div wire:key="card-{{ $card->id }}"
                     wire:sort:item="{{ $card->id }}"
                     wire:sort:group-id="in-progress"
                     class="p-3 bg-white rounded shadow">
                    <p>{{ $card->title }}</p>
                    <span>{{ $card->assignee }}</span>
                </div>
            @endforeach
        </div>

        <div wire:sort="updateCardOrder" wire:sort:group="kanban">
            <h3>Done</h3>
            @foreach($doneCards as $card)
                <div wire:key="card-{{ $card->id }}"
                     wire:sort:item="{{ $card->id }}"
                     wire:sort:group-id="done"
                     class="p-3 bg-white rounded shadow">
                    <p>{{ $card->title }}</p>
                    <span>{{ $card->assignee }}</span>
                </div>
            @endforeach
        </div>
    </div>

    {{-- Sortable with ignored elements --}}
    <div wire:sort="reorderSections">
        @foreach($sections as $section)
            <div wire:key="section-{{ $section->id }}"
                 wire:sort:item="{{ $section->id }}"
                 class="p-4 border rounded">
                <div wire:sort:handle class="cursor-grab font-bold">
                    {{ $section->title }}
                </div>
                <div wire:sort:ignore>
                    {{-- Content inside here won't trigger drag --}}
                    <textarea wire:model="section.{{ $section->id }}.content">
                        {{ $section->content }}
                    </textarea>
                    <button wire:click="deleteSection({{ $section->id }})">Delete</button>
                </div>
            </div>
        @endforeach
    </div>
</div>