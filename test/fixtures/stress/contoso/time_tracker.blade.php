<div
    {{-- Slow poll --}}
    @unless ($isCurrentlyTrackingTime)
        wire:poll.{{ $refreshRateIdle }}s.visible
    @endunless
>
    <div
        {{-- Fast poll --}}
        @if ($isCurrentlyTrackingTime)
            wire:poll.{{ $refreshRate }}s.visible
        @endif
    >
        <div>
            <div class="relative">
                <div class="flex rounded-md shadow-sm">
                    <div
                        class="relative flex flex-grow items-stretch focus-within:z-10"
                    >
                        <div
                            class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                        >
                            @svg('heroicon-o-clock', 'size-5 text-gray-400')
                        </div>
                        <input
                            type="text"
                            readonly
                            disabled
                            value="{{ $trackable->totalTimeFormatted($showSeconds) }}"
                            class="block w-full min-w-28 rounded-none rounded-l-md border-gray-300 pl-10 focus:outline-none sm:text-sm"
                        />
                    </div>

                    <button
                        wire:click="togglePanel('summary')"
                        type="button"
                        class="text-grey-700 relative -ml-px inline-flex items-center space-x-2 border border-gray-300 bg-gray-50 px-2 py-2 text-sm font-medium hover:bg-gray-100 focus:z-10 focus:border-navy-500 focus:outline-none focus:ring-1 focus:ring-navy-500"
                        :class="{ 'bg-white': $wire.openPanel === 'summary' }"
                        x-tooltip.raw="View hours by user"
                    >
                        @svg('heroicon-s-bars-4', 'size-5 text-gray-400')
                    </button>

                    <button
                        wire:click="togglePanel('details')"
                        type="button"
                        class="text-grey-700 relative -ml-px inline-flex items-center space-x-2 border border-gray-300 bg-gray-50 px-2 py-2 text-sm font-medium hover:bg-gray-100 focus:z-10 focus:border-navy-500 focus:outline-none focus:ring-1 focus:ring-navy-500"
                        :class="{ 'bg-white': $wire.openPanel === 'details' }"
                        x-tooltip.raw="View detailed time entries"
                    >
                        @svg('heroicon-s-list-bullet', 'size-5 text-gray-400')
                    </button>

                    <button
                        wire:click="togglePanel('form')"
                        type="button"
                        class="text-grey-700 relative -ml-px inline-flex items-center space-x-2 border border-gray-300 bg-gray-50 px-2 py-2 text-sm font-medium hover:bg-gray-100 focus:z-10 focus:border-navy-500 focus:outline-none focus:ring-1 focus:ring-navy-500"
                        :class="{ 'bg-white': $wire.openPanel === 'form' }"
                        x-tooltip.raw="Add hours"
                    >
                        @svg('heroicon-s-pencil-square', 'size-5 text-gray-400')
                    </button>

                    @if ($isCurrentlyTrackingTime)
                        <button
                            wire:click="stop"
                            type="button"
                            title="Stop time tracking"
                            class="relative -ml-px inline-flex items-center space-x-2 rounded-r-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm font-medium text-red-700 hover:bg-gray-100 focus:z-10 focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                        >
                            @svg('heroicon-s-stop-circle', 'size-5 text-red-700')
                        </button>
                    @else
                        <button
                            wire:click="start"
                            type="button"
                            title="Start time tracking"
                            class="relative -ml-px inline-flex items-center space-x-2 rounded-r-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm font-medium text-navy-700 hover:bg-gray-100 focus:z-10 focus:border-navy-500 focus:outline-none focus:ring-1 focus:ring-navy-500"
                        >
                            @svg('heroicon-s-play', 'size-5 text-navy-700')
                        </button>
                    @endif
                </div>

                {{-- Hours Form --}}
                @if ($openPanel === 'form')
                    <div
                        x-transition.origin.top.right.duration.150ms.opacity.scale
                        class="absolute right-0 z-30 mt-2 w-full origin-top-right rounded-md border border-gray-200 bg-white shadow-lg focus:outline-none"
                    >
                        <div class="p-4">
                            <form
                                wire:submit.prevent="{{ $isEditing ? 'updateTotalTime' : 'addHoursEntry' }}"
                            >
                                <div class="space-y-4">
                                    @if (\App\Enums\Permission::manageTimesheetEntries->isAllowed())
                                        <div>
                                            <label
                                                for="trackedUserId"
                                                class="block text-sm font-medium text-gray-700"
                                            >
                                                Team Member
                                            </label>
                                            <select
                                                id="trackedUserId"
                                                wire:model.live="trackedUserId"
                                                class="mt-1 block w-full rounded-md border-gray-300 bg-white py-2 pl-3 pr-10 text-base text-gray-700 focus:border-navy-500 focus:outline-none focus:ring-navy-500 sm:text-sm"
                                            >
                                                <option
                                                    value="{{ Auth::id() }}"
                                                    selected
                                                >
                                                    {{ Auth::user()->name }}
                                                </option>
                                                @foreach (\App\Models\Company::current()->users as $user)
                                                    @if (! $user->is(Auth::user()))
                                                        <option
                                                            value="{{ $user->id }}"
                                                        >
                                                            {{ $user->name }}
                                                        </option>
                                                    @endif
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif

                                    <div>
                                        <div
                                            class="flex flex-row items-center justify-between"
                                        >
                                            <label
                                                for="date"
                                                class="block text-sm font-medium text-gray-700"
                                            >
                                                Date
                                            </label>
                                            <button
                                                type="button"
                                                class="px-2 py-0.5 text-xs font-medium text-navy-700"
                                                wire:click="setTimeToNow"
                                            >
                                                Set to today
                                            </button>
                                        </div>
                                        <input
                                            type="date"
                                            id="date"
                                            wire:model.defer="date"
                                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm"
                                            required
                                        />
                                        @error('date')
                                            <span class="text-sm text-red-600">
                                                {{ $message }}
                                            </span>
                                        @enderror
                                    </div>

                                    <div>
                                        <label
                                            for="hours"
                                            class="block text-sm font-medium text-gray-700"
                                        >
                                            Hours
                                        </label>
                                        <input
                                            type="number"
                                            id="hours"
                                            wire:model.defer="hours"
                                            placeholder="number of hours (e.g. 1.5)"
                                            step="0.1"
                                            min="0"
                                            max="24"
                                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm"
                                            required
                                        />
                                        @error('hours')
                                            <span class="text-sm text-red-600">
                                                {{ $message }}
                                            </span>
                                        @enderror
                                    </div>

                                    <div>
                                        <label
                                            for="comment"
                                            class="block text-sm font-medium text-gray-700"
                                        >
                                            Comment
                                        </label>
                                        <textarea
                                            id="comment"
                                            wire:model.defer="comment"
                                            rows="2"
                                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-navy-500 focus:ring-navy-500 sm:text-sm"
                                        ></textarea>
                                    </div>

                                    <div class="flex justify-end space-x-3">
                                        <button
                                            type="button"
                                            wire:click="togglePanel(null)"
                                            class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            class="inline-flex items-center rounded-md border border-transparent bg-navy-600 px-3 py-2 text-sm font-medium text-white hover:bg-navy-700 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                        >
                                            {{ $isEditing ? 'Update hours' : 'Add hours' }}
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                @endif

                {{-- Summary Table --}}
                @if ($openPanel === 'summary')
                    <div
                        x-transition.origin.top.right.duration.150ms.opacity.scale
                        class="absolute right-0 z-20 mt-2 w-full origin-top-right rounded-md border border-gray-200 bg-white shadow-lg focus:outline-none"
                        tabindex="-1"
                    >
                        <div role="none">
                            <div>
                                <table
                                    class="w-full max-w-full divide-y divide-gray-300 overflow-hidden rounded-md"
                                >
                                    <thead>
                                        <tr>
                                            <th
                                                class="p-2 text-left text-sm font-semibold text-gray-700"
                                            >
                                                Team Member
                                            </th>
                                            <th
                                                class="p-2 text-right text-sm font-semibold text-gray-700"
                                            >
                                                Hours
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @foreach ($trackable->usersWithTrackedTime as $user)
                                            <tr
                                                class="border-b border-gray-200"
                                                wire:key="user-time-{{ $user->id }}"
                                            >
                                                <td
                                                    class="px-3 py-2 text-left text-sm font-medium text-gray-900"
                                                >
                                                    <div
                                                        class="flex items-center space-x-1"
                                                    >
                                                        <p
                                                            class="overflow-hidden truncate whitespace-normal"
                                                        >
                                                            {{ $user->name }}
                                                        </p>
                                                        @if ($trackable->isUserCurrentlyTrackingTime($user))
                                                            @svg('heroicon-s-play', 'h-4 w-5 text-navy-700')
                                                        @endif
                                                    </div>
                                                </td>
                                                <td
                                                    class="px-3 py-2 text-right text-sm text-gray-500"
                                                >
                                                    @if (Auth::user()->is($user))
                                                        <button
                                                            x-tooltip.raw="Edit time entry"
                                                            wire:click="startEditing({{ $user->id }})"
                                                            class="tabular-nums hover:text-navy-600 focus:outline-none focus:ring-2 focus:ring-navy-500 focus:ring-offset-2"
                                                        >
                                                            {{ $trackable->totalTimeForUserFormatted($user, $showSeconds) }}
                                                        </button>
                                                    @else
                                                        <span
                                                            class="tabular-nums"
                                                        >
                                                            {{ $trackable->totalTimeForUserFormatted($user, $showSeconds) }}
                                                        </span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @endforeach
                                    </tbody>
                                    <tfoot>
                                        <tr>
                                            <th
                                                class="px-3 py-2 text-left text-sm font-medium text-gray-900"
                                            >
                                                Total
                                            </th>
                                            <td
                                                class="px-3 py-2 text-right text-sm text-gray-500"
                                            >
                                                <span class="tabular-nums">
                                                    {{ $trackable->totalTimeFormatted($showSeconds) }}
                                                </span>
                                            </td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>
                    </div>
                @endif

                {{-- Detailed Time Entries --}}
                @if ($openPanel === 'details')
                    <div
                        x-transition.origin.top.right.duration.150ms.opacity.scale
                        class="absolute right-0 z-20 mt-2 w-full origin-top-right rounded-md border border-gray-200 bg-white shadow-xl focus:outline-none"
                        style="max-width: 95vw; width: 600px; left: 0"
                    >
                        <div>
                            <div class="max-h-96 overflow-y-auto">
                                <table
                                    class="w-full max-w-full divide-y divide-gray-300 overflow-hidden rounded-md"
                                >
                                    <thead class="sticky top-0 bg-white">
                                        <tr>
                                            <th class="p-2 text-left text-sm font-semibold text-gray-700">
                                                Team Member
                                            </th>
                                            <th class="p-2 text-left text-sm font-semibold text-gray-700">
                                                Date
                                            </th>
                                            <th class="p-2 text-left text-sm font-semibold text-gray-700">
                                                Comment
                                            </th>
                                            <th class="p-2 text-right text-sm font-semibold text-gray-700">
                                                Duration
                                            </th>
                                            @if (\App\Enums\Permission::manageTimesheetEntries->isAllowed())
                                                <th class="p-2 text-right text-sm font-semibold text-gray-700">
                                                    Actions
                                                </th>
                                            @endif
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-gray-200">
                                        @foreach ($detailedTimeEntries as $timeEntry)
                                            <tr
                                                class="hover:bg-gray-50"
                                                wire:key="time-entry-{{ $timeEntry->id }}"
                                            >
                                                <td class="px-3 py-2 text-sm text-gray-900">
                                                    {{ $timeEntry->user->name }}
                                                </td>
                                                <td class="px-3 py-2 text-sm text-gray-900">
                                                    {{ $timeEntry->start->format('Y-m-d') }}
                                                </td>
                                                <td class="max-w-xs px-3 py-2 text-sm text-gray-900">
                                                    {{ $timeEntry->comment }}
                                                </td>
                                                <td class="px-3 py-2 text-right text-sm tabular-nums text-gray-900">
                                                    {{ $timeEntry->durationFormatted() }}
                                                </td>
                                                @if (\App\Enums\Permission::manageTimesheetEntries->isAllowed())
                                                    <td class="px-3 py-2 text-right">
                                                        <div class="flex justify-end space-x-2">
                                                            <button
                                                                wire:click="editTimeEntry({{ $timeEntry->id }})"
                                                                class="text-navy-600 hover:text-navy-900"
                                                                x-tooltip.raw="Edit time entry"
                                                            >
                                                                @svg('heroicon-s-pencil', 'h-4 w-4')
                                                            </button>
                                                            <button
                                                                wire:click="deleteTimeEntry({{ $timeEntry->id }})"
                                                                wire:confirm="Are you sure you want to delete this time entry?"
                                                                class="text-red-600 hover:text-red-900"
                                                                x-tooltip.raw="Delete time entry"
                                                            >
                                                                @svg('heroicon-s-trash', 'h-4 w-4')
                                                            </button>
                                                        </div>
                                                    </td>
                                                @endif
                                            </tr>
                                        @endforeach
                                    </tbody>
                                    <tfoot>
                                        <tr class="bg-gray-50">
                                            <th colspan="3" class="px-3 py-2 text-left text-sm font-medium text-gray-900">
                                                Total
                                            </th>
                                            <td class="px-3 py-2 text-right text-sm font-medium tabular-nums text-gray-900">
                                                {{ $trackable->totalTimeFormatted($showSeconds) }}
                                            </td>
                                            <td></td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                            <div class="flex justify-end border-t border-gray-200 p-2">
                                <button
                                    wire:click="togglePanel(null)"
                                    class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
                                >
                                    Close
                                </button>
                            </div>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>
