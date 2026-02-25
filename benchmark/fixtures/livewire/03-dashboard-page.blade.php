<x-slot name="scripts">
    <script src="https://maps.googleapis.com/maps/api/js?key={{ config('services.maps.api_key') }}&libraries=places"></script>
</x-slot>

<x-layouts.page>
    <x-slot name="actions">
        <x-layouts.breadcrumb-links
            :links="
                [
                    [
                        'label' => 'Resources',
                        'url' => route('resources.index'),
                    ],
                ]
            "
        />

        <x-layouts.actions>
            <x-slot name="left">
                <x-app.filters :sortings="$this->filters()" />
            </x-slot>

            <x-slot name="right">
                <x-app.search />

                <x-app.action-button
                    href="{{ route('resources.uptime') }}"
                    x-data
                    x-tooltip.raw="Show resource uptime"
                >
                    <x-lucide-history class="size-4" />
                </x-app.action-button>

                <x-app.action-button
                    href="{{ route('resources.log-table') }}"
                    x-data
                    x-tooltip.raw="Show all resource events"
                >
                    <x-lucide-logs class="size-4" />
                </x-app.action-button>

                <x-app.action-button
                    wire:click="toggleMap"
                    x-data
                    x-tooltip.raw="{{ $showMap ? 'Hide map' : 'Show resources on map'  }}"
                >
                    @if ($showMap)
                        <x-lucide-map-pin-off class="size-4" />
                    @else
                        <x-lucide-map-pin class="size-4" />
                    @endif
                </x-app.action-button>

                <x-app.action-button action="createLogEntryAction">
                    Log Event
                </x-app.action-button>

                <x-app.action-button
                    variant="primary"
                    wire:click="refresh"
                    x-data
                    x-tooltip.raw="Last updated: {{ $this->lastUpdatedAt?->diffForHumans() ?: 'unknown' }}"
                >
                    Refresh
                </x-app.action-button>

                @if (\App\Enums\Permission::manageResources->isAllowed() || Auth::user()->isSuperAdmin())
                    <x-app.action-button
                        variant="primary"
                        :href="route('resources.create')"
                        x-data
                        x-tooltip.raw="Add new resource"
                    >
                        <x-lucide-plus class="size-4" />
                    </x-app.action-button>
                @endif
            </x-slot>
        </x-layouts.actions>
    </x-slot>

    @if ($showMap)
        <div class="mb-12">
            <x-app::resource-map
                :resources="$this->resourcesWithLocation"
            />
        </div>
    @endif

    <div
        class="flex flex-col gap-12 duration-200"
        wire:target="refresh"
        wire:loading.class="opacity-50"
    >
        @if ($this->inactiveResources->isNotEmpty())
            <div>
                <div class="mb-4">
                    <h2 class="text-base font-semibold text-gray-700">
                        Inactive Resources
                    </h2>
                    <p class="text-sm text-gray-600">
                        Here you can see an overview of all currently inactive
                        resources.
                    </p>
                </div>

                <div
                    class="grid gap-2 sm:grid-cols-2 md:gap-4 xl:grid-cols-3 2xl:grid-cols-4"
                >
                    @foreach ($this->inactiveResources as $resource)
                        <x-app::resource-card
                            :resource="$resource"
                            :usagePerCycle="$this->usagePerCycleByResource[$resource->id] ?? null"
                        />
                    @endforeach
                </div>
            </div>
        @endif

        @if ($this->activeResources->isNotEmpty())
            <div>
                <div class="mb-4">
                    <h2 class="text-base font-semibold text-gray-700">
                        Active Resources
                    </h2>
                    <p class="text-sm text-gray-600">
                        Here you can see an overview of all active resources.
                    </p>
                </div>

                <div
                    class="grid gap-2 sm:grid-cols-2 md:gap-4 xl:grid-cols-3 2xl:grid-cols-4"
                >
                    @foreach ($this->activeResources as $resource)
                        <x-app::resource-card
                            :resource="$resource"
                            :usagePerCycle="$this->usagePerCycleByResource[$resource->id] ?? null"
                        />
                    @endforeach
                </div>
            </div>
        @endif
    </div>

    <x-filament-actions::modals />
</x-layouts.page>
