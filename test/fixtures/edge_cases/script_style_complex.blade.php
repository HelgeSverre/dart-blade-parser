{{-- Complex script and style blocks with Blade expressions --}}

{{-- Script with all echo types and comments --}}
<script>
    // Configuration from server
    const config = {!! json_encode($config) !!};
    const apiUrl = '{{ config("app.url") }}/api';
    const csrfToken = '{{ csrf_token() }}';

    {{-- This comment should be preserved --}}

    // Strings with tricky quoting
    const greeting = "Hello, {{ $user->name }}!";
    const query = '{{ addslashes($searchQuery) }}';
    const template = `Welcome to {{ config('app.name') }}`;

    // Nested braces in JavaScript
    const data = {
        users: {!! $users->toJson() !!},
        settings: {!! json_encode($settings) !!},
    };

    // Conditional JavaScript via Blade
    @if($analytics)
    window.analyticsId = '{{ $analyticsId }}';
    @endif

    // Function with Blade inside
    function initApp() {
        @foreach($plugins as $plugin)
        loadPlugin('{{ $plugin->name }}', {!! json_encode($plugin->config) !!});
        @endforeach
    }
</script>

{{-- Style block with Blade variables --}}
<style>
    :root {
        --primary-color: {{ $primaryColor }};
        --secondary-color: {{ $secondaryColor }};
        --font-family: '{{ $fontFamily }}';
    }

    {{-- Dynamic breakpoint --}}
    @if($customBreakpoint)
    .container {
        max-width: {{ $breakpointWidth }}px;
    }
    @endif

    .brand-bg {
        background-color: {{ $brandColor }};
        color: {{ $brandTextColor }};
    }
</style>

{{-- Textarea (also a raw text element) --}}
<textarea name="template" rows="10">{{ $templateContent }}</textarea>

{{-- Script with complex JavaScript that looks like Blade but isn't --}}
<script>
    // Arrow functions and template literals (${} must not confuse the lexer)
    const render = (items) => {
        return items.map(item => `<div>${item.name}</div>`).join('');
    };

    // Destructuring (braces that aren't echo)
    const userData = {!! json_encode($user->only(['name', 'email'])) !!};

    // Ternary with Blade
    const isAdmin = {{ $user->isAdmin() ? 'true' : 'false' }};

    // Multiple echoes in one statement
    const range = [{{ $min }}, {{ $max }}];
</script>

{{-- Inline style attributes with Blade --}}
<div style="color: {{ $color }}; font-size: {{ $fontSize }}px;">
    Styled content
</div>
