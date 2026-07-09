#!/usr/bin/env bash
# Cut a release.
#
# Reads the version from pubspec.yaml, then:
#   1. dart format lib test
#   2. commit any pending changes (format + your work)
#   3. flutter test  — abort the release if anything fails
#   4. push the current branch, create + push a `v<version>` tag
#      -> triggers .github/workflows/release.yml to build every OS package
#         (Android apk/aab, Linux deb/rpm/AppImage/tar.gz, Windows x64+arm64
#         Setup.exe/zip, iOS/macOS) and publish a GitHub Release.
#
# Usage:
#   scripts/release.sh              # confirm, then run the full flow
#   scripts/release.sh -y           # no confirmation prompt
#   scripts/release.sh --dry-run    # show what it would do, change nothing
#   scripts/release.sh --remote up  # use a remote other than 'origin'
#
# Bump `version:` in pubspec.yaml BEFORE running (the tag is derived from it).
set -euo pipefail

REMOTE="origin"
ASSUME_YES=false
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) ASSUME_YES=true ;;
    --dry-run) DRY_RUN=true ;;
    --remote) REMOTE="${2:?--remote needs a value}"; shift ;;
    -h|--help) sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ── version from pubspec.yaml (strip the +build suffix) ─────────────────────
VERSION="$(grep -E '^version:' pubspec.yaml | head -1 \
  | sed -E 's/^version:[[:space:]]*//; s/\+.*$//')"
if [ -z "$VERSION" ]; then
  echo "error: could not read 'version:' from pubspec.yaml" >&2
  exit 1
fi
TAG="v${VERSION}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

echo "Version : $VERSION"
echo "Tag     : $TAG"
echo "Branch  : $BRANCH"
echo "Remote  : $REMOTE"
echo

# ── fail fast: tag must not already exist ───────────────────────────────────
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "error: tag $TAG already exists locally. Bump 'version:' in pubspec.yaml." >&2
  exit 1
fi
if git ls-remote --tags "$REMOTE" "refs/tags/$TAG" 2>/dev/null | grep -q "$TAG"; then
  echo "error: tag $TAG already exists on '$REMOTE'. Bump the version." >&2
  exit 1
fi

if [ "$BRANCH" != "main" ]; then
  echo "note: not on 'main' (on '$BRANCH'). The release builds from this commit."
fi

# ── plan / confirm ──────────────────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] would run:"
  echo "  dart format lib test"
  echo "  git add -A && git commit -m 'release: $TAG'   (if anything changed)"
  echo "  flutter test"
  echo "  git push $REMOTE $BRANCH"
  echo "  git tag -a $TAG -m 'Release $TAG' && git push $REMOTE $TAG"
  exit 0
fi
if [ "$ASSUME_YES" != true ]; then
  echo "This will: format, COMMIT ALL pending changes, run tests, then push"
  printf "branch '%s' and release %s. Continue? [y/N] " "$BRANCH" "$TAG"
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "aborted."; exit 1 ;;
  esac
fi

# ── 1. format ───────────────────────────────────────────────────────────────
echo "==> dart format lib test"
dart format lib test

# ── 2. commit pending changes (format + your work) ──────────────────────────
git add -A
if git diff --cached --quiet; then
  echo "==> nothing to commit"
else
  echo "==> committing pending changes"
  git commit -m "release: $TAG"
fi

# ── 3. tests — gate the release ─────────────────────────────────────────────
echo "==> flutter test"
if ! flutter test; then
  echo "error: tests failed — release aborted (nothing pushed)." >&2
  exit 1
fi

# ── 4. existing flow: push branch + tag ─────────────────────────────────────
git push "$REMOTE" "$BRANCH"
git tag -a "$TAG" -m "Release $TAG"
git push "$REMOTE" "$TAG"

REPO_URL="$(git remote get-url "$REMOTE" \
  | sed -E 's#(git@|https://)github.com[:/]#https://github.com/#; s#\.git$##')"
echo
echo "✓ Released $TAG — the workflow is starting."
echo "  Actions:  ${REPO_URL}/actions"
echo "  Releases: ${REPO_URL}/releases"
