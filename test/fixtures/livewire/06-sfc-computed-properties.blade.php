{{--
---
features:
  - livewire_v4_sfc
  - computed_attribute
  - wire_model_live_debounce
  - wire_key
  - wire_navigate
  - foreach_empty
description: Livewire v4 SFC with computed properties using #[Computed] attribute and debounced search
complexity: simple
--}}
<?php

use Livewire\Attributes\Computed;
use Livewire\Component;
use App\Models\Post;

new class extends Component {
    public string $search = '';

    #[Computed]
    public function posts()
    {
        return Post::where('title', 'like', '%' . $this->search . '%')
            ->latest()
            ->get();
    }
}; ?>

<div>
    <input type="text" wire:model.live.debounce.300ms="search" placeholder="Search posts...">

    @forelse ($this->posts as $post)
        <article wire:key="{{ $post->id }}">
            <h2>{{ $post->title }}</h2>
            <p>{{ $post->excerpt }}</p>
            <a href="/posts/{{ $post->slug }}" wire:navigate>Read more</a>
        </article>
    @empty
        <p>No posts found.</p>
    @endforelse
</div>
