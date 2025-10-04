---
description: "Basic @include directive with data passing and scoped variables"
features:
  - "@include directive"
  - "Data passing to includes"
  - "Variable scoping"
  - "Partial templates"
complexity: low
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ $pageTitle }}</title>
</head>
<body>
    @include('partials.header', ['user' => $currentUser, 'notifications' => $notifications])

    <main class="container">
        <h1>Welcome, {{ $currentUser->name }}</h1>

        <div class="dashboard-widgets">
            @include('widgets.stats', [
                'totalSales' => $stats['sales'],
                'totalOrders' => $stats['orders'],
                'revenue' => $stats['revenue']
            ])

            @include('widgets.recent-activity', [
                'activities' => $recentActivities,
                'limit' => 10
            ])

            @include('widgets.quick-actions', [
                'actions' => $availableActions
            ])
        </div>

        <div class="content">
            {{ $slot ?? 'No content available' }}
        </div>
    </main>

    @include('partials.footer', ['year' => date('Y'), 'company' => $companyInfo])
</body>
</html>
