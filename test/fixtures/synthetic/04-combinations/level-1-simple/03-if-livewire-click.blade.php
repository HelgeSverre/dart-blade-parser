---
description: Conditional button visibility with Livewire click handlers
features:
  - if-directive
  - livewire-click
difficulty: level-1-simple
---
<div class="task-manager">
    <h2>Task Management</h2>

    <div class="task-actions">
        @if($canCreateTask)
            <button
                wire:click="createTask"
                class="btn btn-primary"
            >
                Create New Task
            </button>
        @endif

        @if($hasSelectedTasks)
            <div class="bulk-actions">
                <button
                    wire:click="markAsComplete"
                    class="btn btn-success"
                >
                    Mark Selected as Complete
                </button>

                <button
                    wire:click="deleteSelected"
                    class="btn btn-danger"
                >
                    Delete Selected
                </button>
            </div>
        @else
            <p class="text-muted">Select tasks to perform bulk actions</p>
        @endif
    </div>

    <div class="task-list">
        @if($tasks->isEmpty())
            <div class="empty-state">
                <p>No tasks yet. Create your first task to get started!</p>
                <button wire:click="createFirstTask" class="btn btn-outline">
                    Get Started
                </button>
            </div>
        @else
            @if($canExport)
                <button wire:click="exportTasks" class="btn btn-secondary">
                    Export to CSV
                </button>
            @endif

            <button wire:click="refreshTasks" class="btn btn-link">
                Refresh List
            </button>
        @endif
    </div>
</div>
