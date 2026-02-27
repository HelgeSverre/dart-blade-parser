{{--
---
features:
  - livewire_v4_sfc
  - validate_attribute
  - computed_attribute
  - locked_attribute
  - renderless_attribute
  - wire_submit
  - wire_click
  - wire_model_live
  - wire_model_blur
  - wire_confirm
  - wire_navigate
  - wire_key
  - wire_loading
  - wire_loading_attr
  - wire_loading_class
  - wire_loading_remove
  - wire_target
  - wire_dirty_class
  - wire_poll
  - wire_sort
  - entangle
  - teleport
  - persist
  - blade_error
  - alpine_integration
  - dollar_wire
  - data_loading
description: Complex Livewire v4 SFC task manager combining many v4 features including computed properties, Alpine.js integration, modals, sorting, polling, and loading states
complexity: complex
--}}
<?php

use Livewire\Attributes\Computed;
use Livewire\Attributes\Locked;
use Livewire\Attributes\Validate;
use Livewire\Component;
use App\Models\Task;
use App\Models\Project;

new class extends Component {
    #[Locked]
    public int $projectId;

    #[Validate('required|max:255')]
    public string $newTaskTitle = '';

    #[Validate('nullable|max:1000')]
    public string $newTaskDescription = '';

    public string $filter = 'all';
    public string $search = '';
    public bool $showCompleted = false;
    public ?int $editingTaskId = null;
    public string $editTitle = '';
    public string $editDescription = '';

    public function mount(Project $project)
    {
        $this->projectId = $project->id;
    }

    #[Computed]
    public function project()
    {
        return Project::find($this->projectId);
    }

    #[Computed]
    public function tasks()
    {
        $query = Task::where('project_id', $this->projectId)
            ->when($this->search, fn ($q) => $q->where('title', 'like', '%' . $this->search . '%'))
            ->when($this->filter === 'pending', fn ($q) => $q->where('completed', false))
            ->when($this->filter === 'completed', fn ($q) => $q->where('completed', true))
            ->when(!$this->showCompleted && $this->filter === 'all', fn ($q) => $q->where('completed', false));

        return $query->orderBy('sort_order')->get();
    }

    #[Computed]
    public function completedCount()
    {
        return Task::where('project_id', $this->projectId)->where('completed', true)->count();
    }

    #[Computed]
    public function totalCount()
    {
        return Task::where('project_id', $this->projectId)->count();
    }

    public function addTask()
    {
        $this->validate();

        Task::create([
            'project_id' => $this->projectId,
            'title' => $this->newTaskTitle,
            'description' => $this->newTaskDescription,
            'sort_order' => $this->totalCount + 1,
        ]);

        $this->reset('newTaskTitle', 'newTaskDescription');
    }

    public function toggleComplete(int $taskId)
    {
        $task = Task::findOrFail($taskId);
        $task->update(['completed' => !$task->completed]);
    }

    public function startEditing(int $taskId)
    {
        $task = Task::findOrFail($taskId);
        $this->editingTaskId = $taskId;
        $this->editTitle = $task->title;
        $this->editDescription = $task->description ?? '';
    }

    public function saveEdit()
    {
        $this->validate([
            'editTitle' => 'required|max:255',
            'editDescription' => 'nullable|max:1000',
        ]);

        Task::findOrFail($this->editingTaskId)->update([
            'title' => $this->editTitle,
            'description' => $this->editDescription,
        ]);

        $this->cancelEdit();
    }

    public function cancelEdit()
    {
        $this->reset('editingTaskId', 'editTitle', 'editDescription');
    }

    public function deleteTask(int $taskId)
    {
        Task::findOrFail($taskId)->delete();
    }

    public function updateTaskOrder(array $items)
    {
        foreach ($items as $item) {
            Task::where('id', $item['value'])->update(['sort_order' => $item['order']]);
        }
    }
}; ?>

