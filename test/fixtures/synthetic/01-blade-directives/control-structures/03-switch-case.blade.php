{{--
features: [switch, case, default, blade-directives, control-structures]
complexity: medium
lines: 42
valid: true
description: Role-based content rendering and status badge display
--}}

<div class="user-card">
  <div class="user-header">
    <img src="{{ $user->avatar_url }}" alt="{{ $user->name }}" class="avatar">
    <h3>{{ $user->name }}</h3>

    {{-- Role-based badge display --}}
    @switch($user->role)
      @case('super_admin')
        <span class="badge badge-danger">
          <i class="icon-shield"></i> Super Admin
        </span>
        @break

      @case('admin')
        <span class="badge badge-warning">
          <i class="icon-key"></i> Administrator
        </span>
        @break

      @case('moderator')
        <span class="badge badge-info">
          <i class="icon-eye"></i> Moderator
        </span>
        @break

      @case('premium')
        <span class="badge badge-success">
          <i class="icon-star"></i> Premium Member
        </span>
        @break

      @default
        <span class="badge badge-secondary">
          <i class="icon-user"></i> Member
        </span>
    @endswitch
  </div>

  <div class="user-actions">
    <a href="{{ route('user.profile', $user->id) }}" class="btn btn-sm btn-primary">View Profile</a>
  </div>
</div>
