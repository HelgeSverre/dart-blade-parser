{{--
---
features:
  - livewire_v4_sfc
  - livewire_form_object
  - wire_model_live_blur
  - validate_attribute
  - wire_loading
  - blade_error
description: Livewire v4 SFC using Form Object pattern with real-time validation and loading states
complexity: moderate
--}}
<?php

use Livewire\Attributes\Validate;
use Livewire\Component;
use App\Livewire\Forms\PostForm;
use App\Models\Post;

new class extends Component {
    public PostForm $form;

    public function mount(Post $post = null)
    {
        if ($post) {
            $this->form->setPost($post);
        }
    }

    public function save()
    {
        $this->form->store();

        session()->flash('success', 'Post saved successfully!');

        return $this->redirect('/posts');
    }
}; ?>

<div>
    <h1>{{ $this->form->post ? 'Edit' : 'Create' }} Post</h1>

    @if (session('success'))
        <div class="alert alert-success">
            {{ session('success') }}
        </div>
    @endif

    <form wire:submit="save">
        <div>
            <label for="title">Title</label>
            <input
                type="text"
                id="title"
                wire:model.live.blur="form.title"
                class="@error('form.title') border-red-500 @enderror"
            >
            @error('form.title')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div>
            <label for="slug">Slug</label>
            <input
                type="text"
                id="slug"
                wire:model.blur="form.slug"
                class="@error('form.slug') border-red-500 @enderror"
            >
            @error('form.slug')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div>
            <label for="content">Content</label>
            <textarea
                id="content"
                wire:model.live.blur="form.content"
                rows="10"
                class="@error('form.content') border-red-500 @enderror"
            ></textarea>
            @error('form.content')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div>
            <label for="category">Category</label>
            <select wire:model="form.category_id" id="category">
                <option value="">Select a category</option>
                @foreach ($this->form->categories() as $category)
                    <option value="{{ $category->id }}">{{ $category->name }}</option>
                @endforeach
            </select>
            @error('form.category_id')
                <span class="text-red-500 text-sm">{{ $message }}</span>
            @enderror
        </div>

        <div>
            <label>
                <input type="checkbox" wire:model="form.is_published">
                Publish immediately
            </label>
        </div>

        <button type="submit" wire:loading.attr="disabled" wire:loading.class="opacity-50">
            <span wire:loading.remove>Save Post</span>
            <span wire:loading>Saving...</span>
        </button>
    </form>
</div>
