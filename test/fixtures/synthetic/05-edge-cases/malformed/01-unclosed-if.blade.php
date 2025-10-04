{{--
features: [if, blade-directives, control-structures, malformed]
complexity: low
lines: 28
valid: false
description: Missing @endif directive to test parser error recovery and unclosed block detection
--}}

<div class="dashboard">
  <header class="dashboard-header">
    <h1>Welcome, {{ $user->name }}</h1>
  </header>

  <main class="dashboard-content">
    @if ($user->hasNotifications())
      <div class="notification-panel">
        <h2>Notifications</h2>
        <ul class="notification-list">
          @foreach ($notifications as $notification)
            <li class="notification-item">
              <span class="notification-icon">{{ $notification->icon }}</span>
              <span class="notification-message">{{ $notification->message }}</span>
              <span class="notification-time">{{ $notification->created_at->diffForHumans() }}</span>
            </li>
          @endforeach
        </ul>
      </div>
    {{-- Missing @endif here --}}

    <div class="stats-section">
      <h2>Your Statistics</h2>
      <p>Total Posts: {{ $user->posts->count() }}</p>
      <p>Total Comments: {{ $user->comments->count() }}</p>
    </div>
  </main>
</div>
