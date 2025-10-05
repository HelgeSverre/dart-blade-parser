{{-- Dynamic Component Selection --}}
{{-- Component Definitions --}}

{{-- resources/views/components/notifications/success.blade.php --}}
@props(['message', 'dismissible' => true])
<div {{ $attributes->merge(['class' => 'notification success bg-green-100 border-green-500 text-green-900']) }}>
    <svg class="icon">...</svg>
    <span>{{ $message }}</span>
    @if($dismissible)
        <button class="close-btn">&times;</button>
    @endif
</div>

{{-- resources/views/components/notifications/error.blade.php --}}
@props(['message', 'dismissible' => true])
<div {{ $attributes->merge(['class' => 'notification error bg-red-100 border-red-500 text-red-900']) }}>
    <svg class="icon">...</svg>
    <span>{{ $message }}</span>
    @if($dismissible)
        <button class="close-btn">&times;</button>
    @endif
</div>

{{-- Dynamic Component Usage --}}
<div class="notifications-container">
    @php
        $notifications = [
            ['type' => 'success', 'message' => 'Profile updated successfully'],
            ['type' => 'error', 'message' => 'Failed to delete item'],
            ['type' => 'warning', 'message' => 'Your session will expire soon'],
            ['type' => 'info', 'message' => 'New features available']
        ];
    @endphp

    {{-- Dynamic component based on notification type --}}
    @foreach($notifications as $notification)
        <x-dynamic-component
            :component="'notifications.' . $notification['type']"
            :message="$notification['message']"
            class="mb-3"
        />
    @endforeach

    {{-- Dynamic component with conditional rendering --}}
    @if(session()->has('status'))
        <x-dynamic-component
            :component="session('status.type', 'info')"
            :message="session('status.message')"
            :dismissible="true"
        />
    @endif

    {{-- Dynamic component based on user preference --}}
    <x-dynamic-component
        :component="$user->preferredLayoutComponent ?? 'layouts.default'"
        :user="$user"
    >
        <div class="content">
            <h1>Dashboard</h1>
            <p>Welcome back, {{ $user->name }}!</p>
        </div>
    </x-dynamic-component>

    {{-- Dynamic alert component with runtime selection --}}
    @php
        $alertComponent = $isUrgent ? 'alert.urgent' : 'alert.standard';
    @endphp

    <x-dynamic-component
        :component="$alertComponent"
        title="Important Notice"
        :data="$alertData"
        class="mt-6"
    >
        This is a dynamically selected alert component.
    </x-dynamic-component>
</div>
