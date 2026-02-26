{{-- All valid PHP opening tag variants --}}

{{-- Standard PHP tag --}}
<?php
$greeting = 'Hello, World!';
echo $greeting;
?>

{{-- Short echo tag (always available since PHP 5.4) --}}
<p>Name: <?= $name ?></p>
<p>Email: <?= htmlspecialchars($email) ?></p>

{{-- Short open tag (requires short_open_tag, deprecated 7.4) --}}
<? $x = 42; ?>

{{-- Blade @php directive --}}
@php
    $total = $items->sum('price');
    $formatted = number_format($total, 2);
@endphp

{{-- Inline @php expression --}}
@php($now = now())

<div>
    <span>Total: {{ $formatted }}</span>
</div>
