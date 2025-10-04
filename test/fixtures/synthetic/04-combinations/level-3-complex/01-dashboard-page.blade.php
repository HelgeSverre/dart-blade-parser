---
description: "Dashboard page with real-time stats, charts, and activity feed"
features:
  - "@extends and @section inheritance"
  - "Livewire wire:poll for real-time updates"
  - "Custom component <x-stat-card> with props"
  - "@foreach for rendering lists"
  - "Alpine.js x-data for interactive charts"
  - "wire:loading states"
  - "Conditional rendering with @if/@else"
level: 3
complexity: complex
line_count: ~110
---
@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="container mx-auto px-4 py-8" x-data="dashboardData()">
    {{-- Page Header --}}
    <div class="flex justify-between items-center mb-8">
        <div>
            <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
            <p class="text-gray-600 mt-1">Welcome back, {{ Auth::user()->name }}</p>
        </div>
        <div class="flex items-center space-x-3">
            <span class="text-sm text-gray-500" wire:poll.5s>
                Last updated: {{ now()->diffForHumans() }}
            </span>
            <button wire:click="refreshStats" class="btn-primary">
                <span wire:loading.remove wire:target="refreshStats">Refresh</span>
                <span wire:loading wire:target="refreshStats">
                    <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                </span>
            </button>
        </div>
    </div>

    {{-- Statistics Cards --}}
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8" wire:poll.15s>
        <x-stat-card
            title="Total Revenue"
            :value="$revenue"
            prefix="$"
            trend="up"
            :percentage="12.5"
            icon="currency-dollar"
            color="green"
        />

        <x-stat-card
            title="New Orders"
            :value="$orders"
            trend="up"
            :percentage="8.2"
            icon="shopping-cart"
            color="blue"
        />

        <x-stat-card
            title="Active Users"
            :value="$activeUsers"
            trend="down"
            :percentage="3.1"
            icon="users"
            color="purple"
        />

        <x-stat-card
            title="Conversion Rate"
            :value="$conversionRate"
            suffix="%"
            trend="up"
            :percentage="5.4"
            icon="chart-bar"
            color="orange"
        />
    </div>

    {{-- Main Content Grid --}}
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {{-- Sales Chart --}}
        <div class="lg:col-span-2 bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4">Sales Overview</h2>
            <canvas id="salesChart" x-ref="salesChart"></canvas>

            <script>
                function dashboardData() {
                    return {
                        init() {
                            this.renderSalesChart();
                        },
                        renderSalesChart() {
                            const ctx = this.$refs.salesChart.getContext('2d');
                            new Chart(ctx, {
                                type: 'line',
                                data: {
                                    labels: @json($chartLabels),
                                    datasets: [{
                                        label: 'Sales',
                                        data: @json($chartData),
                                        borderColor: 'rgb(59, 130, 246)',
                                        backgroundColor: 'rgba(59, 130, 246, 0.1)',
                                        tension: 0.4
                                    }]
                                }
                            });
                        }
                    }
                }
            </script>
        </div>

        {{-- Recent Activity --}}
        <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4">Recent Activity</h2>

            @if(count($activities) > 0)
                <div class="space-y-4" wire:poll.10s>
                    @foreach($activities as $activity)
                        <div class="flex items-start space-x-3 pb-4 border-b border-gray-100 last:border-0">
                            <div class="flex-shrink-0">
                                <div class="h-10 w-10 rounded-full bg-{{ $activity->color }}-100 flex items-center justify-center">
                                    <span class="text-{{ $activity->color }}-600 font-semibold">
                                        {{ substr($activity->user->name, 0, 1) }}
                                    </span>
                                </div>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium text-gray-900">
                                    {{ $activity->user->name }}
                                </p>
                                <p class="text-sm text-gray-500">
                                    {{ $activity->description }}
                                </p>
                                <p class="text-xs text-gray-400 mt-1">
                                    {{ $activity->created_at->diffForHumans() }}
                                </p>
                            </div>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-center py-8 text-gray-500">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                    </svg>
                    <p class="mt-2">No recent activity</p>
                </div>
            @endif
        </div>
    </div>
</div>
@endsection
