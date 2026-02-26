{{-- Comprehensive kitchen sink: covers as many features and combinations as possible --}}
@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
    {{-- 1. All echo types --}}
    <h1>{{ $title }}</h1>
    <div>{!! $rawHtml !!}</div>
    <pre>{{{ $legacyEscaped }}}</pre>

    {{-- 2. Escaped echo (literal output) --}}
    <p>Use @{{ variable }} in Vue templates</p>

    {{-- 3. @@ literal escape --}}
    <p>Contact us @@ support@@example.com</p>

    {{-- 4. All 7 attribute directives on HTML elements --}}
    <div @class(['container', 'mx-auto' => $centered, 'dark:bg-gray-900' => $darkMode])>
        <input type="text" @style(['color: red' => $hasError, 'font-weight: bold' => $isImportant])>
        <input type="checkbox" @checked($rememberMe)>
        <option value="us" @selected($country === 'us')>United States</option>
        <button @disabled($isSubmitting)>Submit</button>
        <textarea @readonly($isLocked)></textarea>
        <input type="email" @required($needsEmail)>
    </div>

    {{-- 5. Structural directives inside HTML tag heads --}}
    <div
        class="card"
        @if($highlighted)
            style="border: 2px solid gold;"
        @endif
    >
        <p>Card content</p>
    </div>

    {{-- 6. Control structures: if/elseif/else --}}
    @if($user->isAdmin())
        <span class="badge-admin">Admin</span>
    @elseif($user->isModerator())
        <span class="badge-mod">Moderator</span>
    @else
        <span class="badge-user">User</span>
    @endif

    {{-- 7. Loops: foreach, for, while, forelse --}}
    @foreach($items as $item)
        <div class="item" wire:key="item-{{ $item->id }}">
            {{ $item->name }}
            @if($loop->first)
                <span>(first)</span>
            @endif
        </div>
    @endforeach

    @for($i = 0; $i < 10; $i++)
        <span>{{ $i }}</span>
    @endfor

    @while($condition)
        <p>Looping...</p>
    @endwhile

    @forelse($notifications as $notification)
        <div>{{ $notification->message }}</div>
    @empty
        <p>No notifications.</p>
    @endforelse

    {{-- 8. Switch/case --}}
    @switch($role)
        @case('admin')
            <p>Admin panel</p>
            @break
        @case('editor')
            <p>Editor view</p>
            @break
        @default
            <p>Default view</p>
    @endswitch

    {{-- 9. Components: standard, self-closing, with slots --}}
    <x-alert type="warning" :message="$warningMessage" />

    <x-card>
        <x-slot:header>
            <h2>{{ $card->title }}</h2>
        </x-slot>
        <p>{{ $card->body }}</p>
        <x-slot:footer>
            <a href="{{ $card->link }}">Read more</a>
        </x-slot>
    </x-card>

    {{-- 10. Auth/guest/can/cannot/canany --}}
    @auth
        <p>Welcome, {{ auth()->user()->name }}</p>
    @endauth

    @guest
        <a href="/login">Log in</a>
    @endguest

    @can('edit', $post)
        <a href="{{ route('posts.edit', $post) }}">Edit</a>
    @endcan

    @cannot('delete', $post)
        <p>You cannot delete this post.</p>
    @endcannot

    @canany(['edit', 'delete'], $post)
        <div class="actions">Actions available</div>
    @endcanany

    {{-- 11. Unless, isset, empty --}}
    @unless($banned)
        <p>Welcome back!</p>
    @endunless

    @isset($record)
        <p>Record: {{ $record->name }}</p>
    @endisset

    @empty($results)
        <p>No results found.</p>
    @endempty

    {{-- 12. Environment directives --}}
    @env('local')
        <p>Debug toolbar active</p>
    @endenv

    @production
        <script src="/analytics.js"></script>
    @endproduction

    {{-- 13. Error directive --}}
    @error('email')
        <span class="text-red-500">{{ $message }}</span>
    @enderror

    {{-- 14. Include variants --}}
    @include('partials.header')
    @includeIf('partials.sidebar')
    @includeWhen($showBanner, 'partials.banner')
    @includeUnless($hiddenFooter, 'partials.footer')
    @includeFirst(['custom.header', 'default.header'])
    @each('partials.item', $items, 'item', 'partials.empty')

    {{-- 15. Stacks --}}
    @push('scripts')
        <script src="/extra.js"></script>
    @endpush

    @prepend('styles')
        <link href="/extra.css" rel="stylesheet">
    @endprepend

    @pushOnce('scripts')
        <script src="/once.js"></script>
    @endPushOnce

    {{-- 16. Verbatim --}}
    @verbatim
        <div>{{ This is not parsed }}</div>
        @if(literal)
            Not a directive
        @endif
    @endverbatim

    {{-- 17. PHP block --}}
    @php
        $total = array_sum($prices);
    @endphp

    {{-- 18. Once --}}
    @once
        <link href="/once-style.css" rel="stylesheet">
    @endonce

    {{-- 19. Fragment --}}
    @fragment('user-list')
        <ul>
            @foreach($users as $user)
                <li>{{ $user->name }}</li>
            @endforeach
        </ul>
    @endfragment

    {{-- 20. Inline directives: csrf, method, json, vite, dd, dump --}}
    <form method="POST" action="/submit">
        @csrf
        @method('PUT')
        <input type="text" name="title">
    </form>

    @json($data)
    @vite(['resources/css/app.css', 'resources/js/app.js'])

    {{-- 21. Section with @show --}}
    @section('sidebar')
        <nav>Sidebar navigation</nav>
    @show

    {{-- 22. @hasSection / @sectionMissing --}}
    @hasSection('sidebar')
        <div class="has-sidebar">
            @yield('sidebar')
        </div>
    @endif

    @sectionMissing('sidebar')
        <div class="no-sidebar">Full width</div>
    @endif

    {{-- 23. Deeply nested mixed content --}}
    @if($level1)
        <div class="level-1">
            @foreach($items as $item)
                @if($item->visible)
                    <x-list-item :item="$item">
                        @if($item->hasChildren())
                            @foreach($item->children as $child)
                                <span>{{ $child->name }}</span>
                            @endforeach
                        @endif
                    </x-list-item>
                @endif
            @endforeach
        </div>
    @endif
@endsection

@section('scripts')
    <script>
        const appConfig = {!! json_encode($config) !!};
        const userName = '{{ $user->name }}';
        {{-- Initialize the app --}}
        if (appConfig.debug) {
            console.log('Debug mode: {{ $debugLevel }}');
        }
    </script>
@endsection
