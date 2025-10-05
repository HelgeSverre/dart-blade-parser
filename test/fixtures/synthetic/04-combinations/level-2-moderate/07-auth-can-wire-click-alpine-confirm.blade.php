{{--
---
features:
  - auth_directive
  - can_directive
  - wire_click
  - alpine_x_data
description: Role-based action buttons with authentication checks and Alpine confirmation dialogs
complexity: moderate
line_count: 75
--}}

<div
    x-data="{
        showDeleteConfirm: false,
        showArchiveConfirm: false,
        itemToDelete: null,
        itemToArchive: null
    }"
    class="project-management"
>
    <div class="projects-list space-y-4">
        @foreach ($projects as $project)
            <div
                wire:key="project-{{ $project->id }}"
                class="project-card p-6 bg-white rounded-lg shadow-sm border"
            >
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <h3 class="text-xl font-bold mb-2">{{ $project->name }}</h3>
                        <p class="text-gray-600 mb-4">{{ $project->description }}</p>

                        <div class="project-meta flex gap-4 text-sm text-gray-500">
                            <span>Owner: {{ $project->owner->name }}</span>
                            <span>Status: {{ $project->status }}</span>
                            <span>Due: {{ $project->due_date->format('M d, Y') }}</span>
                        </div>
                    </div>

                    <div class="project-actions flex gap-2">
                        @auth
                            @can('view', $project)
                                <button
                                    wire:click="viewProject({{ $project->id }})"
                                    class="btn btn-sm btn-outline"
                                >
                                    View
                                </button>
                            @endcan

                            @can('update', $project)
                                <button
                                    wire:click="editProject({{ $project->id }})"
                                    class="btn btn-sm btn-primary"
                                >
                                    Edit
                                </button>
                            @endcan

                            @can('archive', $project)
                                <button
                                    @click="itemToArchive = {{ $project->id }}; showArchiveConfirm = true"
                                    class="btn btn-sm btn-warning"
                                >
                                    Archive
                                </button>
                            @endcan

                            @can('delete', $project)
                                <button
                                    @click="itemToDelete = {{ $project->id }}; showDeleteConfirm = true"
                                    class="btn btn-sm btn-danger"
                                >
                                    Delete
                                </button>
                            @else
                                <button
                                    disabled
                                    class="btn btn-sm btn-outline opacity-50"
                                    title="You don't have permission to delete this project"
                                >
                                    Delete
                                </button>
                            @endcan
                        @else
                            <a href="/login" class="btn btn-sm btn-primary">
                                Login to manage
                            </a>
                        @endauth
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    {{-- Delete Confirmation Dialog --}}
    <div
        x-show="showDeleteConfirm"
        x-transition.opacity
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        @click.self="showDeleteConfirm = false"
    >
        <div class="bg-white rounded-lg p-6 max-w-md">
            <h3 class="text-xl font-bold mb-4">Confirm Delete</h3>
            <p class="text-gray-600 mb-6">
                Are you sure you want to delete this project? This action cannot be undone.
            </p>
            <div class="flex gap-3 justify-end">
                <button
                    @click="showDeleteConfirm = false"
                    class="btn btn-outline"
                >
                    Cancel
                </button>
                <button
                    @click="$wire.deleteProject(itemToDelete); showDeleteConfirm = false"
                    class="btn btn-danger"
                >
                    Delete Project
                </button>
            </div>
        </div>
    </div>

    {{-- Archive Confirmation Dialog --}}
    <div
        x-show="showArchiveConfirm"
        x-transition.opacity
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        @click.self="showArchiveConfirm = false"
    >
        <div class="bg-white rounded-lg p-6 max-w-md">
            <h3 class="text-xl font-bold mb-4">Archive Project</h3>
            <p class="text-gray-600 mb-6">
                Archived projects can be restored later. Continue?
            </p>
            <div class="flex gap-3 justify-end">
                <button
                    @click="showArchiveConfirm = false"
                    class="btn btn-outline"
                >
                    Cancel
                </button>
                <button
                    @click="$wire.archiveProject(itemToArchive); showArchiveConfirm = false"
                    class="btn btn-warning"
                >
                    Archive
                </button>
            </div>
        </div>
    </div>
</div>
