{{--
---
features:
  - foreach_directive
  - loop_variable
  - alpine_x_for
  - wire_click
description: Nested loops with Blade foreach, Alpine x-for, and interactive actions
complexity: moderate
line_count: 70
--}}

<div class="department-structure">
    <h2 class="text-2xl font-bold mb-6">Organization Structure</h2>

    @foreach ($departments as $department)
        <div
            x-data="{
                expanded: {{ $loop->first ? 'true' : 'false' }},
                teamMembers: {{ json_encode($department->teams->pluck('members')->flatten()->toArray()) }}
            }"
            wire:key="dept-{{ $department->id }}"
            class="department-card mb-6 border rounded-lg {{ $loop->odd ? 'bg-gray-50' : 'bg-white' }}"
        >
            <div class="department-header p-4 flex items-center justify-between cursor-pointer"
                 @click="expanded = !expanded">
                <div class="flex items-center gap-3">
                    <span class="badge">{{ $loop->iteration }}</span>
                    <h3 class="text-lg font-semibold">{{ $department->name }}</h3>
                    <span class="text-sm text-gray-500">
                        ({{ $department->teams->count() }} teams)
                    </span>
                </div>

                <button
                    wire:click.stop="editDepartment({{ $department->id }})"
                    class="btn btn-sm btn-outline"
                >
                    Edit
                </button>
            </div>

            <div x-show="expanded" x-transition class="department-body p-4 pt-0">
                @foreach ($department->teams as $team)
                    <div
                        wire:key="team-{{ $team->id }}"
                        class="team-section ml-6 mb-4 p-4 border-l-4 {{ $loop->first ? 'border-blue-500' : 'border-gray-300' }}"
                    >
                        <div class="flex items-center justify-between mb-3">
                            <h4 class="font-semibold text-md">
                                {{ $team->name }}
                                @if ($loop->last)
                                    <span class="text-xs text-gray-500">(Latest)</span>
                                @endif
                            </h4>

                            <div class="text-sm text-gray-600">
                                Team {{ $loop->iteration }} of {{ $loop->count }}
                            </div>
                        </div>

                        <div class="members-grid grid grid-cols-3 gap-3">
                            <template x-for="(member, index) in teamMembers.filter(m => m.team_id === {{ $team->id }})" :key="member.id">
                                <div
                                    @click="$wire.selectMember(member.id)"
                                    class="member-card p-3 border rounded cursor-pointer hover:bg-blue-50 transition"
                                >
                                    <div class="flex items-center gap-2">
                                        <img
                                            :src="member.avatar"
                                            :alt="member.name"
                                            class="w-10 h-10 rounded-full"
                                        >
                                        <div>
                                            <p class="text-sm font-medium" x-text="member.name"></p>
                                            <p class="text-xs text-gray-500" x-text="member.role"></p>
                                        </div>
                                    </div>
                                </div>
                            </template>
                        </div>

                        <div class="team-stats mt-3 text-sm text-gray-600">
                            <span>Position in department: {{ $loop->iteration }}/{{ $loop->count }}</span>
                            @unless ($loop->last)
                                <span class="mx-2">•</span>
                                <span>{{ $loop->remaining }} more team(s)</span>
                            @endunless
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    @endforeach
</div>
