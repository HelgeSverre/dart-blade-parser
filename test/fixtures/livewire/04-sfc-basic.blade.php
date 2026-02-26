{{--
---
features:
  - livewire_v4_sfc
  - wire_submit
  - wire_model
  - blade_error
  - blade_directives
description: Basic Livewire v4 single-file component with PHP class and Blade template in one file
complexity: simple
--}}
<?php

use Livewire\Component;

new class extends Component {
    public string $title = '';
    public string $content = '';

    public function save()
    {
        $this->validate([
            'title' => 'required|max:255',
            'content' => 'required',
        ]);

        Post::create([
            'title' => $this->title,
            'content' => $this->content,
        ]);

        return $this->redirect('/posts');
    }
}; ?>

<form wire:submit="save">
    <label>
        Title
        <input type="text" wire:model="title">
        @error('title')
            <span style="color: red;">{{ $message }}</span>
        @enderror
    </label>

    <label>
        Content
        <textarea wire:model="content" rows="5"></textarea>
        @error('content')
            <span style="color: red;">{{ $message }}</span>
        @enderror
    </label>

    <button type="submit">Save Post</button>
</form>
