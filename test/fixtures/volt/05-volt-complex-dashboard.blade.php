{{--
---
features:
  - volt
  - state
  - computed
  - on
  - wire_poll
  - wire_navigate
  - teleport
  - entangle
  - wire_sort
  - wire_confirm
  - error_directive
  - loading_states
description: Complex Volt dashboard with real-time updates, modals, sortable lists, and Alpine integration
complexity: complex
line_count: ~95
--}}
<?php

use function Livewire\Volt\{state, computed, on, mount};
use App\Models\{Task, Notification};

state([
    'search' => '',
    'filter' => 'all',
    'showModal' => false,
    'editingTask' => null,
    'newTaskTitle' => '',
    'newTaskPriority' => 'medium',
]);

mount(function () {
    $this->editingTask = null;
});

$tasks = computed(function () {
    return Task::query()
        ->when($this->search, fn ($q) => $q->where('title', 'like', "%{$this->search}%"))
        ->when($this->filter !== 'all', fn ($q) => $q->where('status', $this->filter))
        ->orderBy('position')
        ->get();
});

$stats = computed(fn () => [
    'total' => Task::count(),
    'completed' => Task::where('status', 'completed')->count(),
    'pending' => Task::where('status', 'pending')->count(),
]);

$notifications = computed(fn () => Notification::latest()->take(5)->get());

on(['task-created' => function () {
    unset($this->tasks, $this->stats);
}]);

$createTask = function () {
    $this->validate([
        'newTaskTitle' => 'required|min:3',
        'newTaskPriority' => 'required|in:low,medium,high',
    ]);

    Task::create([
        'title' => $this->newTaskTitle,
        'priority' => $this->newTaskPriority,
        'position' => Task::max('position') + 1,
    ]);

    $this->newTaskTitle = '';
    $this->showModal = false;
    $this->dispatch('task-created');
};

$reorder = function (array $items) {
    foreach ($items as $item) {
        Task::where('id', $item['value'])->update(['position' => $item['order']]);
    }
};

$toggleComplete = function (int $id) {
    $task = Task::findOrFail($id);
    $task->update(['status' => $task->status === 'completed' ? 'pending' : 'completed']);
};

$deleteTask = function (int $id) {
    Task::findOrFail($id)->delete();
};

?>

<div x-data="{ sidebarOpen: $wire.entangle('showModal') }" wire:poll.10s>
    <header class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Task Dashboard</h1>
        <div class="flex items-center gap-3">
            <input type="text" wire:model.live.debounce.300ms="search" placeholder="Search tasks...">
            <select wire:model.live="filter">
                <option value="all">All</option>
                <option value="pending">Pending</option>
                <option value="completed">Completed</option>
            </select>
            <button wire:click="$set('showModal', true)" class="btn-primary">New Task</button>
        </div>
    </header>

    <div class="grid grid-cols-3 gap-4 mb-6">
        @foreach (['total' => 'Total', 'completed' => 'Done', 'pending' => 'Pending'] as $key => $label)
            <div class="bg-white rounded-lg p-4 shadow">
                <span class="text-sm text-gray-500">{{ $label }}</span>
                <p class="text-2xl font-bold">{{ $this->stats[$key] }}</p>
            </div>
        @endforeach
    </div>

    <ul wire:sortable="reorder" class="space-y-2">
        @foreach ($this->tasks as $task)
            <li wire:sortable.item="{{ $task->id }}" wire:key="task-{{ $task->id }}" class="flex items-center gap-3 bg-white p-3 rounded shadow">
                <span wire:sortable.handle class="cursor-grab">::</span>
                <button wire:click="toggleComplete({{ $task->id }})">
                    @if ($task->status === 'completed')
                        <span class="text-green-500">&#10003;</span>
                    @else
                        <span class="text-gray-300">&#9675;</span>
                    @endif
                </button>
                <a href="/tasks/{{ $task->id }}" wire:navigate class="flex-1 {{ $task->status === 'completed' ? 'line-through text-gray-400' : '' }}">
                    {{ $task->title }}
                </a>
                <span class="text-xs px-2 py-1 rounded bg-{{ $task->priority }}-100">{{ $task->priority }}</span>
                <button
                    wire:click="deleteTask({{ $task->id }})"
                    wire:confirm="Delete '{{ $task->title }}'?"
                    class="text-red-500 data-loading:opacity-50"
                >
                    &times;
                </button>
            </li>
        @endforeach
    </ul>

    @teleport('body')
        <div x-show="sidebarOpen" x-cloak class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <form wire:submit="createTask" class="bg-white rounded-lg p-6 w-96 shadow-xl" @click.outside="sidebarOpen = false">
                <h2 class="text-lg font-semibold mb-4">New Task</h2>
                <div class="mb-3">
                    <input type="text" wire:model="newTaskTitle" placeholder="Task title" class="w-full border rounded p-2">
                    @error('newTaskTitle')
                        <span class="text-red-500 text-sm">{{ $message }}</span>
                    @enderror
                </div>
                <div class="mb-4">
                    <select wire:model="newTaskPriority" class="w-full border rounded p-2">
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                    </select>
                </div>
                <div class="flex justify-end gap-2">
                    <button type="button" @click="sidebarOpen = false" class="btn-secondary">Cancel</button>
                    <button type="submit" class="btn-primary data-loading:opacity-50">Create</button>
                </div>
            </form>
        </div>
    @endteleport
</div>
