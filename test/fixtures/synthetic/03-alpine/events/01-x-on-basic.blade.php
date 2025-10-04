{{-- Alpine.js Basic Event Handling: x-on and @ shorthand --}}
<div x-data="{
    count: 0,
    message: '',
    submitted: false,
    username: '',
    items: []
}">
    {{-- Click events with @ shorthand --}}
    <button @click="count++">
        Clicked {{ count }} times
    </button>

    <button x-on:click="count = 0" class="reset">
        Reset Counter
    </button>

    {{-- Form submission --}}
    <form @submit="submitted = true; $event.preventDefault()">
        <input
            type="text"
            @input="username = $event.target.value"
            placeholder="Enter username"
        >
        <button type="submit">Submit</button>
        <p x-show="submitted">Form submitted: {{ username }}</p>
    </form>

    {{-- Multiple event types --}}
    <div
        @mouseenter="message = 'Mouse entered'"
        @mouseleave="message = ''"
        @dblclick="items.push('Item ' + (items.length + 1))"
    >
        Hover or double-click me
        <p x-text="message"></p>
    </div>

    <ul>
        <template x-for="item in items">
            <li x-text="item"></li>
        </template>
    </ul>
</div>
