{{-- Fixture: Package component namespace (::) syntax --}}
{{-- Covers Issue #3: <x-filament::button /> was incorrectly formatted as <x-filament : :button /> --}}

{{-- Self-closing package components --}}
<x-filament::button />

<x-nightshade::calendar />

<x-mail::message />

{{-- Package component with attributes --}}
<x-filament::button type="submit" class="w-full" />

{{-- Package component with children --}}
<x-filament::button type="submit">
    {{ __('Login') }}
</x-filament::button>

{{-- Nested package components --}}
<x-filament::widget class="filament-stats-overview-widget">
    <x-filament::stats :columns="$this->getColumns()">
        @foreach ($this->getStats() as $stat)
            <x-filament::stats.stat
                :label="$stat->getLabel()"
                :value="$stat->getValue()"
                :description="$stat->getDescription()"
            />
        @endforeach
    </x-filament::stats>
</x-filament::widget>

{{-- Package component with closing tag matching namespace --}}
<x-filament::pages.actions.action
    :action="$action"
    component="filament::dropdown.list.item"
>
    {{ $action->getLabel() }}
</x-filament::pages.actions.action>

{{-- Namespace + dot combined --}}
<x-package::nested.component />

<x-namespace::deep.nested.component />

{{-- Mail package components --}}
<x-mail::button url="https://example.com">
    Click Here
</x-mail::button>

{{-- Dashboard components --}}
<x-dashboard::panel title="Overview">
    <p>Content goes here</p>
</x-dashboard::panel>
