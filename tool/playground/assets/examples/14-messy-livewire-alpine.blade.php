<div wire:poll.5s x-data="{ open: false, loading: false }">
<button wire:click="refresh"x-on:click="open = true"class="btn">Refresh</button>
<div x-show="open"wire:loading class="modal"><p>Loading...</p></div>
@if($showData)
<ul>@foreach($records as $record)
<li wire:key="record-{{ $record->id }}"x-data="{ expanded: false }">
<span x-on:click="expanded = !expanded">{{ $record->name }}</span></li>
@endforeach</ul>
@endif
</div>
