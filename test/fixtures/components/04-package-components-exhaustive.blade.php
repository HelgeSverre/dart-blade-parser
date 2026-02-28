{{-- Exhaustive fixture: Package component (::) namespace variations --}}
{{-- Covers every plausible combination of :: components with attributes, slots, bindings, etc. --}}

{{-- ============================================================ --}}
{{-- 1. Self-closing: plain, dotted, deeply dotted --}}
{{-- ============================================================ --}}
<x-nightshade::calendar />
<x-nightshade::calendar.item />
<x-nightshade::calendar.item.index />
<x-filament::button />
<x-mail::message />
<x-dashboard::panel />

{{-- ============================================================ --}}
{{-- 2. With closing tags --}}
{{-- ============================================================ --}}
<x-nightshade::calendar></x-nightshade::calendar>

<x-nightshade::calendar.item>
    <p>Item content</p>
</x-nightshade::calendar.item>

<x-nightshade::calendar.item.index>
    <span>Index content</span>
</x-nightshade::calendar.item.index>

{{-- ============================================================ --}}
{{-- 3. Standard HTML attributes --}}
{{-- ============================================================ --}}
<x-filament::button type="submit" class="w-full bg-blue-500" id="save-btn" />

<x-filament::input
    type="email"
    name="email"
    id="email-field"
    placeholder="Enter your email"
    required
    disabled
/>

<x-nightshade::calendar.item
    class="p-4 rounded-lg shadow"
    style="max-width: 300px;"
    data-testid="calendar-item"
    data-index="0"
    aria-label="Calendar item"
    role="listitem"
>
    Content here
</x-nightshade::calendar.item>

{{-- ============================================================ --}}
{{-- 4. Blade attribute bindings (:attr) --}}
{{-- ============================================================ --}}
<x-filament::button :type="$buttonType" :class="$classes" />

<x-filament::stats
    :columns="$this->getColumns()"
    :data="$chartData"
    :label="$stat->getLabel()"
    :value="$stat->getValue()"
/>

<x-nightshade::calendar.item :date="$event->starts_at" :title="$event->name" />

{{-- ============================================================ --}}
{{-- 5. @class() directive --}}
{{-- ============================================================ --}}
<x-filament::button
    @class([
        'btn btn-primary',
        'btn-lg' => $large,
        'btn-disabled' => $disabled,
        'opacity-50 cursor-not-allowed' => !$active,
    ])
/>

<x-nightshade::calendar
    @class([
        'calendar-widget',
        'calendar-compact' => $compact,
    ])
>
    <p>Calendar body</p>
</x-nightshade::calendar>

{{-- ============================================================ --}}
{{-- 6. @style() directive --}}
{{-- ============================================================ --}}
<x-filament::card
    @style([
        'background-color: red' => $isError,
        'font-weight: bold',
    ])
>
    <p>Card content</p>
</x-filament::card>

{{-- ============================================================ --}}
{{-- 7. Alpine.js attributes --}}
{{-- ============================================================ --}}
<x-filament::modal
    x-data="{ open: false }"
    x-show="open"
    x-transition
    x-on:click="open = !open"
    x-bind:class="{ 'modal-open': open }"
    @click.away="open = false"
    @keydown.escape.window="open = false"
>
    <p>Modal content</p>
</x-filament::modal>

<x-nightshade::dropdown
    x-data="dropdown()"
    x-init="init()"
    x-ref="trigger"
    @click.outside="close()"
/>

{{-- ============================================================ --}}
{{-- 8. Livewire attributes --}}
{{-- ============================================================ --}}
<x-filament::input
    wire:model="email"
    wire:model.live="search"
    wire:model.blur="name"
    wire:model.defer="address"
    wire:loading.class="opacity-50"
    wire:target="save"
/>

<x-filament::button
    wire:click="save"
    wire:click.prevent="submit"
    wire:loading.attr="disabled"
    wire:confirm="Are you sure?"
    class="btn-primary"
>
    Save
</x-filament::button>

<x-nightshade::table
    wire:poll.5s="refreshData"
    wire:key="table-{{ $id }}"
>
    <p>Table content</p>
</x-nightshade::table>

{{-- ============================================================ --}}
{{-- 9. Mixed attribute types on one component --}}
{{-- ============================================================ --}}
<x-filament::input
    type="email"
    name="email"
    id="email-field"
    class="form-input"
    :value="$user->email"
    wire:model.live="form.email"
    x-on:blur="validate('email')"
    @class([
        'border-red-500' => $errors->has('email'),
        'border-green-500' => !$errors->has('email'),
    ])
    required
    placeholder="Enter email"
    aria-describedby="email-help"
    data-testid="email-input"
/>

{{-- ============================================================ --}}
{{-- 10. Default slots --}}
{{-- ============================================================ --}}
<x-filament::card>
    <p>This is default slot content</p>
    <span>More content</span>
</x-filament::card>

<x-filament::button type="submit">
    {{ __('Submit Form') }}
</x-filament::button>

<x-nightshade::calendar.item :date="$date">
    <div class="event-details">
        <h3>{{ $event->title }}</h3>
        <p>{{ $event->description }}</p>
    </div>
</x-nightshade::calendar.item>

{{-- ============================================================ --}}
{{-- 11. Named slots with x-slot:name --}}
{{-- ============================================================ --}}
<x-filament::card>
    <x-slot:header>
        <h2>Card Header</h2>
    </x-slot>

    <p>Card body content</p>

    <x-slot:footer>
        <button>Action</button>
    </x-slot>
