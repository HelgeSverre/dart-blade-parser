{{--
---
features:
  - livewire_v4_sfc
  - route_model_binding
  - locked_attribute
  - wire_submit
  - wire_model
  - blade_error
  - session_flash
description: Livewire v4 SFC page component with route model binding and #[Locked] attribute
complexity: moderate
--}}
<?php

use Livewire\Attributes\Locked;
use Livewire\Component;
use App\Models\Post;

new class extends Component {
    public Post $post;
    public string $title = '';
    public string $content = '';

    public function mount(Post $post)
    {
        $this->post = $post;
        $this->title = $post->title;
        $this->content = $post->content;
    }

    public function update()
    {
        $this->authorize('update', $this->post);

        $this->validate([
            'title' => 'required|max:255',
            'content' => 'required',
        ]);

        $this->post->update([
            'title' => $this->title,
            'content' => $this->content,
        ]);

        session()->flash('message', 'Post updated successfully!');
    }
}; ?>

<form wire:submit="update">
    <input type="text" wire:model="title">
    @error('title')
        <span class="error">{{ $message }}</span>
    @enderror

    <textarea wire:model="content"></textarea>
    @error('content')
        <span class="error">{{ $message }}</span>
    @enderror

    <button type="submit" class="data-loading:opacity-50">
        Update Post
    </button>

    @if (session('message'))
        <div class="alert alert-success">
            {{ session('message') }}
        </div>
    @endif
</form>
