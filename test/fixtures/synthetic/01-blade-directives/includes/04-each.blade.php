---
description: "The @each directive for rendering collections with optional empty state"
features:
  - "@each directive"
  - "Collection rendering"
  - "Empty state handling"
  - "Iterator variables"
complexity: medium
---
<div class="products-grid">
    <h2>Featured Products</h2>

    {{-- Render each product using product-card partial --}}
    @each('components.product-card', $products, 'product', 'components.no-products')
</div>

<div class="team-members">
    <h2>Our Team</h2>

    <div class="members-list">
        {{-- Render each team member with empty state --}}
        @each('partials.team-member', $teamMembers, 'member', 'partials.empty-team')
    </div>
</div>

<div class="blog-posts">
    <h2>Latest Articles</h2>

    <div class="posts-container">
        {{-- Render blog posts with fallback for empty state --}}
        @each('blog.post-preview', $posts, 'post', 'blog.no-posts')
    </div>
</div>

<div class="comments-section">
    <h3>Comments ({{ count($comments) }})</h3>

    <div class="comments-list">
        {{-- Render comments with empty message --}}
        @each('comments.comment-item', $comments, 'comment', 'comments.no-comments')
    </div>
</div>

<div class="order-history">
    <h2>Your Orders</h2>

    {{-- Render order history with empty state --}}
    @each('orders.order-row', $orders, 'order', 'orders.no-orders')
</div>
