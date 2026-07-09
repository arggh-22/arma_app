#!/usr/bin/env bash
# Cut a release.
#
# Reads the version from pubspec.yaml, pushes the current branch, then creates
# and pushes a `v<version>` tag — which triggers .github/workflows/release.yml
# to build every OS package (Android apk/aab, Linux deb/rpm/AppImage/tar.gz,
# Windows x64+arm64 Setup.exe/zip, iOS/macOS) and publish a GitHub Release.
#
# Usage:
#   scripts/release.sh              # prompt, then push branch + tag
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
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

# ── safety checks ───────────────────────────────────────────────────────────
# Uncommitted tracked changes would be excluded from the tagged commit.
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "error: uncommitted changes — commit them before releasing." >&2
  exit 1
fi

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

# ── confirm ─────────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] would run:"
  echo "  git push $REMOTE $BRANCH"
  echo "  git tag -a $TAG -m 'Release $TAG'"
  echo "  git push $REMOTE $TAG"
  exit 0
fi
if [ "$ASSUME_YES" != true ]; then
  printf "Push '%s' and release %s? [y/N] " "$BRANCH" "$TAG"
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "aborted."; exit 1 ;;
  esac
fi

# ── release ─────────────────────────────────────────────────────────────────
git push "$REMOTE" "$BRANCH"
git tag -a "$TAG" -m "Release $TAG"
git push "$REMOTE" "$TAG"

REPO_URL="$(git remote get-url "$REMOTE" \
  | sed -E 's#(git@|https://)github.com[:/]#https://github.com/#; s#\.git$##')"
echo
echo "✓ Released $TAG — the workflow is starting."
echo "  Actions:  ${REPO_URL}/actions"
echo "  Releases: ${REPO_URL}/releases"
