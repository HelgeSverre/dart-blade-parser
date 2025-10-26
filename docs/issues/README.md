# Draft Issues

This directory contains **draft GitHub issues** that haven't been posted yet.

## Purpose

Draft issues are used for:
- Complex technical decisions requiring thorough documentation
- Issues that need review before posting publicly
- Design discussions that need to be fleshed out

## Publishing a Draft

When ready to publish:

```bash
# Using GitHub CLI
gh issue create \
  --title "Issue title from draft" \
  --body-file docs/issues/filename.md \
  --label "decision-needed,enhancement"

# Or copy content to GitHub Issues UI
```

After publishing, either:
- Delete the draft file
- Add a note at the top linking to the GitHub issue

## Current Drafts

- **`unknown-directive-handling.md`** - How should the parser handle custom/unknown Blade directives?
  - Status: ✅ Posted as [Issue #1](https://github.com/HelgeSverre/dart-blade-parser/issues/1)
  - Labels: `enhancement`
