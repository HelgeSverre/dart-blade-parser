<div class="user-profile-form">
    <h2>User Profile Settings</h2>

    {{-- Text Input --}}
    <div class="form-group">
        <label for="username">Username</label>
        <input type="text" id="username" wire:model="username" class="form-control">
        @error('username') <span class="error">{{ $message }}</span> @enderror
    </div>

    {{-- Email Input --}}
    <div class="form-group">
        <label for="email">Email Address</label>
        <input type="email" id="email" wire:model="email" class="form-control">
        @error('email') <span class="error">{{ $message }}</span> @enderror
    </div>

    {{-- Checkbox --}}
    <div class="form-group">
        <label class="checkbox-label">
            <input type="checkbox" wire:model="newsletter">
            Subscribe to newsletter
        </label>
    </div>

    {{-- Select Dropdown --}}
    <div class="form-group">
        <label for="country">Country</label>
        <select id="country" wire:model="country" class="form-control">
            <option value="">Select a country</option>
            <option value="us">United States</option>
            <option value="uk">United Kingdom</option>
            <option value="ca">Canada</option>
        </select>
    </div>

    {{-- Radio Buttons --}}
    <div class="form-group">
        <label>Notification Preference</label>
        <label><input type="radio" wire:model="notificationMethod" value="email"> Email</label>
        <label><input type="radio" wire:model="notificationMethod" value="sms"> SMS</label>
        <label><input type="radio" wire:model="notificationMethod" value="none"> None</label>
    </div>

    <button wire:click="saveProfile" class="btn btn-primary">Save Profile</button>
</div>
