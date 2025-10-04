---
description: "Form security directives: @csrf and @method for CSRF protection and method spoofing"
features:
  - "@csrf directive"
  - "@method directive"
  - "CSRF token generation"
  - "HTTP method spoofing"
  - "Form security"
complexity: low
---
<div class="forms-container">
    {{-- Create form with CSRF protection --}}
    <form method="POST" action="/posts" class="create-form">
        @csrf

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" id="title" name="title" required>
        </div>

        <div class="form-group">
            <label for="content">Content</label>
            <textarea id="content" name="content" rows="5" required></textarea>
        </div>

        <button type="submit">Create Post</button>
    </form>

    {{-- Update form with CSRF and method spoofing --}}
    <form method="POST" action="/posts/{{ $post->id }}" class="update-form">
        @csrf
        @method('PUT')

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" id="title" name="title" value="{{ $post->title }}" required>
        </div>

        <div class="form-group">
            <label for="content">Content</label>
            <textarea id="content" name="content" rows="5" required>{{ $post->content }}</textarea>
        </div>

        <button type="submit">Update Post</button>
    </form>

    {{-- Delete form with CSRF and method spoofing --}}
    <form method="POST" action="/posts/{{ $post->id }}" class="delete-form">
        @csrf
        @method('DELETE')

        <p>Are you sure you want to delete this post?</p>
        <button type="submit" class="btn-danger">Delete Post</button>
    </form>
</div>
