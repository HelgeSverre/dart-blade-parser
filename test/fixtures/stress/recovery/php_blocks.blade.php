@php
    $data = collect([1, 2, 3]);
@endphp

<div class="container">
    <?php if ($legacy): ?>
        <p>Legacy PHP block</p>
    <?php endif; ?>

    @foreach($data as $item)
        <span>{{ $item }}</span>
    @else
        <p>Fallback</p>

    <?php echo $unclosed ?>
    <p>After unclosed PHP</p>
</div>

<section>
    <?php
        // Missing closing tag
        $result = compute($data);
    <p>{{ $result }}</p>
</section>
