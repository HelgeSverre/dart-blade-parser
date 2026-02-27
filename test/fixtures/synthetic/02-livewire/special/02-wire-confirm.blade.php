{{-- Livewire wire:confirm examples --}}
<div>
    {{-- Basic confirmation dialog --}}
    <button wire:click="delete" wire:confirm="Are you sure you want to delete this?">
        Delete Item
    </button>

    {{-- Confirmation on destructive actions --}}
    <button wire:click="resetData" wire:confirm="This will reset all data. Continue?">
        Reset All Data
    </button>

    {{-- Confirmation with dynamic message --}}
    <button wire:click="removeUser({{ $user->id }})"
            wire:confirm="Are you sure you want to remove {{ $user->name }}?">
        Remove User
    </button>

    {{-- wire:confirm.prompt - requires user to type expected value --}}
    <button wire:click="deleteAccount"
            wire:confirm.prompt="Type DELETE to confirm|DELETE">
        Delete My Account
    </button>

    {{-- Prompt with dynamic expected value --}}
    <button wire:click="destroyProject({{ $project->id }})"
            wire:confirm.prompt="Type the project name to confirm deletion|{{ $project->name }}">
        Destroy Project
    </button>

    {{-- Confirmation on form submission --}}
    <form wire:submit="publishPost">
        <input type="text" wire:model="title">
        <textarea wire:model="body"></textarea>
        <button type="submit" wire:confirm="Publish this post? It will be visible to everyone.">
            Publish
        </button>
    </form>

    {{-- Confirmation in a table row --}}
    <table>
        <tbody>
            @foreach($records as $record)
                <tr wire:key="record-{{ $record->id }}">
                    <td>{{ $record->name }}</td>
                    <td>
                        <button wire:click="archive({{ $record->id }})"
                                wire:confirm="Archive {{ $record->name }}?">
                            Archive
                        </button>
                        <button wire:click="destroy({{ $record->id }})"
                                wire:confirm.prompt="Type CONFIRM to delete|CONFIRM">
                            Delete
                        </button>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
</div>