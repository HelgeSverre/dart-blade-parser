{{--
---
features:
  - volt
  - state
  - wire_model
  - wire_click
description: Basic Volt component with state and actions
complexity: simple
--}}
<?php

use function Livewire\Volt\{state, computed};

state(['count' => 0]);

$increment = fn () => $this->count++;
$decrement = fn () => $this->count--;

?>

<div>
    <h1>Counter: {{ $count }}</h1>
    <button wire:click="increment">+</button>
    <button wire:click="decrement">-</button>
</div>
