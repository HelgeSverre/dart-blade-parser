<div x-data="{ count: 0 }">
    <button @click="count++">Increment</button>
    <span :class="{ 'text-red': count > 5 }">{{ count }}</span>
</div>

@if($blade_directive)
    <p>This @ is a Blade directive</p>
@endif
