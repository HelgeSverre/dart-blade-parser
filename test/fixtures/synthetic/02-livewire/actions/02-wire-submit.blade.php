{{-- Livewire wire:submit form examples --}}
<div>
    {{-- Basic login form --}}
    <form wire:submit="login">
        <h2>Login</h2>

        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" wire:model="email" id="email" required>
            @error('email')
                <span class="error">{{ $message }}</span>
            @enderror
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" wire:model="password" id="password" required>
            @error('password')
                <span class="error">{{ $message }}</span>
            @enderror
        </div>

        <button type="submit" wire:loading.attr="disabled">
            <span wire:loading.remove wire:target="login">Login</span>
            <span wire:loading wire:target="login">Logging in...</span>
        </button>
    </form>

    {{-- Post creation form --}}
    <form wire:submit.prevent="createPost" class="post-form">
        <h2>Create New Post</h2>

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" wire:model.defer="title" id="title">
            @error('title') <span class="text-red-500">{{ $message }}</span> @enderror
        </div>

        <div class="form-group">
            <label for="content">Content</label>
            <textarea wire:model.defer="content" id="content" rows="5"></textarea>
            @error('content') <span class="text-red-500">{{ $message }}</span> @enderror
        </div>

        <div class="form-group">
            <label for="category">Category</label>
            <select wire:model="category" id="category">
                <option value="">Select category</option>
                <option value="news">News</option>
                <option value="tutorial">Tutorial</option>
            </select>
            @error('category') <span class="text-red-500">{{ $message }}</span> @enderror
        </div>

        <button type="submit">
            Publish Post
        </button>
        <span wire:loading wire:target="createPost">Saving...</span>
    </form>
</div>
