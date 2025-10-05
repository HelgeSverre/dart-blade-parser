@extends('layouts.app')

@section('title', 'Page Title')

@section('content')
    <h1>Main Content</h1>

    @push('scripts')
        <script src="/page-script.js"></script>
    @endpush

    @include('partials.sidebar')
@endsection

@section('footer')
    @parent
    <p>Additional footer content</p>
@endsection
