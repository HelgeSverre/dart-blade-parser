{{-- Structural directives inside HTML opening tags --}}

{{-- Simple @if in tag --}}
<div
    class="base"
    @if($active)
        data-active="true"
    @endif
>
    Content
</div>

{{-- @if/@else in tag --}}
<button
    type="button"
    @if($primary)
        class="btn-primary"
    @else
        class="btn-secondary"
    @endif
>
    Click me
</button>

{{-- @foreach generating attributes --}}
<div
    @foreach($dataAttrs as $key => $value)
        data-{{ $key }}="{{ $value }}"
    @endforeach
>
    Dynamic attributes
</div>

{{-- Multiple structural directives in one tag --}}
<input
    type="text"
    name="field"
    @if($hasError)
        class="border-red-500"
        aria-invalid="true"
    @endif
    @if($disabled)
        disabled
    @endif
>

{{-- Structural directives mixed with attribute directives --}}
<div
    @class(['card', 'highlighted' => $featured])
    @if($hasBorder)
        style="border: 1px solid #ccc;"
    @endif
    @style(['padding: 2rem' => $padded])
>
    Mixed content
</div>

{{-- Structural directives in component tags --}}
<x-button
    type="submit"
    @if($loading)
        wire:loading.attr="disabled"
        wire:target="save"
    @endif
    @class(['btn', 'btn-lg' => $large])
>
    Save
</x-button>

{{-- Nested structural directives in tag (contrived but valid) --}}
<div
    class="wrapper"
    @if($theme === 'dark')
        @if($highContrast)
            style="background: #000; color: #fff;"
        @else
            style="background: #1a1a1a; color: #eee;"
        @endif
    @endif
>
    Themed content
</div>

{{-- Self-closing tag with structural directive --}}
<img
    src="{{ $image->url }}"
    @if($image->alt)
        alt="{{ $image->alt }}"
    @endif
/>

{{-- Void element with structural directive --}}
<input
    type="checkbox"
    @checked($isChecked)
    @if($autoFocus)
        autofocus
    @endif
>

{{-- Void element with structural directive --}}
<input
    type="checkbox"
    @checked($isChecked)
    @if($autoFocus)
        autofocus
    @endif
>
