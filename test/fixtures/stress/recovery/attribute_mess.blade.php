@foreach($items as $item)
<div class="panel" ????
     data-meta={!! json_encode($meta) !!}
     @if($show)
        data-visible
@endfor
  <span>Ready {{ $item }}</span>
<div>
  <p>Broken tag-heads @endif</p>
