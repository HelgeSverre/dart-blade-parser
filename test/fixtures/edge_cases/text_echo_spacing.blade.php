{{-- Text + echo spacing stress test --}}
{{-- Tests whitespace between text and echo expressions is preserved --}}

{{-- === INLINE ELEMENTS (single line, kept inline by formatter) === --}}

<p>Name: {{ $name }}</p>
<p>Email: {{ $user->email }}</p>
<p>Total: {{ number_format($total, 2) }}</p>
<span>Status: {{ $order->status }}</span>
<td>{{ $row->id }}</td>
<p>Welcome back, {{ $user->name }}!</p>
<span>{{ $count }} items</span>
<h1>Dashboard - {{ $title }}</h1>
<li>{{ $item->name }}: {{ $item->value }}</li>
<a href="{{ $url }}">{{ $label }}</a>
<p>Hello {{ $name }}, you have {{ $count }} messages</p>
<div>{{ $noLeadingText }}</div>
<div>{{ $value }} items remaining</div>
<div>{{ $a }}{{ $b }}</div>
<div>{{ $a }} {{ $b }}</div>

{{-- === BLOCK ELEMENTS (text + echo on its own line) === --}}

<div>
    Name: {{ $name }}
</div>

<div>
    Email: {{ $user->email }}
</div>

<div>
    HTML: {!! $html !!}
</div>

<div>
    Created: {{ $user->created_at->format('Y-m-d') }}
</div>

<div>
    Tags: {{ implode(', ', $tags) }}
</div>

<div>
    Price ($): {{ $price }}
</div>

<div>
    Result = {{ $result }}
</div>

<div>
    Total:{{ $count }}
</div>

<div>
    Content:{!! $rawContent !!}
</div>

{{-- === @class REGRESSION (GC-Mark) === --}}

<div
    @class([
        'tw-items-center tw-border tw-self-start',
        'tw-bg-red-50 tw-border-red-200' => $isClosingSoon,
        'tw-bg-gray-200 tw-text-gray-900' => ! $isClosingSoon,
    ])
>
    Deadline: {{ $opportunity->human_closing_date }}
</div>

<div
    @class([
        'card',
        'card-active' => $isActive,
    ])
>
    Title: {{ $title }}
</div>

{{-- === DIRECTIVE CONTEXTS === --}}

<div>
    @if($showLabel)
        Label: {{ $label }}
    @endif
</div>

@auth
    Welcome: {{ $user->name }}
@endauth

@isset($notification)
    Alert: {{ $notification->message }}
@endisset

@section('sidebar')
    Navigation: {{ $currentPage }}
@endsection

@foreach($products as $product)
    <div>
        Name: {{ $product->name }}
    </div>
@endforeach

{{-- === MIXED DIRECTIVES AND ECHO === --}}

<div>
    @csrf
    Name: {{ $name }}
    @method('PUT')
    Updated: {{ $updated_at }}
</div>

{{-- === ATTRIBUTE CONTEXT === --}}

<div class="container" data-label="{{ $label }}" @style([
        'color: red' => $hasError,
    ])>
    Error: {{ $errorMessage }}
</div>

{{-- === MULTILINE TEXT ENDING WITH ECHO === --}}

<div>
    This is a longer paragraph of text
    and ends with a value: {{ $value }}
</div>

{{-- === COMPONENT CONTEXT === --}}

<x-card>
    Title: {{ $title }}
</x-card>

<x-alert type="warning">
    Warning: {{ $message }}
</x-alert>
