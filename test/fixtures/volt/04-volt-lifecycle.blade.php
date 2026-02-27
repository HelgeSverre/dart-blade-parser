{{--
---
features:
  - volt
  - mount
  - booted
  - updated
  - state
  - on
description: Volt component with lifecycle hooks and event listeners
complexity: moderate
--}}
<?php

use function Livewire\Volt\{state, mount, booted, updated, on};
use App\Models\Post;

state([
    'post' => null,
    'title' => '',
    'content' => '',
    'lastSaved' => null,
]);

mount(function (Post $post) {
    $this->post = $post;
    $this->title = $post->title;
    $this->content = $post->content;
});

updated(['title' => function ($value) {
    $this->post->update(['title' => $value]);
    $this->lastSaved = now();
}]);

on(['post-updated' => function () {
    $this->post->refresh();
    $this->title = $this->post->title;
    $this->content = $this->post->content;
}]);

$save = function () {
    $this->post->update([
        'title' => $this->title,
        'content' => $this->content,
    ]);
    $this->lastSaved = now();
    $this->dispatch('post-updated');
};

?>

<div>
    <form wire:submit="save">
        <input type="text" wire:model.live.blur="title" wire:dirty.class="border-yellow-500">
        <textarea wire:model.blur="content" wire:dirty.class="border-yellow-500"></textarea>

        <div class="flex items-center gap-4">
            <button type="submit">Save</button>
            @if ($lastSaved)
                <span class="text-sm text-gray-500">
                    Last saved: {{ $lastSaved->diffForHumans() }}
                </span>
            @endif
        </div>
    </form>
</div>
