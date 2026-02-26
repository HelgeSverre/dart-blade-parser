{{-- Real-world dashboard page combining many features --}}
@extends('layouts.app')

@section('title', __('Dashboard'))

@push('styles')
    <style>
        .stat-card { transition: transform 0.2s; }
        .stat-card:hover { transform: translateY(-2px); }
        .chart-container { min-height: {{ $chartHeight ?? 300 }}px; }
    </style>
@endpush

@section('content')
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {{-- Page header with breadcrumbs --}}
        <div class="flex items-center justify-between py-6">
            <div>
                <h1 class="text-2xl font-bold text-gray-900">{{ __('Dashboard') }}</h1>
                <p class="mt-1 text-sm text-gray-500">
                    {{ __('Welcome back, :name', ['name' => auth()->user()->name]) }}
                </p>
            </div>

            @can('export', App\Models\Report::class)
                <div x-data="{ exporting: false }">
                    <button
                        wire:click="export"
                        x-on:click="exporting = true"
                        x-bind:disabled="exporting"
                        @class(['btn btn-primary', 'opacity-50 cursor-wait' => false])
                    >
                        <span x-show="!exporting">{{ __('Export') }}</span>
                        <span x-show="exporting" x-cloak>{{ __('Exporting...') }}</span>
                    </button>
                </div>
            @endcan
        </div>

        {{-- Stats grid --}}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            @foreach($stats as $stat)
                <div
                    class="stat-card bg-white rounded-lg shadow p-6"
                    wire:key="stat-{{ $stat->key }}"
                >
                    <div class="flex items-center">
                        <div @class([
                            'p-3 rounded-full',
                            'bg-green-100 text-green-600' => $stat->trend === 'up',
                            'bg-red-100 text-red-600' => $stat->trend === 'down',
                            'bg-gray-100 text-gray-600' => $stat->trend === 'flat',
                        ])>
                            <x-icon :name="$stat->icon" class="w-6 h-6" />
                        </div>
                        <div class="ml-4">
                            <p class="text-sm font-medium text-gray-500">{{ $stat->label }}</p>
                            <p class="text-2xl font-semibold text-gray-900">{{ $stat->formatted_value }}</p>
                        </div>
                    </div>
                    @if($stat->change !== null)
                        <div class="mt-4 flex items-center text-sm">
                            @if($stat->trend === 'up')
                                <span class="text-green-600">↑ {{ $stat->change }}%</span>
                            @elseif($stat->trend === 'down')
                                <span class="text-red-600">↓ {{ $stat->change }}%</span>
                            @else
                                <span class="text-gray-500">— {{ $stat->change }}%</span>
                            @endif
                            <span class="ml-2 text-gray-400">{{ __('vs last period') }}</span>
                        </div>
                    @endif
                </div>
            @endforeach
        </div>

        {{-- Main content: chart + recent activity --}}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {{-- Chart --}}
            <div class="lg:col-span-2 bg-white rounded-lg shadow">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h2 class="text-lg font-medium">{{ __('Revenue Overview') }}</h2>
                        <select
                            wire:model.live="chartPeriod"
                            class="text-sm border-gray-300 rounded-md"
                        >
                            <option value="7d">{{ __('Last 7 days') }}</option>
                            <option value="30d" @selected($chartPeriod === '30d')>{{ __('Last 30 days') }}</option>
                            <option value="90d" @selected($chartPeriod === '90d')>{{ __('Last 90 days') }}</option>
                        </select>
                    </div>
                </div>
                <div class="p-6 chart-container" wire:ignore>
                    <canvas id="revenueChart"></canvas>
                </div>
            </div>

            {{-- Recent activity --}}
            <div class="bg-white rounded-lg shadow" wire:poll.30s="refreshActivity">
                <div class="p-6 border-b border-gray-200">
                    <h2 class="text-lg font-medium">{{ __('Recent Activity') }}</h2>
                </div>
                <div class="divide-y divide-gray-200">
                    @forelse($activities as $activity)
                        <div class="p-4 flex items-start space-x-3" wire:key="activity-{{ $activity->id }}">
                            <x-avatar :user="$activity->user" size="sm" />
                            <div class="flex-1 min-w-0">
                                <p class="text-sm text-gray-900">
                                    <span class="font-medium">{{ $activity->user->name }}</span>
                                    {{ $activity->description }}
                                </p>
                                <p class="text-xs text-gray-500">
                                    {{ $activity->created_at->diffForHumans() }}
                                </p>
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-gray-500">
                            <x-icon name="heroicon-o-clock" class="mx-auto h-8 w-8 mb-2" />
                            <p>{{ __('No recent activity') }}</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>

        {{-- Data table --}}
        @isset($orders)
            <div class="mt-8 bg-white rounded-lg shadow overflow-hidden">
                <div class="p-6 border-b border-gray-200 flex items-center justify-between">
                    <h2 class="text-lg font-medium">{{ __('Recent Orders') }}</h2>
                    <div class="flex items-center space-x-4">
                        <input
                            type="search"
                            wire:model.live.debounce.300ms="orderSearch"
                            placeholder="{{ __('Search orders...') }}"
                            class="text-sm border-gray-300 rounded-md"
                        >
                        @can('create', App\Models\Order::class)
                            <a href="{{ route('orders.create') }}" class="btn btn-sm btn-primary">
                                {{ __('New Order') }}
                            </a>
                        @endcan
                    </div>
                </div>
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {{ __('Order') }}
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {{ __('Customer') }}
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {{ __('Status') }}
                            </th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {{ __('Total') }}
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach($orders as $order)
                            <tr wire:key="order-{{ $order->id }}" @class(['bg-yellow-50' => $order->requiresAttention()])>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <a href="{{ route('orders.show', $order) }}" class="text-indigo-600 hover:text-indigo-900">
                                        #{{ $order->number }}
                                    </a>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $order->customer->name }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <x-badge :color="$order->status_color">
                                        {{ $order->status_label }}
                                    </x-badge>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-right">
                                    {{ $order->formatted_total }}
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
                @if($orders->hasPages())
                    <div class="px-6 py-3 border-t border-gray-200">
                        {{ $orders->links() }}
                    </div>
                @endif
            </div>
        @endisset
    </div>
@endsection

@push('scripts')
    <script>
        const chartData = {!! json_encode($chartData) !!};
        {{-- Chart initialization --}}
        document.addEventListener('DOMContentLoaded', function() {
            const ctx = document.getElementById('revenueChart').getContext('2d');
            new Chart(ctx, {
                type: 'line',
                data: chartData,
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });
        });
    </script>
@endpush
