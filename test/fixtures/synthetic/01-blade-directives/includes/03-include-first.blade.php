---
description: "The @includeFirst directive for fallback template selection"
features:
  - "@includeFirst directive"
  - "Template fallbacks"
  - "View existence checking"
  - "Multiple template options"
complexity: medium
---
<div class="notification-center">
    <h2>Notifications</h2>

    @foreach($notifications as $notification)
        <div class="notification-item">
            {{-- Try to include type-specific template, fall back to generic --}}
            @includeFirst([
                "notifications.types.{$notification->type}",
                "notifications.types.default"
            ], ['notification' => $notification])
        </div>
    @endforeach
</div>

<div class="user-dashboard">
    {{-- Include user-tier specific dashboard with fallbacks --}}
    @includeFirst([
        "dashboards.{$user->tier}.overview",
        'dashboards.premium.overview',
        'dashboards.standard.overview',
        'dashboards.default'
    ], [
        'user' => $user,
        'stats' => $dashboardStats
    ])
</div>

<div class="email-template">
    {{-- Include localized email template with language fallbacks --}}
    @includeFirst([
        "emails.{$locale}.welcome",
        'emails.en.welcome',
        'emails.default.welcome'
    ], [
        'userName' => $user->name,
        'activationLink' => $activationUrl
    ])
</div>

<footer>
    {{-- Include theme-specific footer with fallback --}}
    @includeFirst([
        "themes.{$currentTheme}.footer",
        'themes.default.footer'
    ], ['year' => date('Y')])
</footer>
