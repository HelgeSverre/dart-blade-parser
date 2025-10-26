<x-card class="profile">
<x-slot:header>
<h2>User Profile</h2>
<p>Account Details</p></x-slot>
<div class="content">
<x-avatar :user="$user"/>
<p>{{ $user->name }}</p>
@can('edit-profile')
<x-button wire:click="edit">Edit</x-button>
@endcan</div>
<x-slot:footer><button>Save Changes</button>
<button>Cancel</button></x-slot>
</x-card>
