<div
    x-data="{
        searchOpen: false,
        searchQuery: @entangle('searchQuery'),
        profileOpen: false,
        notificationsOpen: false,
    }"
    class="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8"
>
    <!-- Mobile menu toggle -->
    <button
        type="button"
        class="-m-2.5 p-2.5 text-gray-700 lg:hidden"
        x-on:click="$dispatch('toggle-mobile-menu')"
    >
        <span class="sr-only">Open sidebar</span>
        @svg('heroicon-o-bars-3', 'size-6')
    </button>

    <!-- Separator -->
    <div class="h-6 w-px bg-gray-200 lg:hidden" aria-hidden="true"></div>

    <div class="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
        <!-- Global search -->
        <div class="relative flex flex-1" x-data="{ focused: false }">
            <label for="search-field" class="sr-only">Search</label>
            <div class="relative w-full">
                @svg('heroicon-o-magnifying-glass', 'pointer-events-none absolute inset-y-0 left-0 h-full w-5 text-gray-400')

                <input
                    id="search-field"
                    type="search"
                    placeholder="Search for..."
                    class="block h-full w-full border-0 py-0 pl-8 pr-0 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm"
                    wire:model.live.debounce.300ms="searchQuery"
                    @click="searchOpen = true; focused = true"
                    @keydown.escape="searchOpen = false; focused = false"
                    @keydown.window.prevent.cmd.k="$refs.searchInput.focus(); searchOpen = true"
                    x-ref="searchInput"
                />

                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
                    <span
                        class="hidden items-center gap-1 rounded border border-gray-300 px-1.5 py-0.5 text-xs text-gray-400 sm:flex"
                    >
                        <kbd class="font-sans">⌘</kbd>
                        <kbd class="font-sans">K</kbd>
                    </span>
                </div>
            </div>

            <!-- Search results dropdown -->
            <div
                x-show="searchOpen && searchQuery.length > 0"
                x-transition:enter="transition ease-out duration-100"
                x-transition:enter-start="transform opacity-0 scale-95"
                x-transition:enter-end="transform opacity-100 scale-100"
                x-transition:leave="transition ease-in duration-75"
                x-transition:leave-start="transform opacity-100 scale-100"
                x-transition:leave-end="transform opacity-0 scale-95"
                x-cloak
                @click.away="searchOpen = false"
                class="absolute left-0 top-full z-50 mt-1 w-full overflow-hidden rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5"
            >
                <div class="max-h-96 overflow-y-auto p-2">
                    @if ($searchResults->isNotEmpty())
                        @foreach ($searchResults as $result)
                            <x-dynamic-component
                                :component="$result->getSearchResultComponent()"
                                :result="$result"
                            />
                        @endforeach
                    @else
                        <div class="px-4 py-8 text-center text-sm text-gray-500">
                            No results found for "{{ $searchQuery }}"
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Right side actions -->
        <div class="flex items-center gap-x-4 lg:gap-x-6">

            @env('local')
                <div class="flex items-center gap-2 rounded-md bg-yellow-100 px-2 py-1 text-xs font-medium text-yellow-800">
                    @svg('heroicon-o-wrench-screwdriver', 'size-4')
                    <span>Local</span>
                </div>
            @endenv

            @role('superadmin')
                <!-- Impersonation banner -->
                @if ($impersonating)
                    <div class="flex items-center gap-2">
                        <span class="text-xs font-medium text-orange-600">
                            Impersonating: {{ $impersonatedUser->name }}
                        </span>
                        <button
                            wire:click="stopImpersonating"
                            class="rounded-md bg-orange-100 px-2 py-1 text-xs font-medium text-orange-700 hover:bg-orange-200"
                        >
                            Stop
                        </button>
                    </div>
                @endif

                <!-- Admin quick links -->
                <div class="hidden items-center gap-1 lg:flex">
                    <a
                        href="{{ route('admin.dashboard') }}"
                        x-tooltip.raw="Admin Dashboard"
                        @class([
                            'rounded-md p-2 text-gray-400 hover:text-gray-500',
                            'text-indigo-600' => request()->routeIs('admin.*'),
                        ])
                    >
                        @svg('heroicon-o-cog-6-tooth', 'size-5')
                    </a>

                    <a
                        href="{{ route('queue-manager.index') }}"
                        x-tooltip.raw="Queue Manager"
                        class="rounded-md p-2 text-gray-400 hover:text-gray-500"
                        target="_blank"
                    >
                        @svg('heroicon-o-server-stack', 'size-5')
                    </a>

                    <a
                        href="{{ config('services.error_tracker.dashboard_url') }}"
                        x-tooltip.raw="ErrorTracker"
                        class="rounded-md p-2 text-gray-400 hover:text-gray-500"
                        target="_blank"
                    >
                        @svg('heroicon-o-bug-ant', 'size-5')
                    </a>
                </div>
            @endrole

            @if (false)
                <!-- Feature: Activity Feed (coming soon) -->
                <button
                    type="button"
                    class="rounded-md p-2 text-gray-400 hover:text-gray-500"
                    x-tooltip.raw="Activity Feed"
                >
                    @svg('heroicon-o-rss', 'size-5')
                </button>
            @endif

            <!-- Notifications -->
            <div class="relative" x-data="{ open: false }">
                <button
                    type="button"
                    class="-m-1.5 flex items-center p-1.5 text-gray-400 hover:text-gray-500"
                    @click="open = !open"
                    x-tooltip.raw="Notifications"
                >
                    <span class="sr-only">View notifications</span>
                    <span class="relative">
                        @svg('heroicon-o-bell', 'size-6')
                        @if ($unreadNotificationCount > 0)
                            <span class="absolute -right-1 -top-1 flex size-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white">
                                {{ $unreadNotificationCount > 9 ? '9+' : $unreadNotificationCount }}
                            </span>
                        @endif
                    </span>
                </button>

                <div
                    x-show="open"
                    x-transition:enter="transition ease-out duration-100"
                    x-transition:enter-start="transform opacity-0 scale-95"
                    x-transition:enter-end="transform opacity-100 scale-100"
                    x-transition:leave="transition ease-in duration-75"
                    x-transition:leave-start="transform opacity-100 scale-100"
                    x-transition:leave-end="transform opacity-0 scale-95"
                    x-cloak
                    @click.away="open = false"
                    class="absolute right-0 z-50 mt-2 w-80 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                >
                    <div class="border-b border-gray-100 px-4 py-3">
                        <div class="flex items-center justify-between">
                            <h3 class="text-sm font-semibold text-gray-900">Notifications</h3>
                            @if ($unreadNotificationCount > 0)
                                <button
                                    wire:click="markAllAsRead"
                                    class="text-xs text-indigo-600 hover:text-indigo-500"
                                >
                                    Mark all as read
                                </button>
                            @endif
                        </div>
                    </div>

                    <div class="max-h-96 overflow-y-auto">
                        @forelse ($notifications as $notification)
                            <a
                                href="{{ $notification->data['url'] ?? '#' }}"
                                wire:navigate
                                wire:click="markAsRead('{{ $notification->id }}')"
                                @class([
                                    'block border-b border-gray-50 px-4 py-3 hover:bg-gray-50',
                                    'bg-indigo-50/50' => $notification->unread(),
                                ])
                            >
                                <div class="flex items-start gap-3">
                                    <div class="flex-shrink-0 pt-0.5">
                                        @svg($notification->data['icon'] ?? 'heroicon-o-bell', 'size-5 text-gray-400')
                                    </div>
                                    <div class="min-w-0 flex-1">
                                        <p class="text-sm font-medium text-gray-900">
                                            {{ $notification->data['title'] }}
                                        </p>
                                        <p class="mt-0.5 text-xs text-gray-500">
                                            {{ $notification->created_at->diffForHumans() }}
                                        </p>
                                    </div>
                                    @if ($notification->unread())
                                        <span class="mt-1 size-2 flex-shrink-0 rounded-full bg-indigo-500"></span>
                                    @endif
                                </div>
                            </a>
                        @empty
                            <div class="px-4 py-8 text-center text-sm text-gray-500">
                                No notifications yet
                            </div>
                        @endforelse
                    </div>

                    @if ($notifications->isNotEmpty())
                        <div class="border-t border-gray-100 px-4 py-2">
                            <a
                                href="{{ route('notifications.index') }}"
                                wire:navigate
                                class="block text-center text-xs font-medium text-indigo-600 hover:text-indigo-500"
                            >
                                View all notifications
                            </a>
                        </div>
                    @endif
                </div>
            </div>

            <!-- Separator -->
            <div class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-200" aria-hidden="true"></div>

            <!-- Settings -->
            <a
                href="{{ route('settings.index') }}"
                wire:navigate
                x-tooltip.raw="Settings"
                @class([
                    'hidden rounded-md p-2 text-gray-400 hover:text-gray-500 lg:block',
                    '!text-indigo-600' => request()->routeIs('settings.*'),
                ])
            >
                @svg('heroicon-o-cog-8-tooth', 'size-5')
                <span class="sr-only">Settings</span>
            </a>

            <!-- Team Members -->
            @unless ($currentTeam->personal_team)
                <a
                    href="{{ route('teams.members', $currentTeam) }}"
                    wire:navigate
                    x-tooltip.raw="Team Members"
                    @class([
                        'hidden rounded-md p-2 text-gray-400 hover:text-gray-500 lg:block',
                        '!text-indigo-600' => request()->routeIs('teams.members'),
                    ])
                >
                    @svg('heroicon-o-user-group', 'size-5')
                    <span class="sr-only">Team Members</span>
                </a>
            @endunless

            <!-- Profile dropdown -->
            <div class="relative" x-data="{ open: false }">
                <button
                    type="button"
                    class="-m-1.5 flex items-center p-1.5"
                    @click="open = !open"
                    id="user-menu-button"
                    aria-expanded="false"
                    aria-haspopup="true"
                >
                    <span class="sr-only">Open user menu</span>
                    <img
                        class="size-8 rounded-full bg-gray-50"
                        src="{{ auth()->user()->avatar_url }}"
                        alt="{{ auth()->user()->name }}"
                    />
                    <span class="hidden lg:flex lg:items-center">
                        <span
                            class="ml-4 text-sm font-semibold leading-6 text-gray-900"
                            aria-hidden="true"
                        >
                            {{ auth()->user()->name }}
                        </span>
                        @svg('heroicon-m-chevron-down', 'ml-2 size-5 text-gray-400')
                    </span>
                </button>

                <div
                    x-show="open"
                    x-transition:enter="transition ease-out duration-100"
                    x-transition:enter-start="transform opacity-0 scale-95"
                    x-transition:enter-end="transform opacity-100 scale-100"
                    x-transition:leave="transition ease-in duration-75"
                    x-transition:leave-start="transform opacity-100 scale-100"
                    x-transition:leave-end="transform opacity-0 scale-95"
                    x-cloak
                    @click.away="open = false"
                    class="absolute right-0 z-50 mt-2.5 w-56 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none"
                    role="menu"
                    aria-orientation="vertical"
                    aria-labelledby="user-menu-button"
                    tabindex="-1"
                >
                    <div class="border-b border-gray-100 px-3 py-2">
                        <p class="text-sm font-medium text-gray-900">
                            {{ auth()->user()->name }}
                        </p>
                        <p class="mt-0.5 text-xs text-gray-500">
                            {{ auth()->user()->email }}
                        </p>
                    </div>

                    <a
                        href="{{ route('profile.show') }}"
                        wire:navigate
                        class="block px-3 py-1.5 text-sm leading-6 text-gray-900 hover:bg-gray-50"
                        role="menuitem"
                        tabindex="-1"
                    >
                        Your Profile
                    </a>

                    <a
                        href="{{ route('settings.index') }}"
                        wire:navigate
                        class="block px-3 py-1.5 text-sm leading-6 text-gray-900 hover:bg-gray-50"
                        role="menuitem"
                        tabindex="-1"
                    >
                        Settings
                    </a>

                    @role('superadmin')
                        <div class="border-t border-gray-100 my-1"></div>
                        <a
                            href="{{ route('admin.dashboard') }}"
                            wire:navigate
                            class="block px-3 py-1.5 text-sm leading-6 text-gray-900 hover:bg-gray-50"
                            role="menuitem"
                            tabindex="-1"
                        >
                            Admin Dashboard
                        </a>
                    @endrole

                    <div class="border-t border-gray-100 my-1"></div>

                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <button
                            type="submit"
                            class="block w-full px-3 py-1.5 text-left text-sm leading-6 text-gray-900 hover:bg-gray-50"
                            role="menuitem"
                            tabindex="-1"
                        >
                            Sign out
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <x-filament-actions::modals />
</div>
