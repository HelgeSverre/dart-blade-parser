---
description: "Stack directives for managing asset injection with @push, @prepend, and @stack"
features:
  - "@push directive"
  - "@prepend directive"
  - "@stack directive"
  - "Multiple stack targets"
  - "Scripts and styles management"
complexity: medium
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard - Analytics</title>

    @stack('styles')
</head>
<body>
    <div class="dashboard">
        <h1>Analytics Dashboard</h1>

        <div class="charts">
            <div id="sales-chart"></div>
            <div id="traffic-chart"></div>
        </div>
    </div>

    @stack('scripts')
</body>
</html>

@push('styles')
<link rel="stylesheet" href="/css/charts.css">
<link rel="stylesheet" href="/css/dashboard.css">
@endpush

@prepend('styles')
<link rel="stylesheet" href="/css/base.css">
@endprepend

@push('scripts')
<script src="/js/chart.min.js"></script>
<script>
    new Chart('sales-chart', {
        type: 'line',
        data: @json($salesData)
    });
</script>
@endpush
