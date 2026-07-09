#!/usr/bin/env bash
# One-shot builder for every package this host can produce.
#
#   packaging/build-all.sh [version] [target ...]
#
#   version : override (default: from pubspec.yaml)
#   target  : any of  android linux windows macos ios  (default: all
#             host-buildable). Targets the host can't build are skipped with a
#             note — a single machine cannot cross-build iOS/Windows/macOS.
#
# Outputs land in dist/. Host support:
#   Linux host   → android (apk+aab), linux (tar.gz+deb+rpm+AppImage)
#   macOS host   → android, macos (zip), ios (unsigned .app zip)
#   Windows host → android, windows (zip)   [run under Git-Bash/MSYS]
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [ -n "${VERSION}" ] && [[ "$VERSION" =~ ^(android|linux|windows|macos|ios)$ ]]; then
  # First arg was actually a target, not a version.
  set -- "" "$@"
  VERSION=""
fi
shift || true
[ -z "$VERSION" ] && VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')"
TARGETS="$*"

case "$(uname -s)" in
  Linux) HOST=linux ;;
  Darwin) HOST=macos ;;
  MINGW*|MSYS*|CYGWIN*) HOST=windows ;;
  *) HOST=unknown ;;
esac

BUILD_NO="$(date +%s 2>/dev/null || echo 1)"
mkdir -p dist
BUILT=(); SKIPPED=()

want() { [ -z "$TARGETS" ] || printf '%s\n' $TARGETS | grep -qx "$1"; }
have_curl() { command -v curl >/dev/null; }

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
skip() { printf '\033[1;33m--> skip %s: %s\033[0m\n' "$1" "$2"; SKIPPED+=("$1 ($2)"); }

# Remove desktop xray binaries so an Android build doesn't bundle them.
clean_xray() { rm -f assets/xray/xray assets/xray/xray.exe \
  assets/xray/geoip.dat assets/xray/geosite.dat 2>/dev/null || true; }

# Fetch xray-core for a desktop target into assets/xray.
fetch_xray() { # $1 = linux|windows
  have_curl || { echo "curl required to fetch xray"; return 1; }
  clean_xray
  local url
  case "$1" in
    linux) url="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" ;;
    windows) url="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-windows-64.zip" ;;
  esac
  curl -fL -o /tmp/xray.zip "$url"
  unzip -o /tmp/xray.zip -d assets/xray >/dev/null
  [ -f assets/xray/xray ] && chmod +x assets/xray/xray || true
}

flutter pub get >/dev/null

# ── Android (any host) ──────────────────────────────────────────────────────
if want android; then
  log "Android (apk + aab)"
  clean_xray  # keep the APK lean — Android uses the native AAR, not bundled xray
  if flutter build apk --release --build-name="$VERSION" --build-number="$BUILD_NO" \
     && flutter build appbundle --release --build-name="$VERSION" --build-number="$BUILD_NO"; then
    cp build/app/outputs/flutter-apk/app-release.apk "dist/ArmaVPN-$VERSION.apk"
    cp build/app/outputs/bundle/release/app-release.aab "dist/ArmaVPN-$VERSION.aab"
    BUILT+=("android: apk, aab")
  else
    skip android "build failed (Android SDK present?)"
  fi
fi

# ── Linux (Linux host only) ─────────────────────────────────────────────────
if want linux; then
  if [ "$HOST" != linux ]; then
    skip linux "needs a Linux host (current: $HOST)"
  else
    log "Linux (tar.gz + deb + rpm + AppImage)"
    flutter config --enable-linux-desktop >/dev/null
    fetch_xray linux
    if flutter build linux --release --build-name="$VERSION" --build-number="$BUILD_NO"; then
      tar -czf "dist/ArmaVPN-$VERSION-linux-x64.tar.gz" -C build/linux/x64/release/bundle .
      BUILT+=("linux: tar.gz")
      bash packaging/linux/build-deb.sh "$VERSION" amd64 && BUILT+=("linux: deb") || skip "linux/deb" "dpkg-deb error"
      if command -v rpmbuild >/dev/null; then
        bash packaging/linux/build-rpm.sh "$VERSION" x86_64 && BUILT+=("linux: rpm")
      else
        skip "linux/rpm" "rpmbuild not installed (apt-get install rpm)"
      fi
      bash packaging/linux/build-appimage.sh "$VERSION" x86_64 && BUILT+=("linux: AppImage") || skip "linux/AppImage" "appimagetool error"
    else
      skip linux "flutter build linux failed"
    fi
  fi
fi

# ── Windows (Windows host only) ─────────────────────────────────────────────
if want windows; then
  if [ "$HOST" != windows ]; then
    skip windows "needs a Windows host (current: $HOST)"
  else
    log "Windows (zip)"
    flutter config --enable-windows-desktop >/dev/null
    fetch_xray windows
    if flutter build windows --release --build-name="$VERSION" --build-number="$BUILD_NO"; then
      ( cd build/windows/x64/runner/Release && \
        powershell -NoProfile -Command "Compress-Archive -Path * -DestinationPath '$ROOT/dist/ArmaVPN-$VERSION-windows-x64.zip' -Force" )
      BUILT+=("windows: zip")
    else
      skip windows "flutter build windows failed"
    fi
  fi
fi

# ── macOS + iOS (macOS host only) ───────────────────────────────────────────
if want macos; then
  if [ "$HOST" != macos ]; then
    skip macos "needs a macOS host (current: $HOST)"
  else
    log "macOS (zip)"
    flutter config --enable-macos-desktop >/dev/null
    if flutter build macos --release --build-name="$VERSION" --build-number="$BUILD_NO"; then
      ( cd build/macos/Build/Products/Release && zip -qr "$ROOT/dist/ArmaVPN-$VERSION-macos.zip" ./*.app )
      BUILT+=("macos: zip")
    else
      skip macos "flutter build macos failed"
    fi
  fi
fi

if want ios; then
  if [ "$HOST" != macos ]; then
    skip ios "needs a macOS host (current: $HOST)"
  else
    log "iOS (unsigned .app zip)"
    if flutter build ios --release --no-codesign --build-name="$VERSION" --build-number="$BUILD_NO"; then
      ( cd build/ios/iphoneos && zip -qr "$ROOT/dist/ArmaVPN-$VERSION-ios-unsigned.zip" Runner.app )
      BUILT+=("ios: unsigned zip")
    else
      skip ios "flutter build ios failed (Xcode/Xray wiring pending)"
    fi
  fi
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n\033[1;32m===== build-all summary (v%s, host=%s) =====\033[0m\n' "$VERSION" "$HOST"
printf 'Built:\n'; for b in "${BUILT[@]:-}"; do [ -n "$b" ] && printf '  ✓ %s\n' "$b"; done
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  printf 'Skipped:\n'; for s in "${SKIPPED[@]}"; do printf '  - %s\n' "$s"; done
fi
printf '\nArtifacts in dist/:\n'; ls -1 dist/ 2>/dev/null | sed 's/^/  /'
