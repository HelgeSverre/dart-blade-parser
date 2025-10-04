{{-- Parent Layout: marketing.blade.php --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('meta-title', 'Marketing Site')</title>
    <meta name="description" content="@yield('meta-description', 'Default marketing description')">

    <link rel="stylesheet" href="/css/marketing.css">
    <link rel="stylesheet" href="/css/animations.css">
    @yield('head-styles')
</head>
<body>
    <header class="hero-header">
        @yield('hero-section')
    </header>

    <nav class="top-navigation">
        <ul class="nav-links">
            <li><a href="/">Home</a></li>
            <li><a href="/features">Features</a></li>
            <li><a href="/pricing">Pricing</a></li>
            @yield('additional-nav-items')
        </ul>
    </nav>

    <main class="page-content">
        @yield('main-content')
    </main>

    <section class="call-to-action">
        @yield('cta-section')
    </section>

    <footer class="site-footer">
        <div class="footer-content">
            <div class="footer-links">
                <a href="/about">About</a>
                <a href="/contact">Contact</a>
                <a href="/privacy">Privacy</a>
            </div>
            @yield('footer-extras')
        </div>
    </footer>

    <script src="/js/vendor.js"></script>
    @yield('footer-scripts')
</body>
</html>

{{-- Child Template: product-page.blade.php --}}
@extends('layouts.marketing')

@section('meta-title', 'Premium Features - Our Product')

@section('meta-description', 'Discover our premium features designed to boost your productivity')

@section('head-styles')
    @parent
    <link rel="stylesheet" href="/css/product.css">
    <link rel="stylesheet" href="/css/pricing-table.css">
@endsection

@section('hero-section')
    <div class="hero-content">
        <h1>Transform Your Workflow</h1>
        <p class="hero-subtitle">Experience the next generation of productivity tools</p>
        <button class="cta-button">Get Started Free</button>
    </div>
@endsection

@section('additional-nav-items')
    @parent
    <li><a href="/demo">Live Demo</a></li>
    <li><a href="/resources">Resources</a></li>
@endsection

@section('main-content')
    <section class="features-grid">
        <h2>Powerful Features</h2>
        <div class="feature-cards">
            <div class="feature-card">
                <h3>Real-time Collaboration</h3>
                <p>Work together seamlessly with your team</p>
            </div>
            <div class="feature-card">
                <h3>Advanced Analytics</h3>
                <p>Get insights that drive better decisions</p>
            </div>
            <div class="feature-card">
                <h3>Enterprise Security</h3>
                <p>Bank-grade encryption for your data</p>
            </div>
        </div>
    </section>

    <section class="testimonials">
        <h2>What Our Customers Say</h2>
        <div class="testimonial-grid">
            @foreach($testimonials as $testimonial)
                <blockquote>
                    <p>"{{ $testimonial->quote }}"</p>
                    <cite>- {{ $testimonial->author }}, {{ $testimonial->company }}</cite>
                </blockquote>
            @endforeach
        </div>
    </section>
@endsection

@section('cta-section')
    <div class="cta-content">
        <h2>Ready to Get Started?</h2>
        <p>Join thousands of satisfied customers today</p>
        <form action="/signup" method="POST" class="signup-form">
            @csrf
            <input type="email" name="email" placeholder="Enter your email" required>
            <button type="submit">Start Free Trial</button>
        </form>
    </div>
@endsection

@section('footer-extras')
    @parent
    <div class="social-links">
        <a href="https://twitter.com/ourproduct">Twitter</a>
        <a href="https://linkedin.com/company/ourproduct">LinkedIn</a>
        <a href="https://github.com/ourproduct">GitHub</a>
    </div>
    <p class="copyright">&copy; 2024 Product Inc. All rights reserved.</p>
@endsection

@section('footer-scripts')
    @parent
    <script src="/js/analytics.js"></script>
    <script src="/js/product-tour.js"></script>
    <script>
        initProductTour();
        trackPageView('product-page');
    </script>
@endsection