<div wire:poll.5s>
    {{-- Header --}}
    <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">
            <a href="/projects" wire:navigate>&larr;</a>
            {{ $this->project->name }}
        </h1>
        <span class="text-sm text-gray-500">
            {{ $this->completedCount }} / {{ $this->totalCount }} completed
        </span>
    </div>

    {{-- Search and Filters --}}
    <div class="mt-4 flex gap-4">
        <input
            type="text"
            wire:model.live.debounce.300ms="search"
            placeholder="Search tasks..."
            class="flex-1 rounded border px-3 py-2"
        >
        <select wire:model.live="filter" class="rounded border px-3 py-2">
            <option value="all">All</option>
            <option value="pending">Pending</option>
            <option value="completed">Completed</option>
        </select>
        <label class="flex items-center gap-2">
            <input type="checkbox" wire:model.live="showCompleted">
            Show completed
        </label>
    </div>

    {{-- Add Task Form --}}
    <form wire:submit="addTask" class="mt-6 rounded-lg border bg-gray-50 p-4"
        x-data="{ expanded: false }"
    >
        <div class="flex gap-2">
            <input
                type="text"
                wire:model="newTaskTitle"
                wire:dirty.class="border-yellow-400"
                placeholder="Add a new task..."
                class="flex-1 rounded border px-3 py-2"
                @focus="expanded = true"
            >
            <button
                type="submit"
                class="rounded bg-blue-600 px-4 py-2 text-white data-loading:opacity-50"
                wire:loading.attr="disabled"
                wire:target="addTask"
            >
                <span wire:loading.remove wire:target="addTask">Add</span>
                <span wire:loading wire:target="addTask">Adding...</span>
            </button>
        </div>
        @error('newTaskTitle')
            <span class="mt-1 text-sm text-red-500">{{ $message }}</span>
        @enderror

        <div x-show="expanded" x-transition>
            <textarea
                wire:model="newTaskDescription"
                placeholder="Description (optional)"
                rows="3"
                class="mt-2 w-full rounded border px-3 py-2"
            ></textarea>
            @error('newTaskDescription')
                <span class="mt-1 text-sm text-red-500">{{ $message }}</span>
            @enderror
        </div>
    </form>

    {{-- Task List --}}
    <div class="mt-6 space-y-2" wire:sortable="updateTaskOrder" wire:sortable.handle>
        @forelse ($this->tasks as $task)
            <div
                wire:key="task-{{ $task->id }}"
                wire:sortable.item="{{ $task->id }}"
                class="flex items-center gap-3 rounded-lg border bg-white p-3 shadow-sm"
                x-data="{ showActions: false }"
                @mouseenter="showActions = true"
                @mouseleave="showActions = false"
            >
                <div wire:sortable.handle class="cursor-grab text-gray-400">::</div>

                <input
                    type="checkbox"
                    wire:click="toggleComplete({{ $task->id }})"
                    @checked($task->completed)
                    class="h-5 w-5"
                >

                @if ($editingTaskId === $task->id)
                    <div class="flex-1">
                        <input
                            type="text"
                            wire:model.blur="editTitle"
                            class="w-full rounded border px-2 py-1"
                            wire:keydown.enter="saveEdit"
                            wire:keydown.escape="cancelEdit"
                        >
                        <textarea
                            wire:model.blur="editDescription"
                            rows="2"
                            class="mt-1 w-full rounded border px-2 py-1"
                        ></textarea>
                        <div class="mt-1 flex gap-2">
                            <button wire:click="saveEdit" class="text-sm text-blue-600">Save</button>
                            <button wire:click="cancelEdit" class="text-sm text-gray-500">Cancel</button>
                        </div>
                    </div>
                @else
                    <div class="flex-1">
                        <span class="{{ $task->completed ? 'line-through text-gray-400' : '' }}">
                            {{ $task->title }}
                        </span>
                        @if ($task->description)
                            <p class="mt-1 text-sm text-gray-500">{{ $task->description }}</p>
                        @endif
                    </div>
                @endif

                <div x-show="showActions" x-transition class="flex gap-2">
                    <button
                        wire:click="startEditing({{ $task->id }})"
                        class="text-sm text-blue-600 hover:underline"
                    >
                        Edit
                    </button>
                    <button
                        wire:click="deleteTask({{ $task->id }})"
                        wire:confirm="Are you sure you want to delete this task?"
                        wire:loading.class="opacity-50"
                        wire:target="deleteTask({{ $task->id }})"
                        class="text-sm text-red-600 hover:underline"
                    >
                        Delete
                    </button>
                </div>
            </div>
        @empty
            <div class="rounded-lg border border-dashed p-8 text-center text-gray-400">
                No tasks found. Add one above!
            </div>
        @endforelse
    </div>

    {{-- Background Music Player --}}
    @persist('task-audio')
        <audio src="/sounds/focus-music.mp3" controls class="mt-6 w-full"></audio>
    @endpersist

    {{-- Delete Confirmation Modal --}}
    @teleport('body')
        <div
            x-data="{ open: $wire.entangle('showDeleteModal').live }"
            x-show="open"
            x-transition
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
            @keydown.escape.window="open = false"
        >
            <div class="rounded-lg bg-white p-6 shadow-xl" @click.away="open = false">
                <h2 class="text-lg font-bold">Confirm Delete</h2>
                <p class="mt-2 text-gray-600">This action cannot be undone.</p>
                <div class="mt-4 flex justify-end gap-3">
                    <button @click="open = false" class="rounded border px-4 py-2">Cancel</button>
                    <button
                        wire:click="confirmDelete"
                        wire:loading.attr="disabled"
                        class="rounded bg-red-600 px-4 py-2 text-white data-loading:opacity-50"
                    >
                        Delete
                    </button>
                </div>
            </div>
        </div>
    @endteleport
</div>
