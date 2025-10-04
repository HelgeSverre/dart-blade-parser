---
description: "@while loop for iterative tree/hierarchy rendering"
tags: ["while", "hierarchy", "tree-structure"]
---
<div class="notification-feed">
    <h2>Recent Notifications</h2>

    @php
        $notificationIndex = 0;
        $displayLimit = 15;
    @endphp

    <ul class="notification-list">
        @while($notificationIndex < count($notifications) && $notificationIndex < $displayLimit)
            @php
                $notification = $notifications[$notificationIndex];
                $notificationIndex++;
            @endphp

            <li class="notification-item {{ $notification->read ? 'read' : 'unread' }}">
                <div class="notification-icon {{ $notification->type }}">
                    @if($notification->type == 'comment')
                    <i class="icon-comment"></i>
                    @elseif($notification->type == 'like')
                    <i class="icon-heart"></i>
                    @elseif($notification->type == 'mention')
                    <i class="icon-at"></i>
                    @else
                    <i class="icon-bell"></i>
                    @endif
                </div>

                <div class="notification-content">
                    <p class="notification-message">
                        <strong>{{ $notification->sender->name }}</strong>
                        {{ $notification->message }}
                    </p>
                    <time class="notification-time">{{ $notification->created_at->diffForHumans() }}</time>
                </div>

                @if(!$notification->read)
                <button class="mark-read-btn" data-notification-id="{{ $notification->id }}">
                    Mark as read
                </button>
                @endif
            </li>
        @endwhile
    </ul>

    @if($notificationIndex < count($notifications))
    <div class="load-more-section">
        <p class="remaining-count">
            {{ count($notifications) - $notificationIndex }} more notifications
        </p>
        <button class="btn btn-secondary load-more">
            Load More Notifications
        </button>
    </div>
    @endif
</div>
