---
description: "@forelse loop with empty state handling for blog posts"
tags: ["forelse", "empty-state", "posts", "blog"]
---
<div class="blog-container">
    <header class="blog-header">
        <h1>Latest Blog Posts</h1>
        <p class="subtitle">Stay updated with our latest articles and insights</p>
    </header>

    <div class="posts-grid">
        @forelse($posts as $post)
        <article class="post-card">
            <div class="post-thumbnail">
                <img src="{{ $post->featured_image }}" alt="{{ $post->title }}">
                <div class="post-meta-overlay">
                    <time datetime="{{ $post->published_at }}">
                        {{ $post->published_at->format('M d, Y') }}
                    </time>
                </div>
            </div>

            <div class="post-content">
                <div class="post-categories">
                    @foreach($post->categories as $category)
                    <span class="category-badge">{{ $category }}</span>
                    @endforeach
                </div>

                <h2 class="post-title">
                    <a href="{{ route('posts.show', $post->slug) }}">{{ $post->title }}</a>
                </h2>

                <p class="post-excerpt">{{ $post->excerpt }}</p>

                <div class="post-footer">
                    <div class="author-info">
                        <img src="{{ $post->author->avatar }}" alt="{{ $post->author->name }}" class="author-avatar">
                        <span class="author-name">{{ $post->author->name }}</span>
                    </div>

                    <div class="post-stats">
                        <span class="stat-item">
                            <i class="icon-eye"></i> {{ $post->views_count }}
                        </span>
                        <span class="stat-item">
                            <i class="icon-comment"></i> {{ $post->comments_count }}
                        </span>
                    </div>
                </div>
            </div>
        </article>
        @empty
        <div class="empty-state">
            <div class="empty-icon">
                <svg width="120" height="120" viewBox="0 0 120 120">
                    <circle cx="60" cy="60" r="50" fill="#f0f0f0"/>
                </svg>
            </div>
            <h3 class="empty-title">No Posts Available</h3>
            <p class="empty-message">
                We haven't published any posts yet. Check back soon for new content!
            </p>
            <a href="{{ route('home') }}" class="btn btn-primary">Return to Home</a>
        </div>
        @endforelse
    </div>
</div>
