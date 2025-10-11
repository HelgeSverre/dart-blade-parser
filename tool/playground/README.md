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

## Deploying to GitHub Pages

```bash
# Build
flutter build web --release --base-href /dart-blade-parser/

# Copy to docs/ or gh-pages branch
cp -r build/web/* ../../docs/playground/

# Commit and push
git add docs/playground
git commit -m "Deploy playground"
git push
```

## Quick Deploy with Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy from build/web directory
cd build/web
vercel --prod
```

## Development Tips

- The playground auto-saves input to localStorage (future enhancement)
- Press Ctrl+Enter to force re-parse
- Examples dropdown loads common patterns
- All parsing happens client-side (no backend needed)

## Architecture

- **Framework**: Flutter Web
- **Parser**: `blade_parser` package (local path dependency)
- **UI**: Material Design 3 with dark theme
- **State Management**: Basic setState (can upgrade to Riverpod/Bloc later)
