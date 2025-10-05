---
description: Included partials with Livewire polling for real-time updates
features:
  - include-directive
  - livewire-poll
difficulty: level-1-simple
---
<div class="dashboard-container">
    <header>
        @include('partials.nav', ['user' => $user])
    </header>

    <div class="dashboard-grid">
        <div class="stats-section" wire:poll.5s>
            @include('partials.stats-overview', [
                'totalUsers' => $stats->totalUsers,
                'activeUsers' => $stats->activeUsers,
                'revenue' => $stats->revenue
            ])
        </div>

        <div class="live-feed" wire:poll.2s="updateFeed">
            <h2>Live Activity Feed</h2>
            @include('partials.activity-items', ['activities' => $recentActivities])

            <div class="feed-status">
                <span wire:loading wire:target="updateFeed">Updating...</span>
                <span>Last updated: {{ now()->format('H:i:s') }}</span>
            </div>
        </div>

        <div class="server-status" wire:poll.10s="checkServerHealth">
            @include('partials.server-health', [
                'servers' => $servers,
                'uptime' => $systemUptime
            ])
        </div>

        <div class="notifications-widget" wire:poll.15s>
            <h3>Recent Notifications</h3>
            @include('partials.notification-list', [
                'notifications' => $notifications,
                'unreadCount' => $unreadCount
            ])
        </div>

        <div class="queue-monitor" wire:poll.3s="refreshQueueStats">
            @include('partials.queue-stats', [
                'pendingJobs' => $queueStats->pending,
                'failedJobs' => $queueStats->failed,
                'processedJobs' => $queueStats->processed
            ])

            <div wire:loading.delay wire:target="refreshQueueStats" class="updating-indicator">
                <div class="pulse"></div>
            </div>
        </div>

        <div class="cache-status">
            @include('partials.cache-info', ['cacheHitRate' => $cacheHitRate])
        </div>
    </div>

    <footer>
        @include('partials.footer', ['year' => date('Y')])
    </footer>
</div>
