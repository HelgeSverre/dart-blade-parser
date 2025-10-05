---
description: "@foreach with $loop variable properties for enhanced user list rendering"
tags: ["foreach", "loop-variable", "users", "conditional-styling"]
---
<div class="team-directory">
    <h2>Team Members ({{ count($users) }})</h2>

    <table class="user-table">
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Role</th>
                <th>Department</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach($users as $user)
            <tr class="user-row {{ $loop->first ? 'row-first' : '' }} {{ $loop->last ? 'row-last' : '' }} {{ $loop->even ? 'row-even' : 'row-odd' }}">
                <td class="user-index">
                    {{ $loop->iteration }}
                    @if($loop->first)
                    <span class="badge badge-primary">Lead</span>
                    @endif
                </td>

                <td class="user-name">
                    <div class="user-avatar">
                        <img src="{{ $user->avatar }}" alt="{{ $user->name }}">
                    </div>
                    <div class="user-info">
                        <strong>{{ $user->name }}</strong>
                        <small>{{ $user->email }}</small>
                    </div>
                </td>

                <td class="user-role">{{ $user->role }}</td>
                <td class="user-department">{{ $user->department }}</td>

                <td class="user-status">
                    <span class="status-indicator status-{{ $user->status }}">
                        {{ ucfirst($user->status) }}
                    </span>

                    @if($loop->remaining > 0 && $loop->remaining <= 3)
                    <small class="text-muted">({{ $loop->remaining }} more)</small>
                    @endif
                </td>
            </tr>

            @if($loop->iteration % 5 == 0 && !$loop->last)
            <tr class="separator-row">
                <td colspan="5">
                    <hr>
                    <p class="text-center text-muted">Progress: {{ $loop->iteration }}/{{ $loop->count }}</p>
                </td>
            </tr>
            @endif
            @endforeach
        </tbody>
    </table>
</div>
