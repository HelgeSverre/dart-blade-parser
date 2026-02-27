{{-- Project Management Kanban Board - comprehensive stress fixture --}}
@extends('layouts.app')

@section('title', $project->name . ' - Board')

@push('styles')
    <style>
        .kanban-column { min-height: 60vh; }
        .task-card { transition: box-shadow 0.15s ease; }
        .task-card:hover { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        [x-cloak] { display: none !important; }
    </style>
@endpush

@php
    $columns = [
        ['id' => 'todo', 'label' => 'To Do', 'color' => 'gray'],
        ['id' => 'in_progress', 'label' => 'In Progress', 'color' => 'blue'],
        ['id' => 'review', 'label' => 'Review', 'color' => 'yellow'],
        ['id' => 'done', 'label' => 'Done', 'color' => 'green'],
    ];
    $priorityConfig = [
        'critical' => ['label' => 'Critical', 'color' => 'red', 'icon' => 'fire'],
        'high' => ['label' => 'High', 'color' => 'orange', 'icon' => 'arrow-up'],
        'medium' => ['label' => 'Medium', 'color' => 'yellow', 'icon' => 'minus'],
        'low' => ['label' => 'Low', 'color' => 'blue', 'icon' => 'arrow-down'],
    ];
@endphp

@section('content')
    <div
        x-data="{
            showNewTaskModal: false,
            showTaskDetail: false,
            activeTask: null,
            showSprintSelector: false,
            showFilters: false,
            filterAssignee: 'all',
            filterPriority: 'all',
            filterLabel: 'all',
            searchQuery: '',
            showKeyboardHelp: false,
            draggedTask: null,
        }"
        @keydown.n.prevent="showNewTaskModal = true"
        @keydown.slash.prevent="$refs.boardSearch.focus()"
        @keydown.question.prevent="showKeyboardHelp = !showKeyboardHelp"
        @keydown.escape="showNewTaskModal = false; showTaskDetail = false; showKeyboardHelp = false"
        class="flex h-screen flex-col overflow-hidden bg-gray-100"
    >
        {{-- Board Header --}}
        <header class="flex-shrink-0 border-b border-gray-200 bg-white px-6 py-3">
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-4">
                    <nav class="flex items-center text-sm text-gray-500">
                        <a href="{{ route('projects.index') }}" wire:navigate class="hover:text-gray-700">Projects</a>
                        <x-icon name="chevron-right" class="mx-2 size-3" />
                        <span class="font-medium text-gray-900">{{ $project->name }}</span>
                    </nav>

                    {{-- Sprint Selector --}}
                    <div class="relative" x-data="{ open: false }">
                        <button
                            @click="open = !open"
                            class="flex items-center gap-1 rounded-md border border-gray-300 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50"
                        >
                            <x-icon name="clock" class="size-4" />
                            @isset($currentSprint)
                                Sprint {{ $currentSprint->number }}
                                <span class="text-xs text-gray-400">({{ $currentSprint->end_date->diffForHumans() }})</span>
                            @else
                                No Sprint
                            @endisset
                            <x-icon name="chevron-down" class="size-3" />
                        </button>

                        <div
                            x-show="open"
                            @click.away="open = false"
                            x-transition
                            class="absolute left-0 z-30 mt-1 w-64 rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5"
                        >
                            @forelse($sprints as $sprint)
                                <button
                                    wire:click="selectSprint({{ $sprint->id }})"
                                    wire:key="sprint-{{ $sprint->id }}"
                                    @click="open = false"
                                    @class([
                                        'flex w-full items-center justify-between px-4 py-2 text-left text-sm hover:bg-gray-50',
                                        'bg-blue-50 text-blue-700' => $currentSprint?->id === $sprint->id,
                                        'text-gray-700' => $currentSprint?->id !== $sprint->id,
                                    ])
                                >
                                    <span>Sprint {{ $sprint->number }}</span>
                                    <span class="text-xs text-gray-400">
                                        {{ $sprint->start_date->format('M d') }} - {{ $sprint->end_date->format('M d') }}
                                    </span>
                                </button>
                            @empty
                                <p class="px-4 py-3 text-sm italic text-gray-400">No sprints created</p>
                            @endforelse
                        </div>
                    </div>
                </div>

                <div class="flex items-center gap-3">
                    {{-- Search --}}
                    <div class="relative">
                        <x-icon name="magnifying-glass" class="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-gray-400" />
                        <input
                            type="search"
                            x-ref="boardSearch"
                            x-model="searchQuery"
                            wire:model.live.debounce.300ms="search"
                            placeholder="Search tasks... (/)"
                            class="w-48 rounded-md border-gray-300 py-1.5 pl-8 pr-3 text-sm focus:w-64 focus:border-blue-500 focus:ring-blue-500"
                        >
                    </div>

                    {{-- Filter Button --}}
                    <button
                        @click="showFilters = !showFilters"
                        @class([
                            'flex items-center gap-1 rounded-md border px-3 py-1.5 text-sm',
                            'border-blue-500 bg-blue-50 text-blue-700' => $activeFilterCount > 0,
                            'border-gray-300 text-gray-700 hover:bg-gray-50' => $activeFilterCount === 0,
                        ])
                    >
                        <x-icon name="funnel" class="size-4" />
                        @if($activeFilterCount > 0)
                            <span>{{ $activeFilterCount }}</span>
                        @endif
                    </button>

                    {{-- Team Avatars --}}
                    <div class="flex -space-x-2">
                        @for($i = 0; $i < min(5, count($projectMembers)); $i++)
                            <img
                                src="{{ $projectMembers[$i]->avatar }}"
                                alt="{{ $projectMembers[$i]->name }}"
                                title="{{ $projectMembers[$i]->name }}"
                                class="size-8 rounded-full border-2 border-white object-cover"
                            >
                        @endfor
                        @if(count($projectMembers) > 5)
                            <div class="flex size-8 items-center justify-center rounded-full border-2 border-white bg-gray-200 text-xs font-medium text-gray-600">
                                +{{ count($projectMembers) - 5 }}
                            </div>
                        @endif
                    </div>

                    @can('create', [App\Models\Task::class, $project])
                        <x-button
                            variant="primary"
                            size="sm"
                            @click="showNewTaskModal = true"
                        >
                            <x-icon name="plus" class="mr-1 size-4" />
                            New Task
                        </x-button>
                    @endcan
                </div>
            </div>

            {{-- Filters Panel --}}
            <div x-show="showFilters" x-transition x-cloak class="mt-3 flex items-center gap-4 border-t border-gray-100 pt-3">
                <select
                    x-model="filterAssignee"
                    wire:model.live="filterAssignee"
                    class="rounded-md border-gray-300 text-sm"
                >
                    <option value="all">All Assignees</option>
                    @foreach($projectMembers as $member)
                        <option value="{{ $member->id }}">{{ $member->name }}</option>
                    @endforeach
                </select>

                <select
                    x-model="filterPriority"
                    wire:model.live="filterPriority"
                    class="rounded-md border-gray-300 text-sm"
                >
                    <option value="all">All Priorities</option>
                    @foreach($priorityConfig as $key => $config)
                        <option value="{{ $key }}">{{ $config['label'] }}</option>
                    @endforeach
                </select>

                <select
                    x-model="filterLabel"
                    wire:model.live="filterLabel"
                    class="rounded-md border-gray-300 text-sm"
                >
                    <option value="all">All Labels</option>
                    @each('projects.partials.label-option', $project->labels, 'label')
                </select>

                <button wire:click="clearFilters" class="text-xs text-blue-600 hover:text-blue-800">Clear</button>
            </div>
        </header>

        {{-- Kanban Board --}}
        <main class="flex flex-1 gap-4 overflow-x-auto p-4" wire:poll.30s>
            @foreach($columns as $column)
                <div
                    wire:key="column-{{ $column['id'] }}"
                    class="flex w-80 flex-shrink-0 flex-col rounded-lg bg-gray-200/50"
                    wire:sortable-group="{{ $column['id'] }}"
                >
                    {{-- Column Header --}}
                    <div class="flex items-center justify-between px-3 py-2">
                        <div class="flex items-center gap-2">
                            <span @class([
                                'inline-block size-3 rounded-full',
                                'bg-gray-400' => $column['color'] === 'gray',
                                'bg-blue-400' => $column['color'] === 'blue',
                                'bg-yellow-400' => $column['color'] === 'yellow',
                                'bg-green-400' => $column['color'] === 'green',
                            ])></span>
                            <h2 class="text-sm font-semibold text-gray-700">{{ $column['label'] }}</h2>
                            <span class="rounded-full bg-gray-200 px-2 py-0.5 text-xs text-gray-500">
                                {{ $tasksByColumn[$column['id']]->count() ?? 0 }}
                            </span>
                        </div>
                        @can('create', [App\Models\Task::class, $project])
                            <button
                                wire:click="quickAddTask('{{ $column['id'] }}')"
                                class="rounded p-1 text-gray-400 hover:bg-gray-200 hover:text-gray-600"
                                title="Add task"
                            >
                                <x-icon name="plus" class="size-4" />
                            </button>
                        @endcan
                    </div>

                    {{-- Task Cards --}}
                    <div class="kanban-column flex-1 space-y-2 overflow-y-auto px-2 pb-2">
                        @forelse($tasksByColumn[$column['id']] ?? [] as $task)
                            <div
                                wire:key="task-{{ $task->id }}"
                                wire:sortable.item="{{ $task->id }}"
                                wire:sortable.handle
                                @click="activeTask = {{ $task->id }}; showTaskDetail = true"
                                class="task-card cursor-pointer rounded-lg bg-white p-3 shadow-sm"
                            >
                                {{-- Labels --}}
                                @if($task->labels->isNotEmpty())
                                    <div class="mb-2 flex flex-wrap gap-1">
                                        @foreach($task->labels as $label)
                                            @if($loop->index > 2)
                                                <span class="text-xs text-gray-400">+{{ $task->labels->count() - 3 }}</span>
                                                @break
                                            @endif
                                            <span
                                                @style(["background-color: {$label->color}20; color: {$label->color}"])
                                                class="rounded-full px-2 py-0.5 text-xs font-medium"
                                            >
                                                {{ $label->name }}
                                            </span>
                                        @endforeach
                                    </div>
                                @endif

                                {{-- Task Title --}}
                                <p class="text-sm font-medium text-gray-900">{{ $task->title }}</p>

                                @isset($task->description)
                                    <p class="mt-1 line-clamp-2 text-xs text-gray-500">
                                        {{ Str::limit(strip_tags($task->description), 80) }}
                                    </p>
                                @endisset

                                {{-- Task Meta --}}
                                <div class="mt-3 flex items-center justify-between">
                                    <div class="flex items-center gap-2">
                                        {{-- Priority --}}
                                        @isset($priorityConfig[$task->priority])
                                            <x-icon
                                                :name="$priorityConfig[$task->priority]['icon']"
                                                @class([
                                                    'size-3.5',
                                                    'text-red-500' => $task->priority === 'critical',
                                                    'text-orange-500' => $task->priority === 'high',
                                                    'text-yellow-500' => $task->priority === 'medium',
                                                    'text-blue-400' => $task->priority === 'low',
                                                ])
                                                title="{{ $priorityConfig[$task->priority]['label'] }}"
                                            />
                                        @endisset

                                        {{-- Due Date --}}
                                        @unless($task->due_date === null)
                                            <span @class([
                                                'text-xs',
                                                'text-red-600 font-medium' => $task->is_overdue,
                                                'text-yellow-600' => $task->due_date->isToday(),
                                                'text-gray-400' => !$task->is_overdue && !$task->due_date->isToday(),
                                            ])>
                                                <x-icon name="calendar" class="mr-0.5 inline size-3" />
                                                {{ $task->due_date->format('M d') }}
                                            </span>
                                        @endunless

                                        {{-- Comments Count --}}
                                        @if($task->comments_count > 0)
                                            <span class="flex items-center gap-0.5 text-xs text-gray-400">
                                                <x-icon name="chat-bubble-left" class="size-3" />
                                                {{ $task->comments_count }}
                                            </span>
                                        @endif

                                        {{-- Attachments --}}
                                        @if($task->attachments_count > 0)
                                            <span class="flex items-center gap-0.5 text-xs text-gray-400">
                                                <x-icon name="paper-clip" class="size-3" />
                                                {{ $task->attachments_count }}
                                            </span>
                                        @endif
                                    </div>

                                    {{-- Assignee --}}
                                    @isset($task->assignee)
                                        <img
                                            src="{{ $task->assignee->avatar }}"
                                            alt="{{ $task->assignee->name }}"
                                            title="{{ $task->assignee->name }}"
                                            class="size-6 rounded-full border border-gray-200 object-cover"
                                        >
                                    @endisset
                                </div>

                                {{-- Subtask Progress --}}
                                @if($task->subtasks_count > 0)
                                    <div class="mt-2">
                                        <div class="flex items-center justify-between text-xs text-gray-400">
                                            <span>Subtasks</span>
                                            <span>{{ $task->completed_subtasks_count }}/{{ $task->subtasks_count }}</span>
                                        </div>
                                        <div class="mt-1 h-1 rounded-full bg-gray-200">
                                            <div
                                                @style(["width: " . ($task->subtasks_count > 0 ? round($task->completed_subtasks_count / $task->subtasks_count * 100) : 0) . "%"])
                                                class="h-1 rounded-full bg-blue-500"
                                            ></div>
                                        </div>
                                    </div>
                                @endif
                            </div>
                        @empty
                            <div class="flex items-center justify-center py-8">
                                <p class="text-xs italic text-gray-400">No tasks</p>
                            </div>
                        @endforelse
                    </div>
                </div>
            @endforeach
        </main>

        {{-- New Task Modal --}}
        <div x-show="showNewTaskModal" x-cloak class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-screen items-center justify-center px-4">
                <div class="fixed inset-0 bg-black/50" @click="showNewTaskModal = false"></div>

                <div
                    class="relative w-full max-w-lg rounded-xl bg-white shadow-2xl"
                    @click.stop
                    x-transition:enter="transition ease-out duration-200"
                    x-transition:enter-start="opacity-0 scale-95"
                    x-transition:enter-end="opacity-100 scale-100"
                >
                    <form wire:submit.prevent="createTask">
                        @csrf

                        <div class="border-b border-gray-200 px-6 py-4">
                            <h2 class="text-lg font-semibold text-gray-900">New Task</h2>
                        </div>

                        <div class="space-y-4 px-6 py-4">
                            <div>
                                <input
                                    type="text"
                                    wire:model="taskForm.title"
                                    placeholder="Task title"
                                    @required(true)
                                    class="w-full rounded-md border-gray-300 text-lg font-medium shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                    autofocus
                                >
                                @error('taskForm.title')
                                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                @enderror
                            </div>

                            <div>
                                <textarea
                                    wire:model="taskForm.description"
                                    placeholder="Add a description..."
                                    rows="3"
                                    class="w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                ></textarea>
                            </div>

                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-medium text-gray-700">Column</label>
                                    <select wire:model="taskForm.column" class="mt-1 w-full rounded-md border-gray-300 text-sm">
                                        @foreach($columns as $col)
                                            <option value="{{ $col['id'] }}" @selected($col['id'] === 'todo')>
                                                {{ $col['label'] }}
                                            </option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="block text-xs font-medium text-gray-700">Priority</label>
                                    <select wire:model="taskForm.priority" class="mt-1 w-full rounded-md border-gray-300 text-sm">
                                        @foreach($priorityConfig as $key => $config)
                                            <option value="{{ $key }}" @selected($key === 'medium')>
                                                {{ $config['label'] }}
                                            </option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>

                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-medium text-gray-700">Assignee</label>
                                    <select wire:model="taskForm.assignee_id" class="mt-1 w-full rounded-md border-gray-300 text-sm">
                                        <option value="">Unassigned</option>
                                        @foreach($projectMembers as $member)
                                            <option value="{{ $member->id }}">{{ $member->name }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="block text-xs font-medium text-gray-700">Due Date</label>
                                    <input
                                        type="date"
                                        wire:model="taskForm.due_date"
                                        min="{{ now()->format('Y-m-d') }}"
                                        class="mt-1 w-full rounded-md border-gray-300 text-sm"
                                    >
                                    @error('taskForm.due_date')
                                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                    @enderror
                                </div>
                            </div>
                        </div>

                        <div class="flex justify-end gap-3 border-t border-gray-200 px-6 py-4">
                            <x-button type="button" variant="outline" @click="showNewTaskModal = false">
                                Cancel
                            </x-button>
                            <x-button type="submit" variant="primary" wire:loading.attr="disabled">
                                <span wire:loading.remove wire:target="createTask">Create Task</span>
                                <span wire:loading wire:target="createTask">Creating...</span>
                            </x-button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        {{-- Keyboard Shortcuts Modal --}}
        <!-- HTML comment: accessibility helper -->
        <div x-show="showKeyboardHelp" x-cloak class="fixed inset-0 z-50 flex items-center justify-center">
            <div class="fixed inset-0 bg-black/30" @click="showKeyboardHelp = false"></div>
            <div class="relative w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl" @click.stop>
                <h3 class="mb-4 text-lg font-semibold text-gray-900">Keyboard Shortcuts</h3>
                <dl class="space-y-2">
                    @foreach([
                        'n' => 'New task',
                        '/' => 'Search',
                        '?' => 'Toggle this help',
                        'Esc' => 'Close modals',
                    ] as $key => $action)
                        <div class="flex items-center justify-between">
                            <dt class="text-sm text-gray-600">{{ $action }}</dt>
                            <dd>
                                <kbd class="rounded border border-gray-300 bg-gray-50 px-2 py-0.5 font-mono text-xs text-gray-700">{{ $key }}</kbd>
                            </dd>
                        </div>
                    @endforeach
                </dl>
            </div>
        </div>

        @once
            @push('scripts')
                <script>
                    document.addEventListener('livewire:initialized', () => {
                        Livewire.on('task-created', () => {
                            Alpine.store('toast').success('Task created');
                        });
                        Livewire.on('task-moved', (event) => {
                            Alpine.store('toast').info('Task moved to ' + event.column);
                        });
                    });
                </script>
            @endpush
        @endonce

        @env('local')
            <div class="fixed bottom-4 right-4 z-50 rounded bg-gray-900 px-3 py-1.5 text-xs text-white opacity-75">
                {{ $project->tasks->count() }} tasks | Sprint {{ $currentSprint?->number ?? 'none' }}
            </div>
        @endenv
    </div>
@endsection
