---
description: Authenticated user interface with Alpine.js attribute binding
features:
  - auth-directive
  - alpine-bind
difficulty: level-1-simple
---
<div x-data="{
    theme: 'light',
    sidebarOpen: true,
    userMenuOpen: false
}">
    <nav
        class="navbar"
        :class="{ 'dark-theme': theme === 'dark' }"
        x-bind:data-theme="theme"
    >
        @auth
            <div class="nav-controls">
                <button
                    @click="sidebarOpen = !sidebarOpen"
                    :aria-label="sidebarOpen ? 'Close sidebar' : 'Open sidebar'"
                    :class="{ 'active': sidebarOpen }"
                >
                    Menu
                </button>

                <div class="user-menu" @click.away="userMenuOpen = false">
                    <button
                        @click="userMenuOpen = !userMenuOpen"
                        :aria-expanded="userMenuOpen"
                        x-bind:class="{ 'menu-open': userMenuOpen }"
                    >
                        <img
                            :src="'{{ $user->avatar }}'"
                            :alt="'{{ $user->name }} avatar'"
                            x-bind:title="'{{ $user->name }}'"
                        >
                    </button>

                    <div
                        class="dropdown-menu"
                        x-show="userMenuOpen"
                        x-bind:hidden="!userMenuOpen"
                    >
                        <a href="{{ route('profile') }}">Profile</a>
                        <a href="{{ route('settings') }}">Settings</a>
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <button type="submit">Logout</button>
                        </form>
                    </div>
                </div>
            </div>
        @endauth

        @guest
            <div class="guest-nav">
                <a
                    href="{{ route('login') }}"
                    x-bind:class="{ 'btn-light': theme === 'dark', 'btn-dark': theme === 'light' }"
                >
                    Login
                </a>
                <a
                    href="{{ route('register') }}"
                    x-bind:class="{ 'btn-primary-light': theme === 'dark', 'btn-primary': theme === 'light' }"
                >
                    Sign Up
                </a>
            </div>
        @endguest

        <button
            @click="theme = theme === 'light' ? 'dark' : 'light'"
            :aria-label="'Switch to ' + (theme === 'light' ? 'dark' : 'light') + ' theme'"
            x-bind:data-active-theme="theme"
        >
            <span x-show="theme === 'light'">🌙</span>
            <span x-show="theme === 'dark'">☀️</span>
        </button>
    </nav>

    @auth
        <aside
            class="sidebar"
            x-show="sidebarOpen"
            x-bind:aria-hidden="!sidebarOpen"
            :class="{ 'sidebar-collapsed': !sidebarOpen }"
        >
            <div class="user-info" x-bind:data-role="{{ $user->role }}">
                <h3>{{ $user->name }}</h3>
                <p>{{ $user->email }}</p>
                <span
                    class="role-badge"
                    x-bind:style="'background-color: ' + (theme === 'dark' ? '#333' : '#f0f0f0')"
                >
                    {{ $user->role }}
                </span>
            </div>
        </aside>
    @endauth
</div>
