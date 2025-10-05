{{--
features: [isset, empty, blade-directives, control-structures, optional-data]
complexity: medium
lines: 40
valid: true
description: Optional profile fields and settings with graceful degradation
--}}

<div class="profile-details">
  <div class="profile-section">
    <h2>Contact Information</h2>

    @isset($user->email)
      <div class="field">
        <label>Email:</label>
        <span>{{ $user->email }}</span>
        @isset($user->email_verified_at)
          <i class="icon-check-circle text-success" title="Verified"></i>
        @endisset
      </div>
    @endisset

    @isset($user->phone)
      <div class="field">
        <label>Phone:</label>
        <span>{{ $user->phone }}</span>
      </div>
    @endisset

    @empty($user->phone)
      <p class="text-muted">No phone number provided.</p>
    @endempty
  </div>

  <div class="profile-section">
    <h2>Social Links</h2>

    @empty($user->social_links)
      <div class="empty-state">
        <p class="text-muted">No social links added yet.</p>
        <a href="{{ route('profile.edit', ['section' => 'social']) }}" class="btn btn-sm btn-secondary">
          Add Social Links
        </a>
      </div>
    @else
      <ul class="social-links">
        @foreach($user->social_links as $platform => $url)
          <li><a href="{{ $url }}" target="_blank">{{ ucfirst($platform) }}</a></li>
        @endforeach
      </ul>
    @endempty
  </div>
</div>
