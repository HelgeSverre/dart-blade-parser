<div class="modifier-showcase">
    <h2>Wire Model Modifiers</h2>

    {{-- Blur Modifier - Updates on focus loss --}}
    <div class="form-group">
        <label for="title">Title (blur)</label>
        <input
            type="text"
            id="title"
            wire:model.blur="title"
            class="form-control"
        >
        <small>Updates when you click away</small>
    </div>

    {{-- Number Modifier - Converts to number --}}
    <div class="form-group">
        <label for="age">Age (number)</label>
        <input
            type="text"
            id="age"
            wire:model.number="age"
            class="form-control"
        >
        <small>Automatically converts to number type</small>
        @error('age') <span class="error">{{ $message }}</span> @enderror
    </div>

    {{-- Boolean Modifier - Converts to boolean --}}
    <div class="form-group">
        <label>
            <input type="checkbox" wire:model.boolean="isActive">
            Active Status (boolean)
        </label>
        <small>Ensures true/false values</small>
    </div>

    {{-- Lazy Modifier - Updates on change event --}}
    <div class="form-group">
        <label for="bio">Bio (lazy)</label>
        <textarea
            id="bio"
            wire:model.lazy="bio"
            rows="3"
            class="form-control"
        ></textarea>
        <small>Updates on blur, not while typing</small>
    </div>

    {{-- Defer Modifier - Batches updates --}}
    <div class="form-group">
        <label for="notes">Notes (defer)</label>
        <textarea
            id="notes"
            wire:model.defer="notes"
            rows="3"
            class="form-control"
        ></textarea>
        <small>Updates only when action is called</small>
    </div>

    {{-- Combined Modifiers --}}
    <div class="form-group">
        <label for="quantity">Quantity (live + debounce + number)</label>
        <input
            type="text"
            id="quantity"
            wire:model.live.debounce.300ms.number="quantity"
            class="form-control"
        >
        <small>Live updates with 300ms debounce, converted to number</small>
    </div>

    <button wire:click="save" class="btn btn-primary">Save Changes</button>
</div>
