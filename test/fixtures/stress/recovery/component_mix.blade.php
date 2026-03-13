<x-layout>
  <x-card>
    <x-slot:title>
      {{ $title ?? 'Untitled' }}
    </x-slot:title>
    <x-card-body>
      <p>Active: {{ $active ? 'yes' : 'no' }}</p>
  </x-card>
  <x-widget @if($active) disabled @endif>
    <x-slot:body>
      <div unknown-attr=??>
        <p>Widget details</p>
    </x-slot:body>
  </x-widget>
  </x-card>
</x-layout-->
