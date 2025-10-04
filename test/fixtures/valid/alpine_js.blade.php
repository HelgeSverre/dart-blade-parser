<div x-data="{ open: false }" class="dropdown">
    <button @click="open = !open">Toggle</button>
    <div x-show="open" x-transition>
        <a href="#" :class="{ 'active': isActive }">Link</a>
    </div>
</div>
