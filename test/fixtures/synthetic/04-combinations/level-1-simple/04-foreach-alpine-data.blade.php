---
description: Interactive todo list with Alpine.js data and foreach loop
features:
  - foreach-directive
  - alpine-data
difficulty: level-1-simple
---
<div x-data="{
    filter: 'all',
    completedCount: {{ $todos->where('completed', true)->count() }}
}">
    <div class="todo-header">
        <h1>My Todo List</h1>
        <div class="filter-buttons">
            <button @click="filter = 'all'" :class="{ active: filter === 'all' }">
                All
            </button>
            <button @click="filter = 'active'" :class="{ active: filter === 'active' }">
                Active
            </button>
            <button @click="filter = 'completed'" :class="{ active: filter === 'completed' }">
                Completed
            </button>
        </div>
    </div>

    <ul class="todo-list">
        @foreach($todos as $todo)
            <li
                x-data="{ completed: {{ $todo->completed ? 'true' : 'false' }} }"
                x-show="filter === 'all' || (filter === 'completed' && completed) || (filter === 'active' && !completed)"
                :class="{ 'completed': completed }"
            >
                <input
                    type="checkbox"
                    x-model="completed"
                    @change="completedCount += completed ? 1 : -1"
                >
                <span>{{ $todo->title }}</span>
                <span class="priority" :class="'priority-{{ $todo->priority }}'">
                    {{ $todo->priority }}
                </span>
            </li>
        @endforeach
    </ul>

    <div class="todo-stats" x-data="{ total: {{ $todos->count() }} }">
        <p><span x-text="total - completedCount"></span> active tasks</p>
        <p><span x-text="completedCount"></span> completed tasks</p>
        <p><span x-text="total"></span> total tasks</p>
    </div>
</div>
