{{-- Livewire wire:navigate and SPA navigation examples --}}
<div>
    {{-- Basic wire:navigate --}}
    <a href="/dashboard" wire:navigate>Dashboard</a>
    <a href="/settings" wire:navigate>Settings</a>

    {{-- Prefetch on hover --}}
    <a href="/profile" wire:navigate.hover>Profile</a>
    <a href="/reports/{{ $report->id }}" wire:navigate.hover>
        View Report #{{ $report->id }}
    </a>

    {{-- wire:current - active link styling --}}
    <nav>
        <a href="/dashboard" wire:navigate wire:current="font-bold text-blue-600">
            Dashboard
        </a>
        <a href="/users" wire:navigate wire:current="font-bold text-blue-600">
            Users
        </a>
        <a href="/settings" wire:navigate wire:current="font-bold text-blue-600">
            Settings
        </a>
    </nav>

    {{-- wire:current.exact - match exact path only --}}
    <a href="/posts" wire:navigate wire:current.exact="bg-blue-100">
        All Posts
    </a>

    {{-- wire:current.strict - strict matching --}}
    <a href="/admin/users" wire:navigate wire:current.strict="underline">
        Admin Users
    </a>

    {{-- wire:current.ignore - always apply class regardless of route --}}
    <a href="/home" wire:navigate wire:current.ignore="text-gray-500">
        Home
    </a>

    {{-- @persist - preserve DOM elements across navigations --}}
    @persist('player')
        <div>
            <audio id="player" src="{{ $audioUrl }}">
                Your browser does not support audio.
            </audio>
            <div class="controls">
                <button onclick="document.getElementById('player').play()">Play</button>
                <button onclick="document.getElementById('player').pause()">Pause</button>
            </div>
        </div>
    @endpersist

    @persist('video-player')
        <video id="video" src="{{ $videoUrl }}" controls></video>
    @endpersist

    {{-- wire:navigate:scroll - customize scroll behavior --}}
    <a href="/articles/{{ $article->slug }}" wire:navigate wire:navigate:scroll="preserve">
        {{ $article->title }}
    </a>

    {{-- data-navigate-track - re-run script on navigation --}}
    <script data-navigate-track>
        console.log('Page navigated');
    </script>

    {{-- data-navigate-once - run script only once --}}
    <script data-navigate-once>
        initializeAnalytics();
    </script>

    {{-- Full navigation example --}}
    <nav class="sidebar">
        <ul>
            @foreach($menuItems as $item)
                <li wire:key="menu-{{ $item->id }}">
                    <a href="{{ $item->url }}"
                       wire:navigate.hover
                       wire:current="bg-gray-100 font-semibold">
                        <span>{{ $item->icon }}</span>
                        <span>{{ $item->label }}</span>
                    </a>
                </li>
            @endforeach
        </ul>
    </nav>
</div>