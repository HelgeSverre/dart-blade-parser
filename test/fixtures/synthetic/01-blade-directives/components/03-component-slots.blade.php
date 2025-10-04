{{-- Component with Named Slots --}}
{{-- Component Definition: resources/views/components/card.blade.php --}}
@props(['padding' => true, 'elevated' => false])

<div {{ $attributes->merge([
    'class' => 'card rounded-lg bg-white ' .
               ($elevated ? 'shadow-lg' : 'shadow') .
               ($padding ? ' p-6' : '')
]) }}>
    @if(isset($header))
        <div class="card-header border-b border-gray-200 pb-4 mb-4">
            {{ $header }}
        </div>
    @endif

    <div class="card-body">
        {{ $slot }}
    </div>

    @if(isset($footer))
        <div class="card-footer border-t border-gray-200 pt-4 mt-4">
            {{ $footer }}
        </div>
    @endif
</div>

{{-- Component Usage Examples --}}
<div class="grid gap-6">
    {{-- Card with all slots --}}
    <x-card elevated="true" class="max-w-lg">
        <x-slot:header>
            <h3 class="text-xl font-bold">User Profile</h3>
            <p class="text-gray-600 text-sm">Manage your account settings</p>
        </x-slot:header>

        <div class="space-y-4">
            <div class="field">
                <label>Name</label>
                <input type="text" value="John Doe" class="input" />
            </div>
            <div class="field">
                <label>Email</label>
                <input type="email" value="john@example.com" class="input" />
            </div>
        </div>

        <x-slot:footer>
            <div class="flex justify-between">
                <x-button variant="outline">Cancel</x-button>
                <x-button variant="primary">Save Changes</x-button>
            </div>
        </x-slot:footer>
    </x-card>

    {{-- Card with only default slot --}}
    <x-card :padding="false" class="max-w-md">
        <img src="/images/banner.jpg" class="w-full h-48 object-cover rounded-t-lg" />
        <div class="p-6">
            <h4 class="font-semibold text-lg mb-2">Featured Article</h4>
            <p class="text-gray-700">This is the main content of the card.</p>
        </div>
    </x-card>
</div>
