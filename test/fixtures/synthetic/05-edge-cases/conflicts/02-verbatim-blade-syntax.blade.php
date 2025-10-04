{{--
features: [verbatim, blade-directives, syntax-isolation]
complexity: medium
lines: 52
valid: true
description: @verbatim blocks containing Blade-like syntax that should NOT be parsed as Blade directives
--}}

<div class="documentation-page">
  <h1>Blade Template Syntax Guide</h1>

  <section class="syntax-examples">
    <h2>Control Structures</h2>

    <p>Here's how to use conditional statements in Blade:</p>

    @verbatim
      <div class="code-example">
        @if ($user->isAdmin())
          <p>Welcome, Administrator!</p>
        @elseif ($user->isModerator())
          <p>Welcome, Moderator!</p>
        @else
          <p>Welcome, User!</p>
        @endif
      </div>
    @endverbatim

    <h2>Loops</h2>

    <p>Iterating through collections:</p>

    @verbatim
      <ul class="user-list">
        @foreach ($users as $user)
          <li>{{ $user->name }} - {{ $user->email }}</li>
        @endforeach
      </ul>

      @forelse ($posts as $post)
        <article>
          <h3>{{ $post->title }}</h3>
          <p>{{ $post->excerpt }}</p>
        </article>
      @empty
        <p>No posts available.</p>
      @endforelse
    @endverbatim
  </section>

  <section class="live-example">
    <h2>Live Example</h2>

    @if ($posts->isNotEmpty())
      <div class="post-list">
        @foreach ($posts as $post)
          <article class="post">
            <h3>{{ $post->title }}</h3>
            <p>{{ $post->content }}</p>
          </article>
        @endforeach
      </div>
    @endif
  </section>
</div>
