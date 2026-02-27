{{--
---
features:
  - volt
  - state
  - computed
  - wire_model_live
  - wire_navigate
description: Volt component with computed properties and search
complexity: moderate
--}}
<?php

use function Livewire\Volt\{state, computed};
use App\Models\User;

state(['search' => '']);

$users = computed(function () {
    return User::query()
        ->when($this->search, fn ($q) => $q->where('name', 'like', "%{$this->search}%"))
        ->latest()
        ->paginate(10);
});

$delete = function (int $id) {
    User::findOrFail($id)->delete();
};

?>

<div>
    <input type="text" wire:model.live.debounce.300ms="search" placeholder="Search users...">

    <table>
        <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($this->users as $user)
                <tr wire:key="user-{{ $user->id }}">
                    <td>
                        <a href="/users/{{ $user->id }}" wire:navigate>
                            {{ $user->name }}
                        </a>
                    </td>
                    <td>{{ $user->email }}</td>
                    <td>
                        <button
                            wire:click="delete({{ $user->id }})"
                            wire:confirm="Are you sure you want to delete {{ $user->name }}?"
                        >
                            Delete
                        </button>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>

    {{ $this->users->links() }}
</div>
