---
description: "Full admin dashboard with authentication, authorization, and real-time features"
features:
  - "@extends layout inheritance"
  - "@auth and @guest authentication checks"
  - "@can authorization gates"
  - "@foreach and @forelse loops"
  - "Multiple custom components (x-sidebar, x-notification, x-stats)"
  - "Livewire wire:* directives (model, click, poll)"
  - "Alpine.js x-data for interactivity"
  - "@push and @stack for assets"
  - "@include for partials"
  - "@section with @parent"
  - "@isset and @empty checks"
  - "Nested components with slots"
level: 4
complexity: comprehensive
line_count: ~190
---
@extends('layouts.admin')

@section('title', 'Admin Dashboard')

@push('styles')
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/chart.js@3/dist/chart.min.css">
<style>
    [x-cloak] { display: none !important; }
</style>
@endpush

@section('header')
    @parent
    <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
        @auth
            <div class="flex items-center space-x-4">
                <span class="text-sm text-gray-600">Welcome, {{ Auth::user()->name }}</span>
                <x-notification-bell :count="$unreadNotifications" />
            </div>
        @endauth
    </div>
@endsection

@section('content')
<div class="admin-panel" x-data="adminPanel()" x-init="init()">
    <div class="flex h-screen bg-gray-100">
        {{-- Sidebar --}}
        <x-admin-sidebar :active="'dashboard'" class="w-64 bg-white shadow-lg">
            <x-slot name="logo">
                <img src="/images/logo.svg" alt="Admin Logo" class="h-8 w-auto">
            </x-slot>

            <x-slot name="navigation">
                @can('view-dashboard')
                    <x-nav-item href="{{ route('admin.dashboard') }}" icon="home" :active="true">
                        Dashboard
                    </x-nav-item>
                @endcan

                @can('manage-users')
                    <x-nav-item href="{{ route('admin.users') }}" icon="users">
                        Users
                        <x-slot name="badge">{{ $userCount }}</x-slot>
                    </x-nav-item>
                @endcan

                @can('manage-products')
                    <x-nav-item href="{{ route('admin.products') }}" icon="shopping-bag">
                        Products
                    </x-nav-item>
                @endcan

                @can('view-orders')
                    <x-nav-item href="{{ route('admin.orders') }}" icon="clipboard-list">
                        Orders
                        @isset($pendingOrders)
                            <x-slot name="badge" class="bg-red-500">{{ $pendingOrders }}</x-slot>
                        @endisset
                    </x-nav-item>
                @endcan

                @can('view-analytics')
                    <x-nav-item href="{{ route('admin.analytics') }}" icon="chart-bar">
                        Analytics
                    </x-nav-item>
                @endcan

                @can('manage-settings')
                    <x-nav-item href="{{ route('admin.settings') }}" icon="cog">
                        Settings
                    </x-nav-item>
                @endcan
            </x-slot>

            <x-slot name="footer">
                @auth
                    <div class="p-4 border-t border-gray-200">
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <button type="submit" class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md">
                                Sign Out
                            </button>
                        </form>
                    </div>
                @endauth
            </x-slot>
        </x-admin-sidebar>

        {{-- Main Content --}}
        <div class="flex-1 flex flex-col overflow-hidden">
            {{-- Top Navigation --}}
            <header class="bg-white shadow-sm z-10">
                <div class="px-6 py-4 flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <button @click="sidebarOpen = !sidebarOpen" class="lg:hidden">
                            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                            </svg>
                        </button>

                        {{-- Real-time status indicator --}}
                        <div class="flex items-center space-x-2" wire:poll.5s>
                            <span class="relative flex h-3 w-3">
                                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                            </span>
                            <span class="text-sm text-gray-600">System Online</span>
                        </div>
                    </div>

                    <div class="flex items-center space-x-4">
                        <div class="relative" x-data="{ open: false }">
                            <button @click="open = !open" class="flex items-center space-x-2 text-gray-700 hover:text-gray-900">
                                <img src="{{ Auth::user()->avatar }}" alt="Avatar" class="h-8 w-8 rounded-full">
                                <span class="text-sm font-medium">{{ Auth::user()->name }}</span>
                                <svg class="h-5 w-5" :class="{ 'transform rotate-180': open }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                                </svg>
                            </button>

                            <div x-show="open" @click.away="open = false" x-cloak x-transition class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1">
                                <a href="{{ route('profile') }}" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Profile</a>
                                <a href="{{ route('settings') }}" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Settings</a>
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            {{-- Dashboard Content --}}
            <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-100 p-6">
                {{-- Stats Grid --}}
                @can('view-stats')
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8" wire:poll.15s>
                        <x-stat-card
                            title="Total Revenue"
                            :value="$stats['revenue']"
                            prefix="$"
                            :trend="$stats['revenue_trend']"
                            :percentage="$stats['revenue_change']"
                            icon="currency-dollar"
                            color="green"
                        />

                        <x-stat-card
                            title="New Orders"
                            :value="$stats['orders']"
                            :trend="$stats['orders_trend']"
                            :percentage="$stats['orders_change']"
                            icon="shopping-cart"
                            color="blue"
                        />

                        <x-stat-card
                            title="Total Users"
                            :value="$stats['users']"
                            :trend="$stats['users_trend']"
                            :percentage="$stats['users_change']"
                            icon="users"
                            color="purple"
                        />

                        <x-stat-card
                            title="Conversion Rate"
                            :value="$stats['conversion']"
                            suffix="%"
                            :trend="$stats['conversion_trend']"
                            :percentage="$stats['conversion_change']"
                            icon="chart-bar"
                            color="orange"
                        />
                    </div>
                @endcan

                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                    {{-- Recent Orders --}}
                    @can('view-orders')
                        <div class="lg:col-span-2 bg-white rounded-lg shadow-md">
                            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                                <h2 class="text-lg font-semibold">Recent Orders</h2>
                                <button wire:click="refreshOrders" class="text-sm text-blue-600 hover:text-blue-800">
                                    <span wire:loading.remove wire:target="refreshOrders">Refresh</span>
                                    <span wire:loading wire:target="refreshOrders">Loading...</span>
                                </button>
                            </div>
                            <div class="p-6">
                                @forelse($recentOrders as $order)
                                    <div class="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
                                        <div class="flex items-center space-x-3">
                                            <div class="flex-shrink-0">
                                                <span class="flex items-center justify-center h-10 w-10 rounded-full bg-blue-100 text-blue-600 font-semibold">
                                                    #{{ $order->id }}
                                                </span>
                                            </div>
                                            <div>
                                                <p class="text-sm font-medium text-gray-900">{{ $order->customer_name }}</p>
                                                <p class="text-xs text-gray-500">{{ $order->created_at->diffForHumans() }}</p>
                                            </div>
                                        </div>
                                        <div class="flex items-center space-x-3">
                                            <span class="text-sm font-semibold text-gray-900">${{ number_format($order->total, 2) }}</span>
                                            <span class="px-2 py-1 text-xs font-semibold rounded-full {{ $order->status_color }}">
                                                {{ $order->status }}
                                            </span>
                                            @can('manage-orders')
                                                <button wire:click="viewOrder({{ $order->id }})" class="text-blue-600 hover:text-blue-800">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                                                    </svg>
                                                </button>
                                            @endcan
                                        </div>
                                    </div>
                                @empty
                                    <div class="text-center py-8 text-gray-500">
                                        <p>No recent orders</p>
                                    </div>
                                @endforelse
                            </div>
                        </div>
                    @endcan

                    {{-- Activity Feed --}}
                    <div class="bg-white rounded-lg shadow-md">
                        <div class="px-6 py-4 border-b border-gray-200">
                            <h2 class="text-lg font-semibold">Activity Feed</h2>
                        </div>
                        <div class="p-6">
                            <div class="space-y-4" wire:poll.10s>
                                @foreach($activities as $activity)
                                    <div class="flex items-start space-x-3">
                                        <div class="flex-shrink-0">
                                            <div class="h-8 w-8 rounded-full bg-{{ $activity->color }}-100 flex items-center justify-center">
                                                <svg class="h-4 w-4 text-{{ $activity->color }}-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    {!! $activity->icon !!}
                                                </svg>
                                            </div>
                                        </div>
                                        <div class="flex-1 min-w-0">
                                            <p class="text-sm text-gray-900">{{ $activity->message }}</p>
                                            <p class="text-xs text-gray-500 mt-1">{{ $activity->created_at->diffForHumans() }}</p>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    </div>
                </div>

                {{-- Charts Section --}}
                @can('view-analytics')
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div class="bg-white rounded-lg shadow-md p-6">
                            <h2 class="text-lg font-semibold mb-4">Sales Overview</h2>
                            <canvas id="salesChart" x-ref="salesChart"></canvas>
                        </div>

                        <div class="bg-white rounded-lg shadow-md p-6">
                            <h2 class="text-lg font-semibold mb-4">Top Products</h2>
                            <canvas id="productsChart" x-ref="productsChart"></canvas>
                        </div>
                    </div>
                @endcan

                {{-- Include modals and partials --}}
                @include('admin.partials.quick-actions')
                @include('admin.partials.notifications-panel')
            </main>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js@3"></script>
