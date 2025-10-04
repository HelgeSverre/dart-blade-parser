<div wire:poll.5s>
    <form wire:submit.prevent="save">
        <input wire:model.live="name" type="text">
        <button wire:click="submit" wire:loading.attr="disabled">
            Submit
        </button>
    </form>
</div>
