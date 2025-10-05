---
description: "Authentication state directives: @auth and @guest for conditional rendering"
features:
  - "@auth directive"
  - "@guest directive"
  - "@endauth/@endguest"
  - "Guard specification"
  - "Authentication checks"
complexity: low
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Welcome</title>
</head>
<body>
    <nav class="navbar">
        <div class="logo">MyApp</div>

        <div class="nav-menu">
            @auth
                <a href="/dashboard">Dashboard</a>
                <a href="/profile">Profile</a>
                <a href="/settings">Settings</a>
            @endauth

            @guest
                <a href="/features">Features</a>
                <a href="/pricing">Pricing</a>
                <a href="/about">About</a>
            @endguest
        </div>

        <div class="nav-actions">
            @auth
                <span>Welcome, {{ Auth::user()->name }}</span>
                <form method="POST" action="/logout">
                    @csrf
                    <button type="submit">Logout</button>
                </form>
            @endauth

            @guest
                <a href="/login" class="btn-secondary">Login</a>
                <a href="/register" class="btn-primary">Sign Up</a>
            @endguest
        </div>
    </nav>

    <main>
        @auth('admin')
            <div class="admin-panel">
                <a href="/admin">Admin Panel</a>
            </div>
        @endauth
    </main>
</body>
</html>
