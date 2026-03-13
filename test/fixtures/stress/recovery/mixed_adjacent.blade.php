@php
  \$status = 'partial';
  function greet(\$name) {
    return \"Hello, \$name\";
  }
@endphp

<x-dashboard ??? class="bg" data-state="{{ \$status }}">
  <x-card>
    <x-slot:header>
      <h1>Mixed Recovery</h1>
    </x-slot:header>
    <x-slot:body>
      <?php echo greet('guest') ?>
      @foreach(\$items as \$item)
        <p>{{ \$item }}</p>
      @else
        <p>No items yet</p>
    </x-slot:body>
  </x-card-body>
  <x-spotlight
    @if(\$status === 'partial')
      highlighted
  @endif
    data-flag=?? broken
  >
    <x-widget>
      <p>Widget content</p>
    </x-spotlight>
  </x-spotlight>
  @endforelse
</x-dashboard-->
