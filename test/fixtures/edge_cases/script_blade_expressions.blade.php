<script>
    const config = {!! json_encode($config) !!};
    const name = '{{ $name }}';
    {{-- TODO: remove this --}}
    const items = {!! $items !!};
    if (config.debug) {
        console.log('{{ $debugMessage }}');
    }
</script>
<style>
    body { color: {{ $color }}; }
    .dark { background: {{ $bgColor }}; }
</style>
