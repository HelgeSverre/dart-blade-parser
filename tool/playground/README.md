# Blade Parser Playground

Interactive web playground for testing the Blade parser in real-time.

## Features

- **Live Parsing**: Edit Blade templates and see results instantly
- **Multiple Output Formats**: View AST as JSON or tree structure
- **Error Display**: See parse errors with line/column information
- **Example Templates**: Quick-load common patterns
- **Split-Pane UI**: Side-by-side input/output

## Running Locally

```bash
# From this directory
flutter pub get
flutter run -d chrome
```

## Building for Production

```bash
# Build optimized web version
flutter build web --release

# Output will be in build/web/
# Deploy to any static hosting (GitHub Pages, Vercel, Netlify, etc.)
```

## Deploying to Vercel

Since Vercel doesn't have Flutter pre-installed, we build locally and deploy the static files.

### Quick Deploy (Recommended)

```bash
# From the playground directory (tool/playground)

# 1. Build the web app
flutter build web --release

# 2. Deploy the build output to Vercel
cd build/web
vercel --prod
```

Or use the provided script:

```bash
# From project root
just deploy-playground
```
