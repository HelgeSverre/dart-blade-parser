<div
    class="container"
    @if($dark)
        style="background: #333"
    @endif
    @foreach($classes as $cls)
        data-class="{{ $cls }}"
    @endforeach
>
    <p>Content with directives in tag head</p>
</div>

<x-button
    type="submit"
    @disabled($loading)
    @class(['btn', 'btn-primary' => $primary])
    ???broken-attr
    @if($icon)
        data-icon="{{ $icon }}"
>
    {{ $label }}
</x-button>

<input
    type="text"
    @readonly($locked)
    name="field"
    value=???
    @required($mandatory)
>

@if($showFooter)
    <footer>Footer content</footer>
