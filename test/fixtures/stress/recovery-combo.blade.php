@extends('layout')

@section('content')
  <x-card ???>
    <div><span>Highlights</div>
  </x-panel>
@endsection

@else
  <p>Visitors only</p>
@endif

@foreach($items as $item)
  <li>{{ $item }}</li>
