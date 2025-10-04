{{--
features: [if, elseif, else, blade-directives, control-structures, nested-conditions]
complexity: high
lines: 43
valid: true
description: Complex nested conditionals for post publication and editing workflow
--}}

<article class="post-detail">
  <header class="post-header">
    <h1>{{ $post->title }}</h1>

    @if ($post->isPublished())
      <div class="post-meta">
        <span class="publish-date">Published {{ $post->published_at->diffForHumans() }}</span>

        @if (auth()->check())
          @if ($post->author_id === auth()->id())
            {{-- Author can always edit their own posts --}}
            <div class="author-actions">
              <a href="{{ route('posts.edit', $post->id) }}" class="btn btn-sm btn-primary">Edit Post</a>

              @if ($post->comments_count > 0)
                <a href="{{ route('posts.moderate', $post->id) }}" class="btn btn-sm btn-secondary">
                  Moderate Comments ({{ $post->comments_count }})
                </a>
              @else
                <span class="text-muted">No comments yet</span>
              @endif
            </div>
          @elseif (auth()->user()->isAdmin() || auth()->user()->isModerator())
            {{-- Staff can edit and moderate any post --}}
            <div class="staff-actions">
              <a href="{{ route('admin.posts.edit', $post->id) }}" class="btn btn-sm btn-warning">Admin Edit</a>

              @if ($post->reports_count > 0)
                <a href="{{ route('admin.posts.reports', $post->id) }}" class="btn btn-sm btn-danger">
                  Review Reports ({{ $post->reports_count }})
                </a>
              @endif
            </div>
          @endif
        @endif
      </div>
    @else
      <div class="alert alert-warning">
        <strong>Draft:</strong> This post is not yet published.
      </div>
    @endif
  </header>
</article>
