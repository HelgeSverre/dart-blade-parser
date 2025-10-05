{{--
features: [if, elseif, else, blade-directives, control-structures]
complexity: medium
lines: 32
valid: true
description: User permission checks and navigation with conditional rendering
--}}

<nav class="dashboard-nav">
  <ul class="nav-menu">
    @if (auth()->check() && $user->hasPermission('view_dashboard'))
      <li class="nav-item">
        <a href="{{ route('dashboard.index') }}" class="nav-link">
          <i class="icon-dashboard"></i>
          Dashboard
        </a>
      </li>
    @endif

    @if ($user->isAdmin())
      <li class="nav-item">
        <a href="{{ route('admin.users.index') }}" class="nav-link">
          <i class="icon-users"></i>
          User Management
        </a>
      </li>
    @elseif ($user->isModerator())
      <li class="nav-item">
        <a href="{{ route('moderator.reports.index') }}" class="nav-link">
          <i class="icon-flag"></i>
          Content Reports
        </a>
      </li>
    @else
      <li class="nav-item">
        <a href="{{ route('user.profile', $user->id) }}" class="nav-link">
          <i class="icon-user"></i>
          My Profile
        </a>
      </li>
    @endif
  </ul>
</nav>
