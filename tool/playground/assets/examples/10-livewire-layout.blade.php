<!DOCTYPE html>
<html lang="en" class="h-full">
    <head>
        <meta charset="UTF-8" />
        <meta
            name="viewport"
            content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0"
        />
        <meta http-equiv="X-UA-Compatible" content="ie=edge" />

        <x-partials.favicons />
        <x-partials.tracking />

        @isset($title)
            <title>{{ $title }} - {{ config('app.name') }}</title>
        @else
            <title>{{ config('app.name') }}</title>
        @endisset

        @googlefonts('sans')
        @googlefonts('mono')

        <style>
            [x-cloak] {
                display: none !important;
            }
        </style>

        <!-- Scripts -->
        @vite(['resources/css/app.css', 'resources/js/app.js'])

        <!-- Styles -->
        @filamentStyles
        @livewireStyles
    </head>
    <body class="h-full bg-white antialiased">
        <x-ui.trial-banner />

        <div class="md:mx-4">
            <x-ui.navbar />
        </div>

        <div class="mt-6 pb-40 sm:py-8">
            <div class="mx-auto max-w-7xl">
                <div class="flex flex-col sm:flex-row sm:gap-6">
                    <div
                        class="flex w-20 flex-col items-start gap-y-6 sm:-ml-2 sm:w-auto"
                    >
                        <x-menu />
                    </div>

                    <div class="w-full min-w-0 px-4 lg:col-span-3 lg:mx-auto">
                        {{ $slot }}
                    </div>
                </div>
            </div>
        </div>

        @filamentScripts
        @livewireScriptConfig
        @livewire('notifications')

        @lemonJS

        <livewire:database-notifications />
        <x-impersonate::banner />
    </body>
</html>
