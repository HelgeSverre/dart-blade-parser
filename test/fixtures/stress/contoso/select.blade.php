@props([
    'name',
    'required' => false,
    'readonly' => false,
    'disabled' => false,
    'label' => null,
    'placeholder',
    'options' => [],
])

@isset($label)
    <label for="{{ $name }}" class="block text-sm font-medium text-gray-700">
        {{ $label }}
    </label>
@endif

<select
    name="{{ $name }}"
    id="{{ $name }}"
    {{ $attributes }}
    @if($readonly) readonly @endif
    @if($disabled) disabled @endif
    @if($required) required @endif
    @class([
        'block w-full rounded-md border-gray-300 bg-white py-2 pl-3 pr-10 text-base text-gray-700 focus:border-navy-500 focus:outline-none focus:ring-navy-500 sm:text-sm',
        'border-gray-300 focus:border-navy-500 focus:ring-navy-500' => ! $errors->has($name),
        'border-red-500 focus:border-red-500 focus:ring-red-500' => $errors->has($name),
        'mt-1' => filled($label),
    ])
>
    @isset($placeholder)
        <option value="">{{ $placeholder }}</option>
    @endisset

    @foreach ($options as $option)
        <option
            value="{{ $option['value'] ?? null }}"
            {{ $option['value'] == old($name, $attributes['value'] ?? '') ? 'selected' : '' }}
        >
            {{ $option['label'] }}
        </option>
    @endforeach
</select>

@error($name)
    <div class="mt-2 text-xs text-red-500">{{ $message }}</div>
@enderror
