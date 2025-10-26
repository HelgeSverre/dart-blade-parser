<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>
			@section('title')
			Laravel 4 Application
			@show
		</title>

		<!-- CSS are placed here -->
		{{ HTML::style('css/bootstrap.min.css') }}
		{{ HTML::style('css/styles.css') }}
		@section('styles')
		@show
	</head>
	<body>
		<div id="wrap">
			<div class="container">
				<div class="row">
					{{Notification::showAll()}}
				</div>
			</div>
			<div id="content">
				<div class="container">
					@yield('content')
				</div>
			</div>
		</div>
		<footer>
			<div class="container">
				<div class="row">
					<div class="col-md-12">
						<p>&copy; {{ date('Y') }} Laravel 4 App</p>
					</div>
				</div>
			</div>
		</footer>
	</body>

	<!-- Scripts are placed here -->
	{{ HTML::script('js/jquery.min.js') }}
	{{ HTML::script('js/bootstrap.min.js') }}
	@section('javascripts')
	@show
</html>
