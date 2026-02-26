@script
    <script>
        window.addEventListener(
            'message',
            function (e) {
                const iframe = document.getElementById(e.data.iframeId);
                iframe.style.height = e.data.height + 'px';
            },
            false,
        );
    </script>
@endscript

<x-layouts.page>
    <x-slot name="actions">
        <x-layouts.breadcrumbs>
            <div class="flex w-full items-center justify-between">
                <div class="mr-2 shrink">
                    <div class="flex items-center justify-center text-gray-700">
                        <livewire:watcher
                            :watchable="$ticket"
                            size="5"
                            wire:key="watcher-{{ $ticket->id }}"
                        />
                    </div>
                </div>

                <div class="flex-1">
                    {{ $ticket->displayTitle() }}
                </div>

                @if (\App\Modules\Contoso\Gateway::hasAccess())
                    <div cols="ml-auto mr-4">
                        <x-contoso.loader wire:target="refreshExternalData">
                            Refreshing external data
                        </x-contoso.loader>
                    </div>
                @endif

                <div
                    class="ml-auto cursor-pointer"
                    x-data
                    x-tooltip.raw="{{ $ticket->updated_at->diffForHumans() }}"
                >
                    Last updated
                    {{ $ticket->updated_at->format('Y-m-d H:i') }}
                </div>
            </div>
        </x-layouts.breadcrumbs>

        <x-layouts.actions>
            <x-slot name="left">
                <x-contoso.detail-strip>
                    @if ($ticket->statusEnum())
                        <x-contoso.detail-strip-item>
                            <x-contoso.badge
                                :label="$ticket->statusEnum()->label()"
                                :color="$ticket->statusEnum()->color()"
                            />
                        </x-contoso.detail-strip-item>
                    @endif

                    @if ($ticket->customer)
                        <x-contoso.detail-strip-item
                            label="Customer"
                            url="{{ route('customers.show', $ticket->customer) }}"
                            value="{{ $ticket->customer->name }}"
                        />
                    @endif

                    @if ($ticket->source)
                        <x-contoso.detail-strip-item
                            label="Source"
                            value="{{ $ticket->source->getLabel() }}"
                        />
                    @endif

                    <x-contoso.detail-strip-item
                        label="Created"
                        value="{{ $ticket->created_at->format('Y-m-d') }}"
                    />

                    @if ($ticket->user)
                        <x-contoso.detail-strip-item
                            label="Created By"
                            value="{{ $ticket->user->name }}"
                        />
                    @endif

                    @if ($ticket->tags->isNotEmpty())
                        <x-contoso.detail-strip-item>
                            <div class="flex flex-wrap gap-1.5 gap-x-1">
                                @foreach ($ticket->tags as $tag)
                                    <x-ui.badge type="blue">
                                        {{ $tag->name }}
                                    </x-ui.badge>
                                @endforeach
                            </div>
                        </x-contoso.detail-strip-item>
                    @endif
                </x-contoso.detail-strip>
            </x-slot>

            <x-slot name="right">
                <x-contoso.action-button
                    wire:click="mountAction('assignUsersAction', { ticket_id: {{ $ticket->id }} })"
                    tooltip="Assign this ticket to one or more users"
                >
                    <x-heroicon-m-user-plus
                        class="-mr-1 size-5 text-gray-500"
                    />
                </x-contoso.action-button>

                <x-contoso.action-button
                    type="button"
                    wire:click="mountAction('tagAction')"
                    tooltip="Add or remove tags"
                >
                    <x-heroicon-m-tag class="-mx-1 size-5 text-gray-500" />
                </x-contoso.action-button>

                <x-contoso.listbox
                    tooltip="Status"
                    :enum="\App\Enums\TicketStatus::class"
                    :value="$ticket->statusEnum()"
                    placeholder="Status"
                    x-on:input="$wire.changeStatus($event.detail)"
                />

                <x-contoso.action-button
                    variant="primary"
                    modal="tickets.form"
                    :modal-params="['ticket' => $ticket->id]"
                >
                    Edit
                </x-contoso.action-button>

                @if (\App\Enums\Permission::deleteTickets->isAllowed())
                    <x-contoso.action-button
                        variant="danger"
                        wire:confirm="Are you sure you want to delete this ticket?"
                        wire:click="delete"
                    >
                        Delete
                    </x-contoso.action-button>
                @endif
            </x-slot>
        </x-layouts.actions>
    </x-slot>

    <main>
        <div
            class="grid grid-cols-1 gap-6 lg:grid-flow-col-dense lg:grid-cols-3"
        >
            <div class="space-y-6 lg:col-span-2 lg:col-start-1">
                @unless ($ticket->source == \App\Enums\TicketSource::inboundEmail)
                    <x-panel
                        heading="Description"
                        key="ticket-description"
                        :collapsible="true"
                    >
                        <div>
                            {!! nl2br(strip_tags($ticket->description)) !!}
                        </div>
                    </x-panel>
                @endunless

                {{-- Message Thread --}}
                <x-panel heading="Messages" key="ticket-messages">
                    <div class="flow-root">
                        <ul role="list" class="-mb-8">
                            @foreach ($messages as $index => $message)
                                <li x-data="{ open: {{ $index === count($messages) - 1 ? 'true' : 'false' }} }">
                                    <div class="relative pb-8">
                                        @if (! $loop->last)
                                            <span
                                                class="absolute left-3 top-5 -ml-px h-full w-0.5 bg-gray-200"
                                                aria-hidden="true"
                                            ></span>
                                        @endif

                                        <div class="relative flex items-start space-x-3">
                                            <img
                                                src="{{ $message['avatar'] ?? 'https://ui-avatars.com/api/?name='.urlencode($message['who']) }}"
                                                alt="{{ $message['who'] }}"
                                                class="relative mt-3 size-6 flex-none rounded-full bg-gray-50"
                                            />
                                            <div
                                                class="flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200"
                                            >
                                                <div class="flex justify-between gap-x-4">
                                                    <div
                                                        class="py-0.5 text-xs leading-5 text-gray-500"
                                                    >
                                                        <span
                                                            class="font-medium text-gray-900"
                                                        >
                                                            {{ $message['who'] }}
                                                        </span>
                                                        <span>wrote</span>
                                                    </div>

                                                    <x-contoso.button-group>
                                                        @if ($message['date'] ?? false)
                                                            <time
                                                                x-tooltip.raw="{{ $message['date']->diffForHumans() }}"
                                                                datetime="{{ $message['date']->toIso8601String() }}"
                                                                class="flex-none py-0.5 text-xs leading-5 text-gray-500"
                                                                title="Message ID: {{ $message['id'] }}"
                                                            >
                                                                {{ $message['date']->format('Y-m-d H:i') }}
                                                            </time>
                                                        @endif

                                                        <x-button.chevron
                                                            x-on:click="open = !open"
                                                        />
                                                    </x-contoso.button-group>
                                                </div>

                                                <div x-show="open" x-collapse="open">
                                                    @if ($message['type'] == 'inbound' && isset($message['iframe']) && filled($message['iframe']))
                                                        <div>
                                                            <iframe
                                                                id="{{ $message['id'] ?? '' }}"
                                                                src="{{ $message['iframe'] ?? '' }}"
                                                                frameborder="0"
                                                                class="max-h-[1000px] w-full overflow-y-scroll"
                                                                scrolling="true"
                                                                wire:ignore
                                                            ></iframe>
                                                        </div>
                                                    @else
                                                        <div
                                                            class="prose prose-sm text-sm leading-tight text-gray-500"
                                                        >
                                                            {!! $message['content'] !!}
                                                        </div>
                                                    @endif

                                                    @if (isset($message['attachments']) && filled($message['attachments']))
                                                        <div class="mt-4">
                                                            <dt
                                                                class="text-xs font-medium text-gray-500"
                                                            >
                                                                Attachments
                                                            </dt>
                                                            <dd
                                                                class="mt-1.5 text-sm text-gray-900"
                                                            >
                                                                <div
                                                                    role="list"
                                                                    class="divide-y divide-gray-200 rounded-md border border-gray-200"
                                                                >
                                                                    @foreach ($message['attachments'] as $attachment)
                                                                        <div
                                                                            class="flex items-center justify-between py-3 pl-4 pr-5"
                                                                        >
                                                                            <div
                                                                                class="flex w-0 flex-1 items-center"
                                                                            >
                                                                                <x-heroicon-m-paper-clip
                                                                                    class="size-5 flex-shrink-0 text-gray-400"
                                                                                />
                                                                                <div
                                                                                    class="ml-4 flex min-w-0 flex-1 gap-2"
                                                                                >
                                                                                    <span
                                                                                        class="truncate font-medium"
                                                                                    >
                                                                                        {{ $attachment['name'] }}
                                                                                    </span>
                                                                                </div>
                                                                            </div>
                                                                            <div class="ml-4 flex-shrink-0">
                                                                                <a
                                                                                    href="{{ $attachment['url'] }}"
                                                                                    class="font-medium text-blue-600 hover:text-blue-500"
                                                                                    target="_blank"
                                                                                >
                                                                                    Download
                                                                                </a>
                                                                            </div>
                                                                        </div>
                                                                    @endforeach
                                                                </div>
                                                            </dd>
                                                        </div>
                                                    @endif
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </li>
                            @endforeach
                        </ul>
                    </div>

                    {{-- Reply Form --}}
                    <div class="mt-6 border-t border-gray-200 pt-6">
                        <div class="flex items-start space-x-4">
                            <div class="min-w-0 flex-1">
                                <form wire:submit="sendReply">
                                    <div>
                                        <label for="reply" class="sr-only">
                                            Reply
                                        </label>
                                        <textarea
                                            wire:model="replyContent"
                                            rows="3"
                                            class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600"
                                            placeholder="Type your reply..."
                                        ></textarea>
                                    </div>

                                    <div class="mt-3 flex items-center justify-between">
                                        <div class="flex items-center space-x-5">
                                            <div class="flex items-center">
                                                <button
                                                    type="button"
                                                    x-tooltip.raw.placement.bottom="Include your email signature"
                                                    wire:click="$toggle('includeSignature')"
                                                    class="-m-2.5 flex size-10 items-center justify-center rounded-full text-gray-400 hover:text-gray-500"
                                                >
                                                    <x-lucide-pen-line
                                                        @class([
                                                            'size-5 ',
                                                            'text-gray-500' => $includeSignature,
                                                            'text-gray-300' => ! $includeSignature,
                                                        ])
                                                    />
                                                </button>
                                            </div>

                                            <div class="flex items-center">
                                                <button
                                                    type="button"
                                                    x-tooltip.raw.placement.bottom="Include attachments"
                                                    wire:click="$toggle('showAttachments')"
                                                    class="-m-2.5 flex size-10 items-center justify-center rounded-full text-gray-400 hover:text-gray-500"
                                                >
                                                    <x-lucide-paperclip
                                                        @class([
                                                            'size-5 ',
                                                            'text-gray-500' => $showAttachments,
                                                            'text-gray-300' => ! $showAttachments,
                                                        ])
                                                    />
                                                </button>
                                            </div>

                                            <div
                                                class="relative text-left"
                                                x-data="dropdown"
                                            >
                                                <div>
                                                    <button
                                                        x-tooltip.raw.placement.bottom="Reply Templates"
                                                        x-bind="trigger"
                                                        type="button"
                                                        class="-my-2 flex items-center rounded-full p-2 text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-navy-500"
                                                    >
                                                        @svg('heroicon-s-ellipsis-vertical', 'size-5')
                                                    </button>
                                                </div>

                                                <div
                                                    x-bind="dialog"
                                                    x-cloak
                                                    class="absolute bottom-0 left-0 z-10 mb-8 w-72 origin-bottom-left overflow-hidden rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                                                    role="menu"
                                                >
                                                    <div role="none">
                                                        <button
                                                            x-on:click="open = false"
                                                            wire:click="mountAction('createReplyTemplateAction')"
                                                            type="button"
                                                            class="block w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900"
                                                            role="menuitem"
                                                        >
                                                            Save as template
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <button
                                            type="submit"
                                            class="rounded-md bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                                        >
                                            Send Reply
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </x-panel>
            </div>

            <!-- Sidebar -->
            <section class="row-start-1 space-y-6 lg:col-span-1 lg:col-start-3">
                @if ($ticket->isAssigned(Auth::user()))
                    <livewire:time-tracker
                        wire:key="time-tracker-ticket-{{ $ticket->id }}"
                        :trackable="$ticket"
                        :show-seconds="true"
                    />
                @endif

                @if ($ticket->customer)
                    <x-panel heading="Customer Details">
                        <x-contoso.data-list :cols="2">
                            <x-contoso.data-list.item
                                label="Name"
                                :value="$ticket->customer->name"
                                :href="route('customers.show', $ticket->customer)"
                                full
                            />

                            @if ($ticket->customer->phone)
                                <x-contoso.data-list.item
                                    label="Phone"
                                    :value="$ticket->customer->phone"
                                    :href="'tel:'.$ticket->customer->phone"
                                    full
                                />
                            @endif

                            @if ($ticket->customer->email)
                                <x-contoso.data-list.item
                                    label="Email"
                                    :value="$ticket->customer->email"
                                    :href="'mailto:'.$ticket->customer->email"
                                    full
                                />
                            @endif

                            @if ($ticket->customer->address)
                                <x-contoso.data-list.item
                                    label="Address"
                                    :value="$ticket->customer->displayAddress()"
                                    full
                                />
                            @endif
                        </x-contoso.data-list>
                    </x-panel>
                @endif

                <x-panel heading="Assigned">
                    @if ($ticket->assignedUsers->isNotEmpty())
                        <ul role="list" class="-my-4 divide-y divide-gray-200">
                            @foreach ($ticket->assignedUsers as $user)
                                <li class="flex py-4">
                                    <img
                                        class="size-10 rounded-full"
                                        src="{{ $user->avatarUrl() }}"
                                        alt="{{ $user->name }}"
                                    />
                                    <div class="ml-3">
                                        <p
                                            class="text-sm font-medium text-gray-900"
                                        >
                                            {{ $user->name }}
                                        </p>
                                        <p class="text-sm text-gray-500">
                                            {{ $user->email }}
                                        </p>
                                    </div>
                                </li>
                            @endforeach
                        </ul>
                    @else
                        <div>
                            <div class="mb-3 text-sm text-gray-500">
                                This ticket is not assigned to anyone yet.
                            </div>

                            <x-button.default
                                type="button"
                                wire:click="assignToMe"
                            >
                                Assign to me
                            </x-button.default>
                        </div>
                    @endif
                </x-panel>

                @if ($this->relatedTickets->isNotEmpty())
                    <x-contoso.tickets
                        heading="Related Tickets"
                        :tickets="$this->relatedTickets"
                    />
                @endif
            </section>
        </div>

        <x-filament-actions::modals />
    </main>
</x-layouts.page>
