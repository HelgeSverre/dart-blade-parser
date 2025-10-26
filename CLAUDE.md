# Claude Development Notes

This file contains notes and guidelines for AI assistants working on this project.

## Documentation Style

### GitHub Badges

- **Never use emojis in GitHub badge labels**
  - Emojis don't render consistently across different platforms and browsers
  - Keep badge text clean and professional
  - Use simple text labels like "Try Playground" or "Live Demo"

  ✅ Good:
  ```markdown
  [![Try Playground](https://img.shields.io/badge/Try_Live-Playground-blue?style=for-the-badge)](url)
  ```

  ❌ Bad:
  ```markdown
  [![Playground](https://img.shields.io/badge/🎮_Try_Playground-Live-blue?style=for-the-badge)](url)
  ```

## Code Style

- Follow Dart conventions and use `dart format`
- Use conventional commits for all commit messages
- Keep commits atomic - one logical change per commit

## Testing

- All tests must pass before committing
- Run `just test` to verify
- Add tests for new features

## Deployment

### Playground Deployment

The playground is a Flutter web app deployed to Vercel:
- Build locally with `just build-playground`
- Deploy with `just deploy-playground`
- Vercel doesn't have Flutter pre-installed, so we build and deploy static files
