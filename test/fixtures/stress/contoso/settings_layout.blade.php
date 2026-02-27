@php
    $base = 'group my-0.5 flex items-center rounded-md px-3 py-2 text-sm font-semibold transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-100';
    $activeLink = 'bg-blue-50 font-bold text-blue-800/80';
    $defaultLink = 'text-gray-600 hover:bg-gray-50 hover:text-gray-900';

    $activeIcon = 'text-blue-600/80';
    $defaultIcon = 'text-gray-400 group-hover:text-gray-600';

    $menuItems = [
        [
            'route' => 'profile.show',
            'icon' => 'lucide-user',
            'label' => 'My Profile',
            'permission' => null,
        ],
        [
            'route' => 'company.index',
            'icon' => 'lucide-briefcase',
            'label' => 'Company',
            'permission' => \App\Enums\Permission::manageCompanySettings,
        ],
        [
            'route' => 'templates.index',
            'icon' => 'lucide-file',
            'label' => 'Templates',
            'permission' => \App\Enums\Permission::manageTemplates,
        ],
        [
            'route' => 'billing.show',
            'icon' => 'lucide-banknote',
            'label' => 'Billing Settings',
            'permission' => \App\Enums\Permission::manageBillingSettings,
        ],
        [
            'route' => 'integration.index',
            'icon' => 'lucide-grid-2x2-plus',
            'label' => 'Integrations',
            'permission' => \App\Enums\Permission::manageIntegrations,
        ],
        [
            'route' => 'user.index',
            'icon' => 'lucide-users',
            'label' => 'Team Members',
            'permission' => \App\Enums\Permission::manageUsers,
        ],
        [
            'route' => 'signature.edit',
            'icon' => 'lucide-pencil',
            'label' => 'Email Signature',
            'permission' => \App\Enums\Permission::manageCompanySettings,
        ],
        [
            'route' => 'role-permissions.manage',
            'icon' => 'lucide-shield-check',
            'label' => 'Access Control',
            'permission' => \App\Enums\Permission::managePermissions,
        ],
    ];
@endphp

<div
    class="relative flex h-full flex-1 flex-col pt-14 md:ml-60"
    {{ $attributes }}
>
    {{-- Top Bar --}}
    <div class="sticky top-14 z-10">
        <span id="sr-breadcrumbs"></span>
        {{ $actions ?? '' }}
    </div>

    {{-- Content wrapper --}}
    <span id="sr-content"></span>
    <main
        class="relative grid flex-row bg-gray-100 md:flex-1 md:grid-cols-4 md:pl-60"
    >
        {{-- Mobile Select Navigation --}}
        <div class="block border-b border-gray-200 bg-white p-4 md:hidden">
            <select
                onchange="window.location = this.value"
                class="w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500"
            >
                @foreach ($menuItems as $item)
                    @if (! $item['permission'] || $item['permission']->isAllowed())
                        <option
                            value="{{ route($item['route']) }}"
                            @selected(request()->routeIs(Str::beforeLast($item['route'], '.').'.*'))
                        >
                            {{ $item['label'] }}
                        </option>
                    @endif
                @endforeach
            </select>
        </div>

        {{-- Desktop Sidebar --}}
        <aside
            class="hidden flex-col border-b border-gray-200 bg-white p-4 md:fixed md:bottom-0 md:top-14 md:mt-10 md:flex md:w-60 md:border-b-0 md:border-r"
        >
            @foreach ($menuItems as $item)
                @if (! $item['permission'] || $item['permission']->isAllowed())
                    <a
                        href="{{ route($item['route']) }}"
                        wire:navigate
                        data-pan="menu-settings-{{ str_slug($item['label']) }}"
                        @class([
                            $base,
                            $activeLink => request()->routeIs(Str::beforeLast($item['route'], '.').'.*'),
                            $defaultLink => ! request()->routeIs(Str::beforeLast($item['route'], '.').'.*'),
                        ])
                    >
                        <x-dynamic-component
                            :component="$item['icon']"
                            @class([
                                'flex-shrink-0 -ml-1 mr-3 size-6',
                                $activeIcon => request()->routeIs(Str::beforeLast($item['route'], '.').'.*'),
                                $defaultIcon => ! request()->routeIs(Str::beforeLast($item['route'], '.').'.*'),
                            ])
                        />
                        <span class="truncate">{{ $item['label'] }}</span>
                    </a>
                @endif
            @endforeach
        </aside>

        {{-- Main content --}}
        <main
            @class([
                'col-span-full mx-auto w-full space-y-6 p-4 md:py-6 sm:px-4 md:col-span-4 lg:px-8 mb-12 ',
                'md:max-w-4xl' => isset($narrow),
                'md:max-w-6xl' => isset($wide),
                'md:max-w-full' => isset($full),
            ])
        >
            {{ $slot }}
        </main>
    </main>

    {{-- Footer --}}
    <span id="sr-footer"></span>
    {{ $footer ?? '' }}
</div>
