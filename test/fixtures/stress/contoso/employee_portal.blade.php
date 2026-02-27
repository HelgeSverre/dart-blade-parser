{{-- HR Employee Portal - comprehensive stress fixture --}}
@extends('layouts.dashboard')

@section('title', 'Employee Portal')

@push('styles')
    <style>
        .avatar-ring { box-shadow: 0 0 0 3px white, 0 0 0 5px #3b82f6; }
        .status-dot::before {
            content: '';
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 6px;
        }
    </style>
@endpush

@php
    $departments = ['Engineering', 'Marketing', 'Sales', 'Human Resources', 'Finance', 'Operations'];
    $leaveTypes = [
        'vacation' => ['label' => 'Vacation', 'color' => 'blue', 'icon' => 'sun'],
        'sick' => ['label' => 'Sick Leave', 'color' => 'red', 'icon' => 'heart'],
        'personal' => ['label' => 'Personal', 'color' => 'purple', 'icon' => 'user'],
        'bereavement' => ['label' => 'Bereavement', 'color' => 'gray', 'icon' => 'flag'],
        'parental' => ['label' => 'Parental', 'color' => 'green', 'icon' => 'home'],
    ];
@endphp

@section('content')
    <div
        class="min-h-screen bg-gray-50"
        x-data="{
            activeTab: 'overview',
            showLeaveModal: false,
            showDirectorySearch: false,
            searchTerm: '',
            departmentFilter: 'all',
            notificationsOpen: false,
            editingProfile: false,
        }"
    >
        {{-- Employee Profile Header --}}
        <div class="border-b border-gray-200 bg-white">
            <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
                <div class="flex flex-col items-start gap-6 sm:flex-row sm:items-center">
                    <div class="relative">
                        @isset($employee->avatar)
                            <img
                                src="{{ $employee->avatar }}"
                                alt="{{ $employee->full_name }}"
                                class="size-20 rounded-full object-cover avatar-ring"
                            >
                        @else
                            <div class="flex size-20 items-center justify-center rounded-full bg-blue-100 text-2xl font-bold text-blue-600 avatar-ring">
                                {{ $employee->initials }}
                            </div>
                        @endisset
                        @auth
                            @if($employee->is_online)
                                <span class="absolute bottom-0 right-0 block size-5 rounded-full bg-green-400 ring-2 ring-white"></span>
                            @endif
                        @endauth
                    </div>

                    <div class="flex-1">
                        <div class="flex items-center gap-3">
                            <h1 class="text-2xl font-bold text-gray-900">{{ $employee->full_name }}</h1>
                            @switch($employee->status)
                                @case('active')
                                    <x-badge color="green">Active</x-badge>
                                    @break
                                @case('on_leave')
                                    <x-badge color="yellow">On Leave</x-badge>
                                    @break
                                @case('probation')
                                    <x-badge color="blue">Probation</x-badge>
                                    @break
                                @default
                                    <x-badge color="gray">{{ ucfirst($employee->status) }}</x-badge>
                            @endswitch
                        </div>
                        <p class="mt-1 text-sm text-gray-500">
                            {{ $employee->job_title }} &middot; {{ $employee->department->name }}
                            @unless($employee->location === null)
                                &middot; <x-icon name="map-pin" class="inline size-3.5" /> {{ $employee->location }}
                            @endunless
                        </p>
                        <div class="mt-2 flex items-center gap-4 text-sm text-gray-400">
                            <span>Employee ID: <code class="rounded bg-gray-100 px-1.5 py-0.5 font-mono text-xs">{{ $employee->employee_id }}</code></span>
                            <span>Joined {{ $employee->hire_date->format('M d, Y') }}</span>
                            <span>{{ $employee->tenure_years }} year(s) tenure</span>
                        </div>
                    </div>

                    <div class="flex gap-2">
                        @can('update', $employee)
                            <x-button variant="outline" @click="editingProfile = true">
                                <x-icon name="pencil" class="mr-1.5 size-4" />
                                Edit Profile
                            </x-button>
                        @endcan
                        <x-button variant="outline" @click="notificationsOpen = !notificationsOpen">
                            <x-icon name="bell" class="size-4" />
                            @if($unreadNotifications > 0)
                                <span class="ml-1 rounded-full bg-red-500 px-1.5 py-0.5 text-xs text-white">{{ $unreadNotifications }}</span>
                            @endif
                        </x-button>
                    </div>
                </div>

                {{-- Tab Navigation --}}
                <nav class="mt-6 flex space-x-6 border-t border-gray-200 pt-4">
                    @foreach(['overview' => 'Overview', 'leave' => 'Leave & PTO', 'team' => 'Team', 'payroll' => 'Payroll', 'documents' => 'Documents'] as $tab => $label)
                        <button
                            @click="activeTab = '{{ $tab }}'"
                            :class="activeTab === '{{ $tab }}'
                                ? 'border-blue-500 text-blue-600'
                                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'"
                            class="border-b-2 px-1 pb-3 text-sm font-medium transition-colors"
                        >
                            {{ $label }}
                        </button>
                    @endforeach
                </nav>
            </div>
        </div>

        <main class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
            {{-- Overview Tab --}}
            <div x-show="activeTab === 'overview'" x-transition>
                <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                    {{-- Quick Stats --}}
                    <div class="lg:col-span-2">
                        <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
                            @foreach([
                                ['label' => 'PTO Balance', 'value' => $employee->pto_balance . ' days', 'icon' => 'calendar', 'color' => 'blue'],
                                ['label' => 'Sick Days', 'value' => $employee->sick_days_remaining . ' left', 'icon' => 'heart', 'color' => 'red'],
                                ['label' => 'Next Review', 'value' => $employee->next_review?->format('M d') ?? 'TBD', 'icon' => 'clipboard', 'color' => 'green'],
                                ['label' => 'Team Size', 'value' => $employee->direct_reports_count, 'icon' => 'users', 'color' => 'purple'],
                            ] as $stat)
                                <div class="rounded-lg bg-white p-4 shadow" wire:key="stat-{{ $loop->index }}">
                                    <div class="flex items-center gap-3">
                                        <div @class([
                                            'flex size-10 items-center justify-center rounded-lg',
                                            'bg-blue-100 text-blue-600' => $stat['color'] === 'blue',
                                            'bg-red-100 text-red-600' => $stat['color'] === 'red',
                                            'bg-green-100 text-green-600' => $stat['color'] === 'green',
                                            'bg-purple-100 text-purple-600' => $stat['color'] === 'purple',
                                        ])>
                                            <x-icon :name="$stat['icon']" class="size-5" />
                                        </div>
                                        <div>
                                            <p class="text-xs text-gray-500">{{ $stat['label'] }}</p>
                                            <p class="text-lg font-semibold text-gray-900">{{ $stat['value'] }}</p>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>

                        {{-- Upcoming Events --}}
                        <div class="mt-6 rounded-lg bg-white p-6 shadow">
                            <h2 class="mb-4 text-lg font-semibold text-gray-900">Upcoming</h2>
                            @forelse($upcomingEvents as $event)
                                <div
                                    wire:key="event-{{ $event->id }}"
                                    @class([
                                        'flex items-start gap-4 border-b border-gray-100 py-3',
                                        'last:border-b-0' => $loop->last,
                                    ])
                                >
                                    <div @class([
                                        'mt-0.5 flex size-8 flex-shrink-0 items-center justify-center rounded-full text-xs font-bold',
                                        'bg-blue-100 text-blue-700' => $event->type === 'meeting',
                                        'bg-green-100 text-green-700' => $event->type === 'holiday',
                                        'bg-yellow-100 text-yellow-700' => $event->type === 'deadline',
                                        'bg-purple-100 text-purple-700' => $event->type === 'birthday',
                                    ])>
                                        {{ $event->date->format('d') }}
                                    </div>
                                    <div class="flex-1">
                                        <p class="text-sm font-medium text-gray-900">{{ $event->title }}</p>
                                        <p class="text-xs text-gray-500">
                                            <time datetime="{{ $event->date->toIso8601String() }}">
                                                {{ $event->date->format('l, F j') }}
                                            </time>
                                            @if($event->time)
                                                at {{ $event->time }}
                                            @endif
                                        </p>
                                    </div>
                                    @if($loop->first && $event->is_today)
                                        <x-badge color="red">Today</x-badge>
                                    @endif
                                </div>
                            @empty
                                <p class="py-4 text-center text-sm italic text-gray-400">No upcoming events</p>
                            @endforelse
                        </div>
                    </div>

                    {{-- Announcements Sidebar --}}
                    <div class="lg:col-span-1">
                        <div class="rounded-lg bg-white p-6 shadow">
                            <h2 class="mb-4 text-lg font-semibold text-gray-900">Announcements</h2>
                            @foreach($announcements as $announcement)
                                <article
                                    wire:key="announcement-{{ $announcement->id }}"
                                    class="mb-4 border-b border-gray-100 pb-4 last:mb-0 last:border-0 last:pb-0"
                                >
                                    <div class="flex items-start justify-between">
                                        <h3 class="text-sm font-medium text-gray-900">{{ $announcement->title }}</h3>
                                        @if($announcement->is_pinned)
                                            <x-icon name="bookmark" class="size-4 text-yellow-500" />
                                        @endif
                                    </div>
                                    <p class="mt-1 text-xs text-gray-500">
                                        {!! Str::limit(strip_tags($announcement->body), 120) !!}
                                    </p>
                                    <div class="mt-2 flex items-center gap-2 text-xs text-gray-400">
                                        <span>{{ $announcement->author->name }}</span>
                                        <span>&middot;</span>
                                        <span>{{ $announcement->created_at->diffForHumans() }}</span>
                                    </div>
                                </article>
                            @endforeach

                            @includeWhen($announcements->count() > 5, 'hr.partials.view-all-link', ['route' => 'announcements.index'])
                        </div>

                        {{-- Quick Links --}}
                        <div class="mt-6 rounded-lg bg-white p-6 shadow">
                            <h2 class="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-500">Quick Links</h2>
                            <ul class="space-y-2">
                                @foreach([
                                    ['label' => 'Benefits Portal', 'route' => 'benefits.index', 'icon' => 'shield-check'],
                                    ['label' => 'Training Center', 'route' => 'training.index', 'icon' => 'academic-cap'],
                                    ['label' => 'IT Support', 'route' => 'support.create', 'icon' => 'computer-desktop'],
                                    ['label' => 'Company Handbook', 'route' => 'handbook.index', 'icon' => 'book-open'],
                                    ['label' => 'Expense Reports', 'route' => 'expenses.index', 'icon' => 'receipt-percent'],
                                ] as $link)
                                    <li>
                                        <a
                                            href="{{ route($link['route']) }}"
                                            wire:navigate
                                            class="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900"
                                        >
                                            <x-icon :name="$link['icon']" class="size-4 text-gray-400" />
                                            {{ $link['label'] }}
                                        </a>
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Leave & PTO Tab --}}
            <div x-show="activeTab === 'leave'" x-transition x-cloak>
                <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                    {{-- Leave Balance Cards --}}
                    <div class="lg:col-span-3">
                        <div class="grid grid-cols-2 gap-4 sm:grid-cols-5">
                            @foreach($leaveTypes as $type => $config)
                                <div class="rounded-lg bg-white p-4 shadow" wire:key="leave-type-{{ $type }}">
                                    <div class="flex items-center gap-2">
                                        <x-icon :name="$config['icon']" @class([
                                            'size-5',
                                            'text-blue-500' => $config['color'] === 'blue',
                                            'text-red-500' => $config['color'] === 'red',
                                            'text-purple-500' => $config['color'] === 'purple',
                                            'text-gray-500' => $config['color'] === 'gray',
                                            'text-green-500' => $config['color'] === 'green',
                                        ]) />
                                        <span class="text-xs font-medium text-gray-500">{{ $config['label'] }}</span>
                                    </div>
                                    <p class="mt-2 text-2xl font-bold text-gray-900">
                                        {{ $employee->getLeaveBalance($type) }}
                                    </p>
                                    <p class="text-xs text-gray-400">of {{ $employee->getLeaveAllotment($type) }} days</p>
                                </div>
                            @endforeach
                        </div>
                    </div>

                    {{-- Leave Request Form --}}
                    <div class="lg:col-span-2">
                        <div class="rounded-lg bg-white p-6 shadow">
                            <h2 class="mb-4 text-lg font-semibold text-gray-900">Request Time Off</h2>
                            <form wire:submit.prevent="submitLeaveRequest">
                                @csrf
                                <div class="space-y-4">
                                    <div>
                                        <label for="leave-type" class="block text-sm font-medium text-gray-700">Leave Type</label>
                                        <select
                                            id="leave-type"
                                            wire:model.live="leaveForm.type"
                                            @required(true)
                                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                        >
                                            <option value="">Select type</option>
                                            @foreach($leaveTypes as $type => $config)
                                                <option value="{{ $type }}">{{ $config['label'] }}</option>
                                            @endforeach
                                        </select>
                                        @error('leaveForm.type')
                                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                        @enderror
                                    </div>

                                    <div class="grid grid-cols-2 gap-4">
                                        <div>
                                            <label for="leave-start" class="block text-sm font-medium text-gray-700">Start Date</label>
                                            <input
                                                id="leave-start"
                                                type="date"
                                                wire:model="leaveForm.start_date"
                                                @required(true)
                                                min="{{ now()->format('Y-m-d') }}"
                                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                            >
                                            @error('leaveForm.start_date')
                                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                            @enderror
                                        </div>
                                        <div>
                                            <label for="leave-end" class="block text-sm font-medium text-gray-700">End Date</label>
                                            <input
                                                id="leave-end"
                                                type="date"
                                                wire:model="leaveForm.end_date"
                                                @required(true)
                                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                            >
                                            @error('leaveForm.end_date')
                                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                                            @enderror
                                        </div>
                                    </div>

                                    <div>
                                        <label for="leave-reason" class="block text-sm font-medium text-gray-700">Reason</label>
                                        <textarea
                                            id="leave-reason"
                                            wire:model="leaveForm.reason"
                                            rows="3"
                                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                            placeholder="Brief reason for leave (optional)"
                                        ></textarea>
                                    </div>

                                    <div class="flex items-center gap-2">
                                        <input
                                            type="checkbox"
                                            id="leave-notify"
                                            wire:model="leaveForm.notify_team"
                                            @checked(true)
                                            class="rounded border-gray-300 text-blue-600"
                                        >
                                        <label for="leave-notify" class="text-sm text-gray-600">Notify my team</label>
                                    </div>
                                </div>

                                <div class="mt-6 flex justify-end gap-3">
                                    <x-button type="button" variant="outline" wire:click="resetLeaveForm">
                                        Clear
                                    </x-button>
                                    <x-button type="submit" variant="primary" wire:loading.attr="disabled">
                                        <span wire:loading.remove wire:target="submitLeaveRequest">Submit Request</span>
                                        <span wire:loading wire:target="submitLeaveRequest">Submitting...</span>
                                    </x-button>
                                </div>
                            </form>
                        </div>
                    </div>

                    {{-- Leave History --}}
                    <div class="lg:col-span-1">
                        <div class="rounded-lg bg-white p-6 shadow">
                            <h2 class="mb-4 text-lg font-semibold text-gray-900">Recent Requests</h2>
                            @forelse($leaveRequests as $request)
                                <div
                                    wire:key="leave-req-{{ $request->id }}"
                                    class="mb-3 rounded-md border border-gray-100 p-3 last:mb-0"
                                >
                                    <div class="flex items-center justify-between">
                                        <span class="text-sm font-medium text-gray-900">
                                            {{ $leaveTypes[$request->type]['label'] ?? $request->type }}
                                        </span>
                                        @if($request->status === 'approved')
                                            <x-badge color="green">Approved</x-badge>
                                        @elseif($request->status === 'pending')
                                            <x-badge color="yellow">Pending</x-badge>
                                        @elseif($request->status === 'rejected')
                                            <x-badge color="red">Rejected</x-badge>
                                        @else
                                            <x-badge color="gray">{{ ucfirst($request->status) }}</x-badge>
                                        @endif
                                    </div>
                                    <p class="mt-1 text-xs text-gray-500">
                                        {{ $request->start_date->format('M d') }} - {{ $request->end_date->format('M d, Y') }}
                                        ({{ $request->days_count }} day{{ $request->days_count > 1 ? 's' : '' }})
                                    </p>
                                    @if($request->status === 'pending')
                                        @can('cancel', $request)
                                            <button
                                                wire:click="cancelLeaveRequest({{ $request->id }})"
                                                wire:confirm="Cancel this leave request?"
                                                class="mt-2 text-xs text-red-600 hover:text-red-800"
                                            >
                                                Cancel Request
                                            </button>
                                        @endcan
                                    @endif
                                </div>
                            @empty
                                <p class="py-4 text-center text-sm italic text-gray-400">No leave requests</p>
                            @endforelse
                        </div>
                    </div>
                </div>
            </div>

            {{-- Team Tab --}}
            <div x-show="activeTab === 'team'" x-transition x-cloak>
                <div class="rounded-lg bg-white shadow">
                    <div class="border-b border-gray-200 px-6 py-4">
                        <div class="flex items-center justify-between">
                            <h2 class="text-lg font-semibold text-gray-900">Team Directory</h2>
                            <div class="flex items-center gap-3">
                                <input
                                    type="search"
                                    x-model="searchTerm"
                                    wire:model.live.debounce.300ms="teamSearch"
                                    placeholder="Search team members..."
                                    class="rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                >
                                <select
                                    x-model="departmentFilter"
                                    wire:model.live="departmentFilter"
                                    class="rounded-md border-gray-300 text-sm shadow-sm"
                                >
                                    <option value="all">All Departments</option>
                                    @foreach($departments as $dept)
                                        <option value="{{ Str::slug($dept) }}">{{ $dept }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                    </div>

                    <div class="divide-y divide-gray-100">
                        @forelse($teamMembers as $member)
                            <div
                                wire:key="member-{{ $member->id }}"
                                class="flex items-center gap-4 px-6 py-4 transition-colors hover:bg-gray-50"
                            >
                                @isset($member->avatar)
                                    <img src="{{ $member->avatar }}" alt="" class="size-10 rounded-full object-cover">
                                @else
                                    <div class="flex size-10 items-center justify-center rounded-full bg-gray-200 text-sm font-medium text-gray-600">
                                        {{ $member->initials }}
                                    </div>
                                @endisset

                                <div class="flex-1">
                                    <p class="text-sm font-medium text-gray-900">
                                        {{ $member->full_name }}
                                        @if($member->id === $employee->id)
                                            <span class="text-xs text-gray-400">(You)</span>
                                        @endif
                                    </p>
                                    <p class="text-xs text-gray-500">{{ $member->job_title }}</p>
                                </div>

                                <div class="text-right text-xs text-gray-400">
                                    <p>{{ $member->department->name }}</p>
                                    @if($member->is_online)
                                        <p class="text-green-500">Online</p>
                                    @endif
                                </div>

                                @can('view', $member)
                                    <a
                                        href="{{ route('employees.show', $member) }}"
                                        wire:navigate
                                        class="rounded-md px-2 py-1 text-xs text-blue-600 hover:bg-blue-50"
                                    >
                                        View
                                    </a>
                                @endcan
                            </div>
                        @empty
                            <div class="px-6 py-12 text-center">
                                <x-icon name="users" class="mx-auto size-12 text-gray-300" />
                                <p class="mt-2 text-sm text-gray-500">No team members found</p>
                            </div>
                        @endforelse
                    </div>

                    @if($teamMembers->hasPages())
                        <div class="border-t border-gray-200 px-6 py-3">
                            {{ $teamMembers->links() }}
                        </div>
                    @endif
                </div>
            </div>

            {{-- Payroll Tab --}}
            <div x-show="activeTab === 'payroll'" x-transition x-cloak>
                @auth
                    @can('viewPayroll', $employee)
                        <div class="rounded-lg bg-white shadow">
                            <div class="border-b border-gray-200 px-6 py-4">
                                <h2 class="text-lg font-semibold text-gray-900">Pay Stubs</h2>
                            </div>
                            <table class="min-w-full divide-y divide-gray-200">
                                <thead class="bg-gray-50">
                                    <tr>
                                        <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">Period</th>
                                        <th class="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">Gross</th>
                                        <th class="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">Deductions</th>
                                        <th class="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">Net Pay</th>
                                        <th class="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">Actions</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-gray-200">
                                    @foreach($payStubs as $stub)
                                        <tr wire:key="pay-{{ $stub->id }}" class="hover:bg-gray-50">
                                            <td class="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                                                {{ $stub->period_start->format('M d') }} - {{ $stub->period_end->format('M d, Y') }}
                                            </td>
                                            <td class="whitespace-nowrap px-6 py-4 text-right text-sm text-gray-700">
                                                ${{ number_format($stub->gross_pay, 2) }}
                                            </td>
                                            <td class="whitespace-nowrap px-6 py-4 text-right text-sm text-red-600">
                                                -${{ number_format($stub->total_deductions, 2) }}
                                            </td>
                                            <td class="whitespace-nowrap px-6 py-4 text-right text-sm font-semibold text-gray-900">
                                                ${{ number_format($stub->net_pay, 2) }}
                                            </td>
                                            <td class="whitespace-nowrap px-6 py-4 text-right">
                                                <a
                                                    href="{{ route('payroll.download', $stub) }}"
                                                    class="text-sm text-blue-600 hover:text-blue-800"
                                                >
                                                    <x-icon name="arrow-down-tray" class="inline size-4" /> PDF
                                                </a>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    @else
                        <div class="rounded-lg bg-yellow-50 p-8 text-center">
                            <x-icon name="lock-closed" class="mx-auto size-12 text-yellow-400" />
                            <p class="mt-2 text-sm text-yellow-800">You don't have permission to view payroll information.</p>
                        </div>
                    @endcan
                @endauth

                @guest
                    <div class="rounded-lg bg-gray-100 p-8 text-center">
                        <p class="text-sm text-gray-600">Please <a href="{{ route('login') }}" class="text-blue-600 underline">log in</a> to view payroll information.</p>
                    </div>
                @endguest
            </div>
        </main>

        @once
            @push('scripts')
                <script>
                    document.addEventListener('livewire:initialized', () => {
                        Livewire.on('leave-submitted', () => {
                            Alpine.store('notifications').add('Leave request submitted successfully', 'success');
                        });
                    });
                </script>
            @endpush
        @endonce

        @production
            @include('analytics.pageview', ['page' => 'employee-portal'])
        @endproduction
    </div>
@endsection
