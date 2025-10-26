{{--
  Example demonstrating @overwrite directive (deprecated in Laravel 7+)
  @overwrite was used in Laravel 4.x/5.x to completely replace a parent section
--}}

@extends('layouts.master')

{{-- Standard section with @endsection --}}
@section('title')
Child Page Title
@endsection

{{-- Section with @show to define and immediately display --}}
@section('sidebar')
<div class="sidebar">
	<h3>Sidebar Content</h3>
	<p>This is shown immediately</p>
</div>
@show

{{-- Section with @overwrite (legacy Laravel 4.x/5.x) --}}
@section('footer')
<footer>
	<p>This completely overwrites the parent footer section</p>
	<p>&copy; {{ date('Y') }} - Overwritten Footer</p>
</footer>
@overwrite

{{-- Main content section --}}
@section('content')
<div class="content">
	<h1>Welcome</h1>

	@if($user)
		<p>Hello, {{ $user->name }}!</p>
	@else
		<p>Please log in</p>
	@endif

	@foreach($items as $item)
		<div class="item">
			<h2>{{ $item->title }}</h2>
			<p>{{ $item->description }}</p>
		</div>
	@endforeach
</div>
@endsection
