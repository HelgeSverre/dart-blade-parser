{{--
features: [alpine, blade-directives, at-symbol-conflict, x-on, if]
complexity: medium
lines: 47
valid: true
description: Alpine.js @click/@keyup directives mixed with Blade @ directives testing parser disambiguation
--}}

<div x-data="{
  open: false,
  selected: null,
  items: []
}" class="dropdown-component">

  @if ($user->isAuthenticated())
    <div class="user-dropdown">
      <button
        @click="open = !open"
        @click.away="open = false"
        @keydown.escape="open = false"
        class="dropdown-trigger"
        :aria-expanded="open"
      >
        <img src="{{ $user->avatar }}" alt="{{ $user->name }}" class="avatar">
        <span>{{ $user->name }}</span>
        <svg class="icon-chevron" :class="{ 'rotate-180': open }">
          <use xlink:href="#icon-chevron-down"></use>
        </svg>
      </button>

      <div
        x-show="open"
        x-transition
        @click.outside="open = false"
        class="dropdown-menu"
      >
        @foreach ($menuItems as $item)
          <a
            href="{{ $item->url }}"
            @click="selected = '{{ $item->id }}'"
            @mouseenter="$el.classList.add('hover')"
            @mouseleave="$el.classList.remove('hover')"
            class="dropdown-item"
            :class="{ 'active': selected === '{{ $item->id }}' }"
          >
            <i class="icon-{{ $item->icon }}"></i>
            {{ $item->label }}
          </a>
        @endforeach

        <div class="dropdown-divider"></div>

        <button
          @click="logout()"
          @keydown.enter="logout()"
          class="dropdown-item text-danger"
        >
          <i class="icon-logout"></i>
          Logout
        </button>
      </div>
    </div>
  @endif
</div>

<script>
  function logout() {
    // Handle logout
  }
</script>
