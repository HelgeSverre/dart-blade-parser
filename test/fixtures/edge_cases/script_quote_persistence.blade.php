<script>
    // Multiple Blade expressions across quote boundaries
    const a = "before {{ $x }} after";
    const b = 'between {{ $y }} end';
    const obj = { key: '{{ $z }}', other: "{{ $w }}" };
</script>
<div>between scripts</div>
<script>
    const second = "{{ $second }}";
</script>
