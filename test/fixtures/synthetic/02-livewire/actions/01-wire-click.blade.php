{{-- Livewire wire:click action examples --}}
<div>
    {{-- Basic method calls --}}
    <button wire:click="save">Save Post</button>
    <button wire:click="delete">Delete</button>
    <button wire:click="refreshData">Refresh</button>

    {{-- Method calls with parameters --}}
    <button wire:click="addToCart({{ $product->id }})">Add to Cart</button>
    <button wire:click="updateQuantity({{ $item->id }}, 1)">Increase</button>
    <button wire:click="removeItem({{ $cartItem->id }})">Remove</button>

    {{-- Using $event --}}
    <button wire:click="handleClick($event)">Click Me</button>
    <div wire:click="trackPosition($event.clientX, $event.clientY)">
        Track Mouse Position
    </div>

    {{-- Multiple parameters and complex expressions --}}
    <button wire:click="assignRole({{ $user->id }}, 'admin')">
        Make Admin
    </button>
    <button wire:click="updateStatus({{ $order->id }}, 'completed', true)">
        Complete Order
    </button>

    {{-- With loading states --}}
    <button wire:click="processPayment" wire:loading.attr="disabled">
        <span wire:loading.remove wire:target="processPayment">Process Payment</span>
        <span wire:loading wire:target="processPayment">Processing...</span>
    </button>

    {{-- Inline actions --}}
    <button wire:click="$set('showModal', true)">Open Modal</button>
    <button wire:click="$toggle('expanded')">Toggle</button>
    <button wire:click="$refresh">Refresh Component</button>

    {{-- Conditional actions --}}
    <button wire:click="approve({{ $request->id }})" class="btn-success">
        Approve Request
    </button>
    <button wire:click="reject({{ $request->id }}, 'Not qualified')" class="btn-danger">
        Reject Request
    </button>
</div>
