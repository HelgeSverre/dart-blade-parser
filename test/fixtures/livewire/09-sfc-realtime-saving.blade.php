{{--
---
features:
  - livewire_v4_sfc
  - validate_attribute
  - wire_model_live_blur
  - wire_dirty_class
  - updated_lifecycle
  - blade_error
description: Livewire v4 SFC real-time saving pattern using wire:model.live.blur and updated() lifecycle hook
complexity: simple
--}}
<?php

use Livewire\Attributes\Validate;
use Livewire\Component;
use App\Models\Post;

new class extends Component {
    public Post $post;

    #[Validate('required')]
    public $title = '';

    #[Validate('required')]
    public $content = '';

    public function mount(Post $post)
    {
        $this->post = $post;
        $this->title = $post->title;
        $this->content = $post->content;
    }

    public function updated($name, $value)
    {
        $this->post->update([
            $name => $value,
        ]);
    }
}; ?>

<form wire:submit>
    <input type="text" wire:model.live.blur="title" wire:dirty.class="border-yellow">
    <div>
        @error('title')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>

    <textarea wire:model.live.blur="content" wire:dirty.class="border-yellow"></textarea>
    <div>
        @error('content')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
</form>
