<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" @class(['dark' => ($appearance ?? 'system') == 'dark'])>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        {{-- Inline script to detect system dark mode preference --}}
        <script>
            (function() {
                const appearance = '{{ $appearance ?? "system" }}';
                if (appearance === "system") {
                    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                    if (prefersDark) {
                        document.documentElement.classList.add("dark");
                    }
                }
            })();
        </script>
        @vite('resources/sass/app.scss')
        <title inertia>{{ config('app.name', 'Laravel') }}</title>
        <link href="/favicon.svg" rel="icon" type="image/svg+xml">
        @inertiaHead
    </head>
    <body class="font-sans antialiased">
        @inertia
    </body>
</html>