<script>
    function adminPanel() {
        return {
            sidebarOpen: false,
            init() {
                this.initCharts();
                this.setupWebSocket();
            },
            initCharts() {
                // Sales Chart
                if (this.$refs.salesChart) {
                    const salesCtx = this.$refs.salesChart.getContext('2d');
                    new Chart(salesCtx, {
                        type: 'line',
                        data: {
                            labels: @json($chartLabels),
                            datasets: [{
                                label: 'Sales',
                                data: @json($salesData),
                                borderColor: 'rgb(59, 130, 246)',
                                backgroundColor: 'rgba(59, 130, 246, 0.1)',
                                tension: 0.4
                            }]
                        }
                    });
                }

                // Products Chart
                if (this.$refs.productsChart) {
                    const productsCtx = this.$refs.productsChart.getContext('2d');
                    new Chart(productsCtx, {
                        type: 'bar',
                        data: {
                            labels: @json($productLabels),
                            datasets: [{
                                label: 'Sales',
                                data: @json($productData),
                                backgroundColor: 'rgba(139, 92, 246, 0.8)'
                            }]
                        }
                    });
                }
            },
            setupWebSocket() {
                // WebSocket connection for real-time updates
                window.Echo.private('admin.dashboard')
                    .listen('OrderCreated', (e) => {
                        @this.call('handleNewOrder', e.order);
                    })
                    .listen('UserRegistered', (e) => {
                        @this.call('handleNewUser', e.user);
                    });
            }
        }
    }
</script>
@endpush
