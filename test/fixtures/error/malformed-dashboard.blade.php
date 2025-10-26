<div class="dashboard">
    @foreach($widgets as $widget)
        @ifaasdf($widget->isVisible())
            <div class="widget">
                <h3>{{ $widget
->title }}</h3>




                <p>{{ $widget->content }}</p>
            </div>
        @endif
    @endforeach

    @while($count > 0)
        <p>Count: {{ $count }}</p>
    @endwhile
</div>
