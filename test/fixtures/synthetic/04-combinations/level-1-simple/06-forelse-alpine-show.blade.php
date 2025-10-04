---
description: Notification list with Alpine.js toggle and forelse for empty state
features:
  - forelse-directive
  - alpine-show
difficulty: level-1-simple
---
<div x-data="{
    showRead: false,
    showUnread: true,
    expandAll: false
}">
    <div class="notifications-header">
        <h2>Notifications</h2>

        <div class="filter-controls">
            <label>
                <input type="checkbox" x-model="showUnread">
                Show Unread
            </label>
            <label>
                <input type="checkbox" x-model="showRead">
                Show Read
            </label>
            <button @click="expandAll = !expandAll" class="btn-link">
                <span x-text="expandAll ? 'Collapse All' : 'Expand All'"></span>
            </button>
        </div>
    </div>

    <div class="notifications-list">
        <div x-show="showUnread">
            <h3>Unread Notifications</h3>
            @forelse($unreadNotifications as $notification)
                <div
                    class="notification-item unread"
                    x-data="{ expanded: false }"
                >
                    <div class="notification-summary" @click="expanded = !expanded">
                        <strong>{{ $notification->title }}</strong>
                        <span class="time">{{ $notification->created_at->diffForHumans() }}</span>
                    </div>
                    <div class="notification-body" x-show="expanded || expandAll">
                        <p>{{ $notification->message }}</p>
                        <a href="{{ $notification->actionUrl }}">View Details</a>
                    </div>
                </div>
            @empty
                <div class="empty-state" x-show="showUnread">
                    <p>No unread notifications. You're all caught up!</p>
                </div>
            @endforelse
        </div>

        <div x-show="showRead">
            <h3>Read Notifications</h3>
            @forelse($readNotifications as $notification)
                <div
                    class="notification-item read"
                    x-data="{ expanded: false }"
                >
                    <div class="notification-summary" @click="expanded = !expanded">
                        {{ $notification->title }}
                        <span class="time">{{ $notification->created_at->diffForHumans() }}</span>
                    </div>
                    <div class="notification-body" x-show="expanded || expandAll">
                        <p>{{ $notification->message }}</p>
                    </div>
                </div>
            @empty
                <div class="empty-state" x-show="showRead">
                    <p>No read notifications.</p>
                </div>
            @endforelse
        </div>
    </div>
</div>
