{{-- Single-file component pattern with PHP class block at top --}}
<?php

use Livewire\Component;
use Livewire\Attributes\Computed;

new class extends Component {
    public string $search = '';
    public int $perPage = 10;

    #[Computed]
    public function results()
    {
        return Post::where('title', 'like', "%{$this->search}%")
            ->paginate($this->perPage);
    }

    public function updatedSearch()
    {
        $this->resetPage();
    }
}; ?>

<div>
    <input type="text" wire:model.live.debounce.300ms="search" placeholder="Search...">

    @foreach($this->results as $post)
        <article wire:key="post-{{ $post->id }}">
            <h2>{{ $post->title }}</h2>
            <p>{{ $post->excerpt }}</p>
        </article>
    @endforeach

    {{ $this->results->links() }}
</div>
