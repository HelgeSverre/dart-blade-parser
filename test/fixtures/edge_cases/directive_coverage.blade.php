{{-- Directive coverage: tests all official Laravel 12.x + Livewire directives --}}

{{-- Issue #1: @slot/@endslot (legacy component directive syntax) --}}
@component('alert')
    @slot('title')
        <h1>Alert Title</h1>
    @endslot
    <p>Alert body content</p>
@endcomponent

{{-- Issue #2: @context/@endcontext (Laravel 12.x) --}}
@context('canonical')
    <link href="{{ $value }}" rel="canonical">
@endcontext

{{-- Issue #3: @hasStack closes with @endif --}}
@hasStack('scripts')
    <ul>
        @stack('scripts')
    </ul>
@endif

{{-- Issue #4: @teleport/@endTeleport (Livewire 3.x) --}}
@teleport('body')
    <div x-show="open" class="modal-backdrop">
        <div class="modal">
            <p>Modal content</p>
        </div>
    </div>
@endTeleport

{{-- Issue #5: @persist/@endPersist (Livewire 3.x) --}}
@persist('player')
    <audio src="{{ $episode->url }}" controls></audio>
@endPersist

{{-- Issue #6: @stop (section alias for @endsection) --}}
@section('sidebar')
    <nav>Sidebar navigation</nav>
@stop

{{-- Issue #7: @append (section closer that appends) --}}
@section('scripts')
    <script src="/custom.js"></script>
@append

{{-- Nested: @teleport inside @if --}}
@if($showModal)
    @teleport('body')
        <div class="overlay">
            <div class="modal">
                <p>{{ $modalContent }}</p>
            </div>
        </div>
    @endTeleport
@endif

{{-- Nested: @persist with conditional --}}
@auth
    @persist('dashboard-player')
        <audio src="{{ $track->url }}" controls></audio>
    @endPersist
@endauth

{{-- @context inside a component --}}
<x-layout>
    @context('canonical')
        <link href="{{ $value }}" rel="canonical">
    @endcontext

    <main>
        {{ $slot }}
    </main>
</x-layout>
