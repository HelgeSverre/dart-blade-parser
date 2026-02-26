{{--
---
features:
  - volt
  - state
  - rules
  - wire_model
  - wire_submit
  - error_directive
description: Volt component with form handling and validation
complexity: moderate
--}}
<?php

use function Livewire\Volt\{state, rules};
use App\Models\Post;

state([
    'title' => '',
    'content' => '',
    'category' => '',
]);

rules([
    'title' => 'required|min:5|max:255',
    'content' => 'required|min:10',
    'category' => 'required|exists:categories,id',
]);

$save = function () {
    $this->validate();

    Post::create([
        'title' => $this->title,
        'content' => $this->content,
        'category_id' => $this->category,
    ]);

    $this->redirect('/posts');
};

?>

<form wire:submit="save">
    <div>
        <label for="title">Title</label>
        <input id="title" type="text" wire:model.live.blur="title">
        @error('title')
            <span class="text-red-500 text-sm">{{ $message }}</span>
        @enderror
    </div>

    <div>
        <label for="content">Content</label>
        <textarea id="content" wire:model.blur="content" rows="5"></textarea>
        @error('content')
            <span class="text-red-500 text-sm">{{ $message }}</span>
        @enderror
    </div>

    <div>
        <label for="category">Category</label>
        <select id="category" wire:model="category">
            <option value="">Select category</option>
            @foreach ($categories as $cat)
                <option value="{{ $cat->id }}">{{ $cat->name }}</option>
            @endforeach
        </select>
        @error('category')
            <span class="text-red-500 text-sm">{{ $message }}</span>
        @enderror
    </div>

    <button type="submit" class="data-loading:opacity-50">
        Save Post
    </button>
</form>
