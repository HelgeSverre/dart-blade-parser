<x-slot name="title">
    {{ $contact->name }}
</x-slot>

<x-layouts.page>
    <x-slot name="actions">
        <x-layouts.breadcrumb-links
            :links="
                [
                    ['label' => 'Contacts', 'url' => route('contacts.index')],
                    ['label' => $contact->name, 'url' => route('contacts.show', $contact)],
                ]
            "
        />

        <x-layouts.actions>
            <x-slot name="left">
                <x-contoso.detail-strip>
                    @if ($contact->type)
                        <x-contoso.detail-strip-item
                            label="Type"
                            :value="$contact->type->name"
                        />
                    @endif

                    @if ($contact->title)
                        <x-contoso.detail-strip-item
                            label="Title"
                            :value="$contact->title"
                        />
                    @endif

                    @if ($contact->company_name)
                        <x-contoso.detail-strip-item
                            label="Company"
                            :value="$contact->company_name"
                        />
                    @endif

                    <x-contoso.detail-strip-item
                        label="Created"
                        :value="$contact->created_at->format('Y-m-d')"
                    />

                    <x-contoso.detail-strip-item
                        label="Updated"
                        :value="$contact->updated_at->format('Y-m-d')"
                    />
                </x-contoso.detail-strip>
            </x-slot>

            <x-slot name="right">
                <x-contoso.action-button
                    action="editContactAction"
                    variant="primary"
                >
                    Edit
                </x-contoso.action-button>
            </x-slot>
        </x-layouts.actions>
    </x-slot>

    <main>
        <div
            class="mx-auto grid max-w-3xl grid-cols-1 gap-6 px-4 sm:mt-8 sm:px-6 lg:max-w-7xl lg:grid-flow-col-dense lg:grid-cols-3"
        >
            <div class="space-y-6 lg:col-span-2 lg:col-start-1">
                @if ($contact->notes)
                    <x-panel heading="Notes" :collapsible="true">
                        <div class="prose prose-sm max-w-none">
                            {!! nl2br(e($contact->notes)) !!}
                        </div>
                    </x-panel>
                @endif

                <livewire:comments
                    wire:key="comments-contact-{{ $contact->id }}"
                    :commentable="$contact"
                    :allow-attachments="true"
                    :allow-multiple-attachments="true"
                />
            </div>

            <!-- Sidebar -->
            <section class="row-start-1 space-y-6 lg:col-span-1 lg:col-start-3">
                <x-panel heading="Contact Details" :collapsible="true">
                    <x-contoso.data-list :cols="1">
                        @if (! empty($contact->emails))
                            <x-contoso.data-list.item
                                label="Email{{ count($contact->emails) > 1 ? 's' : '' }}"
                                :value="implode(', ', $contact->emails)"
                                :href="'mailto:'.implode(',', $contact->emails)"
                            />
                        @endif

                        @if ($contact->phone)
                            <x-contoso.data-list.item
                                label="Phone"
                                :value="$contact->phone"
                                :href="'tel:'.$contact->phone"
                            />
                        @endif

                        @if ($contact->mobile)
                            <x-contoso.data-list.item
                                label="Mobile"
                                :value="$contact->mobile"
                                :href="'tel:'.$contact->mobile"
                            />
                        @endif

                        @if ($contact->department)
                            <x-contoso.data-list.item
                                label="Department"
                                :value="$contact->department"
                            />
                        @endif

                        @if ($contact->address || $contact->city || $contact->postal_code || $contact->country)
                            <x-contoso.data-list.item label="Address">
                                @if ($contact->address)
                                    <div>{{ $contact->address }}</div>
                                @endif

                                @if ($contact->postal_code || $contact->city)
                                    <div>
                                        {{ $contact->postal_code }}
                                        {{ $contact->city }}
                                    </div>
                                @endif

                                @if ($contact->country)
                                    <div>{{ $contact->country }}</div>
                                @endif
                            </x-contoso.data-list.item>
                        @endif

                        @if ($contact->is_active !== null)
                            <x-contoso.data-list.item label="Status">
                                <x-ui.badge
                                    type="{{ $contact->is_active ? 'green' : 'red' }}"
                                >
                                    {{ $contact->is_active ? 'Active' : 'Inactive' }}
                                </x-ui.badge>
                            </x-contoso.data-list.item>
                        @endif
                    </x-contoso.data-list>
                </x-panel>

                @php
                    $associations = $contact->getAssociations();
                @endphp

                @if ($associations->isNotEmpty())
                    <x-panel heading="Linked Records" :collapsible="true">
                        <div class="space-y-2">
                            @foreach ($associations as $association)
                                <div class="flex items-center justify-between">
                                    <a
                                        wire:navigate
                                        href="{{ $contact->associationUrl($association) }}"
                                        class="text-sm text-navy-600 hover:text-navy-800 hover:underline"
                                    >
                                        {{ $contact->associationLabel($association) }}
                                    </a>
                                    @if (method_exists($association, 'pivot') && $association->pivot && $association->pivot->is_primary)
                                        <x-ui.badge type="green" class="ml-2">
                                            Primary
                                        </x-ui.badge>
                                    @endif
                                </div>
                            @endforeach
                        </div>
                    </x-panel>
                @endif

                @env('local')
                    @if ($contact->notify_email || $contact->notify_sms || $contact->notify_push)
                        <x-panel
                            heading="Notification Preferences"
                            :collapsible="true"
                        >
                            <x-contoso.data-list :cols="1" gap="3">
                                <x-contoso.data-list.item label="Email Notifications">
                                    <x-ui.badge
                                        type="{{ $contact->notify_email ? 'green' : 'gray' }}"
                                    >
                                        {{ $contact->notify_email ? 'Enabled' : 'Disabled' }}
                                    </x-ui.badge>
                                </x-contoso.data-list.item>

                                <x-contoso.data-list.item label="SMS Notifications">
                                    <x-ui.badge
                                        type="{{ $contact->notify_sms ? 'green' : 'gray' }}"
                                    >
                                        {{ $contact->notify_sms ? 'Enabled' : 'Disabled' }}
                                    </x-ui.badge>
                                </x-contoso.data-list.item>

                                <x-contoso.data-list.item label="Push Notifications">
                                    <x-ui.badge
                                        type="{{ $contact->notify_push ? 'green' : 'gray' }}"
                                    >
                                        {{ $contact->notify_push ? 'Enabled' : 'Disabled' }}
                                    </x-ui.badge>
                                </x-contoso.data-list.item>
                            </x-contoso.data-list>
                        </x-panel>
                    @endif
                @endenv
            </section>
        </div>
    </main>

    <x-filament-actions::modals />
</x-layouts.page>
