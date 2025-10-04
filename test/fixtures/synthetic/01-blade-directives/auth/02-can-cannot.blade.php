---
description: "Authorization directives: @can and @cannot for permission-based rendering"
features:
  - "@can directive"
  - "@cannot directive"
  - "@endcan/@endcannot"
  - "@canany directive"
  - "Policy-based authorization"
  - "Model-based permissions"
complexity: medium
---
<div class="post-container">
    <article class="post">
        <h1>{{ $post->title }}</h1>
        <p class="author">By {{ $post->author->name }}</p>

        <div class="post-content">
            {{ $post->content }}
        </div>

        <div class="post-actions">
            @can('update', $post)
                <a href="/posts/{{ $post->id }}/edit" class="btn btn-primary">
                    Edit Post
                </a>
            @endcan

            @can('delete', $post)
                <form method="POST" action="/posts/{{ $post->id }}">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-danger">Delete</button>
                </form>
            @endcan

            @cannot('update', $post)
                <p class="text-muted">You don't have permission to edit this post.</p>
            @endcannot
        </div>
    </article>

    <aside class="post-sidebar">
        @canany(['create', 'update', 'delete'], $post)
            <div class="admin-tools">
                <h3>Admin Tools</h3>

                @can('publish', $post)
                    <button class="btn-publish">Publish</button>
                @endcan

                @can('feature', $post)
                    <button class="btn-feature">Feature Post</button>
                @endcan
            </div>
        @endcanany

        @can('moderate-comments')
            <div class="moderation-panel">
                <h3>Comment Moderation</h3>
                <button>Review Comments</button>
            </div>
        @endcan
    </aside>
</div>
