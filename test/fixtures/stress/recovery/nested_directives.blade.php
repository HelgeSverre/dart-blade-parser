@extends('dashboard')

@section('content')
  @if($user)
    <div>
      <p>Welcome, {{ $user->name }}
      @foreach($user->notifications as $note)
        <span>{{ $note->message }}</span>
      @else
        <span>No notifications</span>
  @endsection

@section('sidebar')
  <x-panel>
    <p>Sidebar info</p>
@endforeach

@show
