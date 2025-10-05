---
description: Conditional user greeting with echo statements
features:
  - if-directive
  - echo-statement
difficulty: level-1-simple
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Dashboard</title>
</head>
<body>
    <div class="container">
        <header>
            <h1>Welcome to Your Dashboard</h1>

            @if($user->isPremium())
                <div class="premium-badge">
                    <span class="badge">{{ $user->membershipLevel }}</span>
                    <p>Thank you for being a premium member, {{ $user->name }}!</p>
                </div>
            @else
                <div class="standard-greeting">
                    <p>Hello, {{ $user->name }}!</p>
                    <a href="{{ route('upgrade') }}">Upgrade to Premium</a>
                </div>
            @endif
        </header>

        <main>
            @if($notifications > 0)
                <div class="notification-alert">
                    <strong>You have {{ $notifications }} new notifications</strong>
                </div>
            @endif

            @if($user->hasCompletedProfile())
                <p>Profile completion: {{ $user->completionPercentage }}%</p>
            @else
                <div class="alert alert-warning">
                    <p>Your profile is {{ $user->completionPercentage }}% complete.</p>
                    <p>Complete your profile to unlock all features!</p>
                </div>
            @endif

            <div class="account-info">
                <p>Account Type: {{ $user->accountType }}</p>
                <p>Member Since: {{ $user->memberSince->format('F Y') }}</p>
            </div>
        </main>
    </div>
</body>
</html>
