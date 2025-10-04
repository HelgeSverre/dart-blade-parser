---
description: "Conditional include directives: @includeIf, @includeWhen, and @includeUnless"
features:
  - "@includeIf directive"
  - "@includeWhen directive"
  - "@includeUnless directive"
  - "Conditional rendering"
  - "Optional partials"
complexity: medium
---
<div class="user-profile">
    <div class="profile-header">
        <h1>{{ $user->name }}</h1>
        <p>{{ $user->email }}</p>
    </div>

    {{-- Include only if the view exists --}}
    @includeIf('profiles.premium-badge', ['tier' => $user->subscription_tier])

    {{-- Include when user is verified --}}
    @includeWhen($user->email_verified_at, 'profiles.verified-badge', [
        'verifiedDate' => $user->email_verified_at
    ])

    {{-- Include unless user is suspended --}}
    @includeUnless($user->is_suspended, 'profiles.actions', [
        'canEdit' => $canEdit,
        'canDelete' => $canDelete
    ])

    <div class="profile-content">
        {{-- Include when user has completed profile --}}
        @includeWhen($user->profile_completed, 'profiles.details', ['user' => $user])

        {{-- Include if bio exists --}}
        @includeIf('profiles.bio', ['bio' => $user->bio])

        {{-- Include unless user opted out of social links --}}
        @includeUnless($user->hide_social_links, 'profiles.social-links', [
            'links' => $user->socialLinks
        ])
    </div>

    {{-- Include when user has achievements --}}
    @includeWhen(count($user->achievements) > 0, 'profiles.achievements', [
        'achievements' => $user->achievements
    ])
</div>
