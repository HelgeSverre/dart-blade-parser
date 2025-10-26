<div class="dashboard">
@foreach($items as $item)
@if($item->isActive())
<div class="item"><h3>{{$item->title}}</h3>
<p>{{$item->description}}</p></div>
@endif
@endforeach
@while($count>0)
<p>Count: {{$count}}</p>
@endwhile
</div>
