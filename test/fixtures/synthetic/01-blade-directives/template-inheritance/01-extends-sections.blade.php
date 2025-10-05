{{-- Parent Layout: app.blade.php --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Default Application Title')</title>
    <link rel="stylesheet" href="/css/app.css">
    @yield('styles')
</head>
<body class="@yield('body-class', 'default-theme')">
    <header class="main-header">
        <nav class="navbar">
            <div class="logo">
                <a href="/">MyApp</a>
            </div>
            @yield('navigation')
        </nav>
        @yield('header')
    </header>

    <div class="container">
        @yield('breadcrumbs')

        <aside class="sidebar">
            @yield('sidebar', '<p>Default sidebar content</p>')
        </aside>

        <main class="content">
            @yield('content')
        </main>
    </div>

    <footer class="main-footer">
        @yield('footer', '<p>&copy; 2024 MyApp. All rights reserved.</p>')
    </footer>

    <script src="/js/app.js"></script>
    @yield('scripts')
</body>
</html>

{{-- Child Template: dashboard.blade.php --}}
@extends('layouts.app')

@section('title', 'Dashboard - MyApp')

@section('body-class', 'dashboard-page')

@section('navigation')
    <ul class="nav-menu">
        <li><a href="/dashboard">Dashboard</a></li>
        <li><a href="/profile">Profile</a></li>
        <li><a href="/settings">Settings</a></li>
    </ul>
@endsection

@section('header')
    <div class="page-header">
        <h1>Dashboard</h1>
        <p class="subtitle">Welcome back, {{ $user->name }}</p>
    </div>
@endsection

@section('breadcrumbs')
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li><a href="/">Home</a></li>
            <li class="active">Dashboard</li>
        </ol>
    </nav>
@endsection

@section('sidebar')
    <div class="widget">
        <h3>Quick Stats</h3>
        <ul>
            <li>Active Users: {{ $stats['users'] }}</li>
            <li>Total Sales: ${{ $stats['sales'] }}</li>
            <li>Pending Orders: {{ $stats['orders'] }}</li>
        </ul>
    </div>
@endsection

@section('content')
    <div class="dashboard-widgets">
        <div class="widget-grid">
            <div class="widget-card">
                <h2>Recent Activity</h2>
                <ul class="activity-list">
                    @foreach($activities as $activity)
                        <li>{{ $activity->description }}</li>
                    @endforeach
                </ul>
            </div>

            <div class="widget-card">
                <h2>Performance Metrics</h2>
                <div class="metrics">
                    <div class="metric">
                        <span class="label">Revenue</span>
                        <span class="value">${{ number_format($metrics['revenue']) }}</span>
                    </div>
                    <div class="metric">
                        <span class="label">Conversions</span>
                        <span class="value">{{ $metrics['conversions'] }}%</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@section('scripts')
    <script src="/js/chart.js"></script>
    <script>
        initDashboard({
            chartData: @json($chartData)
        });
    </script>
@endsection
