{{--
features: [unless, blade-directives, control-structures, authentication]
complexity: medium
lines: 38
valid: true
description: Authentication guards and feature flag checks using unless directive
--}}

<div class="content-wrapper">
  {{-- Show upgrade prompt unless user has premium subscription --}}
  @unless ($user->hasPremiumSubscription())
    <div class="alert alert-info upgrade-banner">
      <h4>Unlock Premium Features</h4>
      <p>Get unlimited storage, advanced analytics, and priority support.</p>
      <a href="{{ route('subscriptions.plans') }}" class="btn btn-primary">
        Upgrade Now
      </a>
    </div>
  @endunless

  {{-- Show login prompt unless authenticated --}}
  @unless (auth()->check())
    <div class="guest-overlay">
      <div class="auth-prompt">
        <h3>Sign in to continue</h3>
        <p>Access your personalized dashboard and saved content.</p>
        <div class="auth-actions">
          <a href="{{ route('login') }}" class="btn btn-primary">Log In</a>
          <a href="{{ route('register') }}" class="btn btn-secondary">Sign Up</a>
        </div>
      </div>
    </div>
  @endunless

  {{-- Show beta feature notice unless user opted in --}}
  @unless ($settings->beta_features_enabled)
    <div class="notice notice-warning">
      <p>Some features are in beta.
        <a href="{{ route('settings.features') }}">Enable beta features</a>
        to try them out.
      </p>
    </div>
  @endunless
</div>
