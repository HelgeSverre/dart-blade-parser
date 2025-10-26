<div x-data="{ open: false }"   class="container">
@if($user)
<button   @click="open = !open"  >Toggle</button>
<div  x-show="open">
{{$user->name}}
</div>
@endif
</div>
