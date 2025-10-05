{{--
---
features:
  - extends_directive
  - section_directive
  - wire_poll
  - push_directive
description: Dashboard layout with real-time polling and section-based content organization
complexity: moderate
line_count: 75
--}}

@extends('layouts.dashboard')

@section('title', 'Analytics Dashboard')

@push('styles')
    <link href="/css/charts.css" rel="stylesheet">
    <style>
        .metric-card {
            transition: transform 0.2s;
        }
        .metric-card:hover {
            transform: translateY(-2px);
        }
    </style>
@endpush

@section('header')
    <div class="dashboard-header flex items-center justify-between">
        <div>
            <h1 class="text-3xl font-bold">Analytics Dashboard</h1>
            <p class="text-gray-600">Real-time business metrics and insights</p>
        </div>

        <div class="header-actions flex gap-3">
            <button wire:click="exportData" class="btn btn-outline">
                Export Report
            </button>
            <button wire:click="refreshDashboard" class="btn btn-primary">
                Refresh Data
            </button>
        </div>
    </div>
@endsection

@section('content')
    <div wire:poll.10s="updateMetrics" class="dashboard-content">
        <div class="metrics-grid grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div class="metric-card bg-white p-6 rounded-lg shadow">
                <h3 class="text-sm text-gray-600 mb-2">Total Revenue</h3>
                <p class="text-3xl font-bold text-green-600">
                    ${{ number_format($metrics['revenue'], 2) }}
                </p>
                <span class="text-xs text-gray-500">
                    {{ $metrics['revenue_change'] }}% from last month
                </span>
            </div>

            <div class="metric-card bg-white p-6 rounded-lg shadow">
                <h3 class="text-sm text-gray-600 mb-2">Active Users</h3>
                <p class="text-3xl font-bold text-blue-600">
                    {{ number_format($metrics['active_users']) }}
                </p>
                <span class="text-xs text-gray-500">
                    {{ $metrics['users_change'] }}% from yesterday
                </span>
            </div>

            <div class="metric-card bg-white p-6 rounded-lg shadow">
                <h3 class="text-sm text-gray-600 mb-2">Conversion Rate</h3>
                <p class="text-3xl font-bold text-purple-600">
                    {{ number_format($metrics['conversion_rate'], 2) }}%
                </p>
                <span class="text-xs text-gray-500">
                    {{ $metrics['conversion_change'] }}% improvement
                </span>
            </div>

            <div class="metric-card bg-white p-6 rounded-lg shadow">
                <h3 class="text-sm text-gray-600 mb-2">Avg. Order Value</h3>
                <p class="text-3xl font-bold text-orange-600">
                    ${{ number_format($metrics['avg_order_value'], 2) }}
                </p>
                <span class="text-xs text-gray-500">
                    {{ $metrics['aov_change'] }}% from last week
                </span>
            </div>
        </div>

        <div wire:loading class="loading-overlay">
            <span>Updating metrics...</span>
        </div>
    </div>
@endsection

@section('sidebar')
    <div class="recent-activity bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold mb-4">Recent Activity</h3>
        <ul class="space-y-3">
            @foreach ($recentActivities as $activity)
                <li class="text-sm">
                    <span class="font-medium">{{ $activity->user }}</span>
                    <span class="text-gray-600">{{ $activity->action }}</span>
                    <span class="text-gray-400 text-xs block">{{ $activity->timestamp }}</span>
                </li>
            @endforeach
        </ul>
    </div>
@endsection

@push('scripts')
    <script src="/js/charts.min.js"></script>
    <script>
        document.addEventListener('livewire:load', function () {
            Livewire.on('metricsUpdated', () => {
                console.log('Dashboard metrics updated');
            });
        });
    </script>
@endpush