</x-filament::card>

<x-nightshade::modal title="Confirm Action">
    <x-slot:trigger>
        <button class="btn">Open Modal</button>
    </x-slot>

    <x-slot:header>
        <h3>Are you sure?</h3>
    </x-slot>

    <p>This action cannot be undone.</p>

    <x-slot:footer>
        <x-filament::button wire:click="confirm">Yes</x-filament::button>
        <x-filament::button wire:click="cancel" class="btn-secondary">No</x-filament::button>
    </x-slot>
</x-nightshade::modal>

{{-- ============================================================ --}}
{{-- 12. Named slots with attributes --}}
{{-- ============================================================ --}}
<x-filament::widget>
    <x-slot:heading class="text-xl font-bold">
        Widget Title
    </x-slot>

    <x-slot:description class="text-gray-500 text-sm">
        A brief description
    </x-slot>

    <p>Widget content</p>
</x-filament::widget>

{{-- ============================================================ --}}
{{-- 13. Deeply nested :: components --}}
{{-- ============================================================ --}}
<x-filament::page>
    <x-filament::widget>
        <x-filament::stats :columns="3">
            <x-filament::stats.stat
                :label="'Users'"
                :value="$userCount"
                :description="'Total registered'"
                :icon="'heroicon-o-users'"
            />
            <x-filament::stats.stat
                :label="'Revenue'"
                :value="$revenue"
                :description="'This month'"
            />
        </x-filament::stats>
    </x-filament::widget>

    <x-filament::card>
        <x-filament::table>
            <x-slot:header>
                <x-filament::table.header-cell>Name</x-filament::table.header-cell>
                <x-filament::table.header-cell>Email</x-filament::table.header-cell>
            </x-slot>
        </x-filament::table>
    </x-filament::card>
</x-filament::page>

{{-- ============================================================ --}}
{{-- 14. :: components inside Blade directives --}}
{{-- ============================================================ --}}
@if($showButton)
    <x-filament::button type="submit">Save</x-filament::button>
@endif

@foreach($items as $item)
    <x-nightshade::calendar.item :date="$item->date" :title="$item->name" />
@endforeach

@auth
    <x-filament::nav.item :href="route('dashboard')" :active="request()->routeIs('dashboard')">
        Dashboard
    </x-filament::nav.item>
@endauth

@forelse($notifications as $notification)
    <x-filament::notification
        :type="$notification->type"
        :message="$notification->message"
        wire:key="notification-{{ $notification->id }}"
    />
@empty
    <x-filament::empty-state icon="heroicon-o-bell" heading="No notifications" />
@endforelse

{{-- ============================================================ --}}
{{-- 15. Echo expressions inside :: components --}}
{{-- ============================================================ --}}
<x-filament::button class="{{ $buttonClass }}">
    {{ $buttonLabel }}
</x-filament::button>

<x-filament::badge color="{{ $status === 'active' ? 'success' : 'danger' }}">
    {{ ucfirst($status) }}
</x-filament::badge>

<x-nightshade::avatar
    src="{{ $user->avatar_url }}"
    alt="{{ $user->name }}"
    class="h-10 w-10 rounded-full {{ $online ? 'ring-2 ring-green-500' : '' }}"
/>

{{-- ============================================================ --}}
{{-- 16. Raw echo {!! !!} inside :: components --}}
{{-- ============================================================ --}}
<x-mail::message>
    {!! $htmlContent !!}
</x-mail::message>

<x-filament::card>
    {!! Str::markdown($body) !!}
</x-filament::card>

{{-- ============================================================ --}}
{{-- 17. Inline text mixed with :: components --}}
{{-- ============================================================ --}}
<p>Click <x-filament::link href="/help">here</x-filament::link> for help.</p>

<span>Status: <x-filament::badge :color="$color">{{ $status }}</x-filament::badge></span>

{{-- ============================================================ --}}
{{-- 18. Multiple different :: namespaces together --}}
{{-- ============================================================ --}}
<x-filament::layout>
    <x-nightshade::sidebar>
        <x-nightshade::nav-item href="/home">Home</x-nightshade::nav-item>
    </x-nightshade::sidebar>

    <x-filament::content>
        <x-mail::button url="{{ route('verify') }}">
            Verify Email
        </x-mail::button>

        <x-dashboard::chart :data="$chartData" />
    </x-filament::content>
</x-filament::layout>

{{-- ============================================================ --}}
{{-- 19. wire:class and dynamic class bindings --}}
{{-- ============================================================ --}}
<x-filament::button
    wire:loading.class="opacity-50 cursor-wait"
    wire:loading.class.remove="hover:bg-blue-600"
    wire:target="save"
>
    Save Changes
</x-filament::button>

<x-nightshade::panel
    x-bind:class="{ 'border-blue-500': selected, 'border-gray-300': !selected }"
    :class="$panelClasses"
>
    Panel content
</x-nightshade::panel>

{{-- ============================================================ --}}
{{-- 20. Boolean and shorthand attributes --}}
{{-- ============================================================ --}}
<x-filament::input type="checkbox" checked disabled readonly />

<x-filament::textarea
    name="bio"
    rows="5"
    autofocus
    required
    :value="$user->bio"
/>
