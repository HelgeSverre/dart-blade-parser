{{-- Livewire miscellaneous wire: attribute examples --}}
<div>
    {{-- wire:init - run action when component is initialized --}}
    <div wire:init="loadPosts">
        <span wire:loading wire:target="loadPosts">Loading posts...</span>
        @foreach($posts as $post)
            <div wire:key="post-{{ $post->id }}">{{ $post->title }}</div>
        @endforeach
    </div>

    {{-- wire:offline - show element when browser is offline --}}
    <div wire:offline>
        You are currently offline.
    </div>

    {{-- wire:offline.class - add class when offline --}}
    <div wire:offline.class="bg-red-100 text-red-800">
        Connection Status
    </div>

    {{-- wire:offline.attr - set attribute when offline --}}
    <button wire:click="save" wire:offline.attr="disabled">
        Save Changes
    </button>

    {{-- wire:ignore - exclude element from Livewire DOM diffing --}}
    <div wire:ignore>
        <select id="select2" class="select2">
            @foreach($options as $option)
                <option value="{{ $option->id }}">{{ $option->name }}</option>
            @endforeach
        </select>
    </div>

    {{-- wire:ignore.self - ignore only the element itself, not children --}}
    <div wire:ignore.self class="chart-container" data-chart-type="line">
        <div>{{ $chartLabel }}</div>
    </div>

    {{-- wire:replace - force replace element on update --}}
    <div wire:replace>
        <canvas id="canvas-{{ $canvasId }}"></canvas>
    </div>

    {{-- wire:replace.self - replace self only --}}
    <div wire:replace.self id="widget-{{ $widgetId }}">
        {{ $widgetContent }}
    </div>

    {{-- wire:transition - animate element changes --}}
    <div wire:transition>
        @if($showPanel)
            <div class="panel">{{ $panelContent }}</div>
        @endif
    </div>

    {{-- wire:transition with named transition --}}
    <div wire:transition="slide-up">
        @if($showNotification)
            <div class="notification">{{ $message }}</div>
        @endif
    </div>

    {{-- wire:key - unique key for element tracking --}}
    @foreach($items as $item)
        <div wire:key="item-{{ $item->id }}">
            {{ $item->name }}
        </div>
    @endforeach

    {{-- wire:dirty - show element when form is dirty --}}
    <form wire:submit="save">
        <input type="text" wire:model="title">
        <span wire:dirty>Unsaved changes</span>
        <span wire:dirty.remove>All changes saved</span>
        <button wire:dirty.class="bg-yellow-500" type="submit">Save</button>
    </form>

    {{-- wire:show - conditionally show elements --}}
    <div wire:show="$showDetails">
        <p>{{ $details }}</p>
    </div>

    {{-- wire:show with $dirty --}}
    <div wire:show="$dirty">
        You have unsaved changes.
    </div>

    {{-- wire:show with $dirty for specific field --}}
    <div wire:show="$dirty('email')">
        Email has been modified.
    </div>

    {{-- wire:text - bind text content --}}
    <span wire:text="title"></span>

    {{-- wire:bind:class - dynamic class binding --}}
    <div wire:bind:class="containerClasses">
        Dynamic class content
    </div>

    {{-- wire:bind:disabled - dynamic disabled binding --}}
    <button wire:bind:disabled="isProcessing">
        Submit
    </button>

    {{-- wire:ref - reference element from component --}}
    <input type="text" wire:ref="searchInput" wire:model="query">
    <button wire:click="focusSearch">Focus Search</button>

    {{-- wire:cloak - hide element until Livewire initializes --}}
    <div wire:cloak>
        This content is hidden until Livewire loads.
    </div>

    {{-- wire:intersect - trigger action when element enters viewport --}}
    <div wire:intersect="loadMorePosts">
        <div class="loading-trigger"></div>
    </div>

    {{-- wire:intersect.once - only trigger once --}}
    <div wire:intersect.once="trackImpression({{ $ad->id }})">
        <img src="{{ $ad->image }}" alt="{{ $ad->title }}">
    </div>

    {{-- wire:intersect.half - trigger when 50% visible --}}
    <div wire:intersect.half="markAsRead({{ $article->id }})">
        <p>{{ $article->excerpt }}</p>
    </div>

    {{-- wire:intersect:enter - trigger on enter --}}
    <div wire:intersect:enter="startAnimation">
        <div class="animated-content">{{ $content }}</div>
    </div>

    {{-- wire:intersect:leave - trigger on leave --}}
    <div wire:intersect:leave="pauseVideo">
        <video src="{{ $videoUrl }}"></video>
    </div>

    {{-- wire:island - lazy load an isolated component --}}
    <div wire:island>
        <livewire:heavy-component />
    </div>
</div>