{{--
features: [foreach, blade-directives, loops, malformed]
complexity: low
lines: 35
valid: false
description: Missing @endforeach directive to test parser error recovery with unclosed loop blocks
--}}

<div class="blog-posts">
  <header class="blog-header">
    <h1>Latest Blog Posts</h1>
    <p class="subtitle">Stay updated with our latest articles</p>
  </header>

  <div class="post-grid">
    @foreach ($posts as $post)
      <article class="post-card">
        <div class="post-image">
          <img src="{{ $post->featured_image }}" alt="{{ $post->title }}">
        </div>

        <div class="post-content">
          <h2 class="post-title">
            <a href="{{ route('blog.show', $post->slug) }}">{{ $post->title }}</a>
          </h2>

          <p class="post-excerpt">{{ $post->excerpt }}</p>

          <div class="post-meta">
            <span class="post-author">By {{ $post->author->name }}</span>
            <span class="post-date">{{ $post->published_at->format('M d, Y') }}</span>
            <span class="post-reading-time">{{ $post->reading_time }} min read</span>
          </div>

          <a href="{{ route('blog.show', $post->slug) }}" class="btn-read-more">Read More</a>
        </div>
      </article>
    {{-- Missing @endforeach here --}}
  </div>

  <div class="pagination">
    {{ $posts->links() }}
  </div>
</div>
