<div class="dashboard"  >
    @foreach($widgets as $widget )
        @if  (  $widget->isVisible()  )
<div   class="widget">
                <h3>{{ $widget->title }}</h3>
            <p>{{$widget->description}}</p>
        </div>
        @endif
    @endforeach
</div>
