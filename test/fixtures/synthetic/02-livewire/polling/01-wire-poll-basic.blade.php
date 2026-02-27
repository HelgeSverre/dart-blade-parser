{{-- Livewire wire:poll examples --}}
<div>
    {{-- Default interval (2.5s) --}}
    <div wire:poll>{{ now() }}</div>

    {{-- Call specific action --}}
    <div wire:poll="refreshData">{{ $count }}</div>

    {{-- Custom intervals in seconds --}}
    <div wire:poll.1s>{{ $counter }}</div>
    <div wire:poll.5s>{{ $data }}</div>
    <div wire:poll.15s="checkStatus">{{ $status }}</div>

    {{-- Custom intervals in milliseconds --}}
    <div wire:poll.500ms>{{ $liveData }}</div>
    <div wire:poll.15000ms>{{ $metrics }}</div>

    {{-- keep-alive: continue polling even when tab is in background --}}
    <div wire:poll.keep-alive>{{ $notifications }}</div>

    {{-- visible: only poll when element is visible in viewport --}}
    <div wire:poll.visible>{{ $dashboardData }}</div>

    {{-- Combined interval with keep-alive --}}
    <div wire:poll.5s.keep-alive="refreshNotifications">
        @foreach($notifications as $notification)
            <div wire:key="notif-{{ $notification->id }}">{{ $notification->message }}</div>
        @endforeach
    </div>

    {{-- Combined interval with visible --}}
    <div wire:poll.10s.visible="updateChart">
        <canvas id="chart"></canvas>
    </div>

    {{-- Polling a table of data --}}
    <table wire:poll.3s="fetchLatestOrders">
        <thead>
            <tr>
                <th>Order</th>
                <th>Status</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($orders as $order)
                <tr wire:key="order-{{ $order->id }}">
                    <td>#{{ $order->number }}</td>
                    <td>{{ $order->status }}</td>
                    <td>${{ $order->total }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    {{-- Polling with loading indicator --}}
    <div wire:poll.5s="refreshStats">
        <span wire:loading wire:target="refreshStats" class="text-gray-400">Updating...</span>
        <div wire:loading.remove wire:target="refreshStats">
            <p>Active Users: {{ $activeUsers }}</p>
            <p>Revenue: ${{ $revenue }}</p>
        </div>
    </div>
</div>