---
description: "The @once directive for preventing duplicate asset inclusion in components"
features:
  - "@once directive"
  - "Duplicate prevention"
  - "Component-level assets"
  - "Conditional asset loading"
complexity: low
---
<div class="alert alert-{{ $type ?? 'info' }}">
    <div class="alert-icon">
        @if($type === 'success')
            <svg><!-- success icon --></svg>
        @elseif($type === 'error')
            <svg><!-- error icon --></svg>
        @else
            <svg><!-- info icon --></svg>
        @endif
    </div>

    <div class="alert-content">
        {{ $slot }}
    </div>
</div>

@once
    @push('styles')
    <link rel="stylesheet" href="/css/components/alert.css">
    @endpush

    @push('scripts')
    <script src="/js/components/alert.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            Alert.initialize({
                dismissible: true,
                timeout: 5000
            });
        });
    </script>
    @endpush
@endonce
