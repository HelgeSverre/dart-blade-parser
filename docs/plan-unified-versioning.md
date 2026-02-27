# Plan: Unified Versioning & Automated Releases

## Problem

- Dart package (`blade_parser`) and npm package (`prettier-plugin-laravel-blade`) have independent version numbers (1.3.0 vs 0.4.1) with no obvious relationship.
- Every release requires manual steps: bump both versions, build JS bridge, publish to npm separately.
- Changelog tracks both packages in the same file with separate subsections that easily fall out of sync.

## Goal

One version number, one tag, zero manual publishing.

## Design

- `pubspec.yaml` is the **single source of truth** for the version.
- Both packages share the same version number.
- Pushing a `v*.*.*` git tag triggers CI to build, test, and publish both packages automatically.
- `package.json` version is never manually edited again — CI sets it at publish time.

## Implementation Steps

### Step 1: One-time version alignment

- [ ] Decide the next version (e.g., `1.3.1` or `1.4.0` depending on changes since 1.3.0)
- [ ] Bump `pubspec.yaml` to that version
- [ ] Do NOT manually bump `package.json` — CI will handle it
- [ ] Add a note to the npm README: "Plugin version matches the `blade_parser` Dart package version."
- [ ] Add a one-line note in the changelog: "npm plugin versioning now aligned with `blade_parser`."

### Step 2: Create `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          registry-url: "https://registry.npmjs.org"

      # Run Dart tests
      - run: dart pub get
      - run: dart analyze --fatal-warnings lib/
      - run: dart test

      # Extract version from tag
      - name: Extract version
        id: ver
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      # Guardrail: ensure pubspec.yaml matches the tag
      - name: Verify pubspec version matches tag
        run: |
          PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
          if [ "$PUBSPEC_VERSION" != "${{ steps.ver.outputs.version }}" ]; then
            echo "ERROR: pubspec.yaml version ($PUBSPEC_VERSION) does not match tag (${{ steps.ver.outputs.version }})"
            exit 1
          fi

      # Build and test the prettier plugin
      - name: Build and test plugin
        working-directory: prettier-plugin-laravel-blade
        run: |
          npm ci
          npm version --no-git-tag-version "${{ steps.ver.outputs.version }}"
          npm test

      # Publish to npm
      - name: Publish to npm
        working-directory: prettier-plugin-laravel-blade
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: npm publish --access public

      # Publish to pub.dev
      - name: Publish to pub.dev
        run: dart pub publish --force
        env:
          PUB_CREDENTIALS: ${{ secrets.PUB_CREDENTIALS }}
```

### Step 3: Set up secrets

- [ ] Add `NPM_TOKEN` to GitHub repo secrets (generate from npmjs.com → Access Tokens)
- [ ] Add `PUB_CREDENTIALS` to GitHub repo secrets (from `~/.config/dart/pub-credentials.json` or use `dart pub token`)

### Step 4: Simplify changelog format

Stop using separate `### Prettier Plugin (vX.Y.Z)` subsections. One version = one section. If a fix is plugin-specific, just mention it inline, e.g.:

```markdown
## [1.4.0] - 2026-03-XX

### Fixed
- **Void element self-closing slash:** ...
- **Plugin: some-plugin-specific-thing:** ...
```

### Step 5: Update justfile

- [ ] Keep `plugin-build` and `plugin-test` for local dev
- [ ] Remove or deprecate `plugin-publish` (CI handles it now)
- [ ] Add a `release VERSION` recipe for convenience:

```just
# Tag a release (CI publishes automatically)
[group('publish')]
release VERSION:
    @echo "Tagging v{{VERSION}}..."
    git tag -a "v{{VERSION}}" -m "Release {{VERSION}}"
    git push origin "v{{VERSION}}"
```

### Step 6: Update package.json metadata

- [ ] Remove the hardcoded version or set it to `0.0.0-managed-by-ci` as a signal
- [ ] Ensure `prepublishOnly` still runs `npm run build` (it does)

## Release workflow (after implementation)

1. Make changes, update `pubspec.yaml` version and `CHANGELOG.md`
2. Commit and push to main
3. `just release 1.4.0` (or manually `git tag v1.4.0 && git push origin v1.4.0`)
4. CI does the rest: test → build → publish to npm + pub.dev

## Risks

| Risk | Mitigation |
|------|-----------|
| Tag/pubspec mismatch | CI hard-fails if they don't match |
| npm published but pub.dev fails | Re-run workflow; npm is idempotent for same version |
| Semver jump from 0.4.x → 1.x on npm | One-time note in README and changelog |
| `prepublishOnly` runs build twice | Remove `prepublishOnly` if CI builds explicitly |

## Not doing

- **Subtree split / separate repos:** Plugin build script references `../../tool/js_bridge.dart` — splitting repos adds submodule or artifact pipeline complexity.
- **Changesets / release-please:** Overkill for two packages with locked versions.
- **Automated changelog generation:** Current manual changelog is fine; the problem was only the dual versioning.
