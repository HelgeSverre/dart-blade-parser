{{--
---
features:
  - forelse_directive
  - wire_loading
  - alpine_x_transition
  - wire_poll
description: Async notification list with loading states and smooth transitions
complexity: moderate
line_count: 75
--}}

<div
    x-data="{ showNotifications: true }"
    class="notifications-panel"
    wire:poll.5s="refreshNotifications"
>
    <div class="panel-header flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold">Notifications</h3>

        <button
            wire:click="markAllAsRead"
            class="text-sm text-blue-600 hover:underline"
        >
            Mark all as read
        </button>
    </div>

    <div
        wire:loading.class="opacity-50"
        class="transition-opacity duration-200"
    >
        @forelse ($notifications as $notification)
            <div
                x-show="showNotifications"
                x-transition:enter="transition ease-out duration-300"
                x-transition:enter-start="opacity-0 transform translate-x-4"
                x-transition:enter-end="opacity-100 transform translate-x-0"
                x-transition:leave="transition ease-in duration-200"
                x-transition:leave-start="opacity-100 transform translate-x-0"
                x-transition:leave-end="opacity-0 transform -translate-x-4"
                wire:key="notification-{{ $notification->id }}"
                class="notification-item p-4 mb-2 rounded-lg border {{ $notification->read ? 'bg-gray-50' : 'bg-white border-blue-200' }}"
            >
                <div class="flex items-start gap-3">
                    <div class="notification-icon mt-1">
                        @if ($notification->type === 'success')
                            <span class="text-green-500">✓</span>
                        @elseif ($notification->type === 'warning')
                            <span class="text-yellow-500">⚠</span>
                        @elseif ($notification->type === 'error')
                            <span class="text-red-500">✕</span>
                        @else
                            <span class="text-blue-500">ℹ</span>
                        @endif
                    </div>

                    <div class="flex-1">
                        <h4 class="font-medium {{ $notification->read ? 'text-gray-700' : 'text-gray-900' }}">
                            {{ $notification->title }}
                        </h4>
                        <p class="text-sm text-gray-600 mt-1">
                            {{ $notification->message }}
                        </p>
                        <span class="text-xs text-gray-500 mt-2 block">
                            {{ $notification->created_at->diffForHumans() }}
                        </span>
                    </div>

                    <div class="flex gap-2">
                        <button
                            wire:click="markAsRead({{ $notification->id }})"
                            class="text-sm text-blue-600 hover:underline"
                        >
                            Read
                        </button>
                        <button
                            wire:click="deleteNotification({{ $notification->id }})"
                            class="text-sm text-red-600 hover:underline"
                        >
                            Delete
                        </button>
                    </div>
                </div>
            </div>
        @empty
            <div class="empty-state text-center py-12">
                <p class="text-gray-500">No notifications</p>
                <p class="text-sm text-gray-400 mt-2">You're all caught up!</p>
            </div>
        @endforelse
    </div>

    <div wire:loading class="loading-indicator mt-4 text-center">
        <span class="text-sm text-gray-500">Checking for new notifications...</span>
    </div>
</div>
