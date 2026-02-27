@php
    use App\Models\Company;
    use App\Models\Customer;

    $prefix = $prefix ?? 'Id'.Str::random(3);

    $selected = null;
    if (isset($value)) {
        $customer = Customer::find($value);
        if ($customer && $customer->company->is(Company::current())) {
            $selected = $customer->only(['id', 'name', 'phone', 'email']) + ['url' => route('customers.show', $customer)];
        }
    }
@endphp

<div x-data="entitySelectorHandler{{ $prefix }}()">
    <div>
        <label
            for="{{ $name }}"
            class="block text-sm font-medium text-gray-700"
        >
            {{ $label }}
        </label>
        <div class="flex items-center justify-between">
            <label
                for="customer"
                class="block text-sm font-medium text-gray-700"
            >
                Customer
            </label>

            <button
                class="text-xs text-navy-500"
                wire:click="$dispatch('open.modal', { component: 'customers.form', arguments: @js(['customer' => $selected['id']]) })"
            >
                @if ($selected)
                    <span>Edit</span>
                @else
                    <span>Create</span>
                @endif
            </button>
        </div>
    </div>

    <div>
        <div
            class="relative mt-1"
            x-on:click.outside="open = false"
            x-on:keyup.escape.window="open = false"
            x-trap="open"
        >
            <!-- Search field -->
            <template x-if="selectedEntity == null">
                <div class="relative mt-1 rounded-md shadow-sm">
                    <input
                        x-model.debounce="search"
                        x-on:input="open = true;"
                        type="text"
                        {{ $attributes->whereDoesntStartWith('wire:') }}
                        @class([
                            'block w-full rounded-md border-gray-300 text-sm focus:border-navy-500 focus:ring-navy-500',
                            'border-red-500' => $errors->has($name),
                        ])
                    />

                    <div
                        class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3"
                    >
                        @svg('heroicon-s-question-mark-circle', 'size-5 text-gray-400')
                    </div>
                </div>
            </template>

            <!-- Selected entity -->
            <template x-if="selectedEntity">
                <div
                    class="relative flex w-full select-none justify-between rounded-md border border-gray-200 bg-gray-50 px-4 py-2 text-left text-gray-900"
                >
                    <div>
                        <a
                            x-bind:href="selectedEntity.url"
                            target="_blank"
                            class="block text-sm font-medium text-gray-900 hover:underline"
                            x-text="selectedEntity?.name"
                        ></a>
                        <p
                            class="truncate text-sm text-gray-500"
                            x-text="selectedEntity?.email"
                        ></p>
                        <p
                            class="truncate text-sm text-gray-500"
                            x-text="selectedEntity?.phone"
                        ></p>
                        <input
                            type="hidden"
                            name="{{ $name }}"
                            x-bind:value="selectedEntity?.id"
                        />
                    </div>
                    <div>
                        <button
                            x-on:click="clearSelection"
                            class="cursor-pointer p-2 text-red-600 hover:text-red-500"
                            type="button"
                            tabindex="-1"
                        >
                            <span class="sr-only">Clear selection</span>
                            @svg('heroicon-s-x-mark', 'size-5')
                        </button>
                    </div>
                </div>
            </template>

            <!-- Dropdown items -->
            <div
                x-cloak
                x-show="dropdownVisible"
                x-transition:leave="transition duration-100 ease-in"
                x-transition:leave-start="opacity-100"
                x-transition:leave-end="opacity-0"
                class="absolute z-10 mt-1 max-h-60 w-full divide-y divide-gray-100 overflow-auto rounded-md bg-white p-1 text-sm shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                tabindex="-1"
            >
                <template x-for="entity in entities" :key="entity.id">
                    <button
                        type="button"
                        x-on:click="select(entity)"
                        class="relative block w-full cursor-pointer select-none px-4 py-2 text-left text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-100"
                    >
                        <p
                            class="text-sm font-medium text-gray-900"
                            x-text="entity.name"
                        ></p>
                        <p
                            class="truncate text-sm text-gray-500"
                            x-text="entity.email"
                        ></p>
                        <p
                            class="truncate text-sm text-gray-500"
                            x-text="entity.phone"
                        ></p>
                    </button>
                </template>
            </div>
        </div>
    </div>

    @error($name)
        <div class="text-md text-red-500">{{ $message }}</div>
    @enderror
</div>

<script>
    function entitySelectorHandler{{ $prefix }}() {
        return {
            open: false,
            search: "",
            entities: [],
            selectedEntity: {!! json_encode($selected) !!},
            init() {
                this.$watch('search', () => this.getEntities());
            },

            get dropdownVisible() {
                return this.open && this.search.length && this.entities.length;
            },

            select(entity) {
                this.selectedEntity = entity;
                this.open = false;
                this.search = "";

                @if($attributes->has("wire:model.live"))
                    this.$wire.set("{{ $attributes["wire:model.live"] }}", entity.id)
                @endif
            },

            clearSelection() {
                this.selectedEntity = null;

                @if($attributes->has("wire:model.live"))
                    this.$wire.set("{{ $attributes["wire:model.live"] }}", null)
                @endif
            },

            getEntities() {
                fetch(`/app/ajax/customers?q=${decodeURIComponent(this.search)}`)
                    .then((r) => r.json())
                    .then(data => {
                        this.entities = data;
                    });
            }
        }
    }
</script>
