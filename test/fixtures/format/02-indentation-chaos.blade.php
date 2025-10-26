<div>
@if($user)
<p>{{ $user->name }}</p>
        @foreach($items as $item)
    <span>{{ $item }}</span>
    @endforeach
@endif
</div>
