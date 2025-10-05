---
description: "@continue and @break directives for conditional loop control"
tags: ["continue", "break", "loop-control", "filtering"]
---
<div class="order-management">
    <h2>Active Orders Dashboard</h2>

    <div class="order-summary">
        @php
            $displayedOrders = 0;
            $skippedOrders = 0;
        @endphp

        @foreach($orders as $order)
            {{-- Skip cancelled or deleted orders --}}
            @if($order->status === 'cancelled' || $order->deleted_at !== null)
                @php $skippedOrders++; @endphp
                @continue
            @endif

            {{-- Stop after displaying 20 orders --}}
            @if($displayedOrders >= 20)
                @break
            @endif

            @php $displayedOrders++; @endphp

            <article class="order-card status-{{ $order->status }}">
                <header class="order-header">
                    <div class="order-id">
                        <strong>Order #{{ $order->order_number }}</strong>
                        <span class="order-date">{{ $order->created_at->format('M d, Y') }}</span>
                    </div>

                    <div class="order-status">
                        <span class="badge badge-{{ $order->status }}">
                            {{ ucfirst($order->status) }}
                        </span>
                    </div>
                </header>

                <div class="order-items">
                    @foreach($order->items as $item)
                        {{-- Skip items with zero quantity --}}
                        @continue($item->quantity <= 0)

                        <div class="order-item">
                            <img src="{{ $item->product->thumbnail }}" alt="{{ $item->product->name }}">
                            <div class="item-details">
                                <span class="item-name">{{ $item->product->name }}</span>
                                <span class="item-quantity">Qty: {{ $item->quantity }}</span>
                            </div>
                            <span class="item-price">${{ number_format($item->total, 2) }}</span>
                        </div>

                        {{-- Break if we've shown 5 items --}}
                        @if($loop->iteration >= 5)
                            @if($loop->remaining > 0)
                            <div class="more-items">
                                +{{ $loop->remaining }} more items
                            </div>
                            @endif
                            @break
                        @endif
                    @endforeach
                </div>

                <footer class="order-footer">
                    <div class="order-total">
                        <strong>Total:</strong> ${{ number_format($order->total_amount, 2) }}
                    </div>
                    <a href="{{ route('orders.show', $order->id) }}" class="btn btn-sm btn-outline">
                        View Details
                    </a>
                </footer>
            </article>
        @endforeach
    </div>

    @if($skippedOrders > 0)
    <p class="info-message">
        {{ $skippedOrders }} cancelled/deleted orders hidden from view
    </p>
    @endif
</div>
