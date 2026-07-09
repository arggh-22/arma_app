#!/usr/bin/env bash
# Builds a portable AppImage from the release Linux bundle. Runs on any distro
# without installation.
#
# Usage: packaging/linux/build-appimage.sh <version> [arch]
#   arch : AppImage arch tag, default x86_64 (use aarch64 on arm64 hosts)
#
# appimagetool is downloaded on demand (cached in packaging/linux/.tools).
set -euo pipefail

VERSION="${1:?version required, e.g. 1.0.10}"
ARCH="${2:-x86_64}"

PKG="arma-vpn"
BINARY="arma_proxy_vpn_client"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="${ROOT}/build/linux/x64/release/bundle"
ICON_SRC="${ROOT}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
OUT_DIR="${ROOT}/dist"
TOOLS="${ROOT}/packaging/linux/.tools"
APPDIR="$(mktemp -d)/ArmaVPN.AppDir"
trap 'rm -rf "$(dirname "$APPDIR")"' EXIT

if [ ! -d "$BUNDLE" ]; then
  echo "error: $BUNDLE not found — run 'flutter build linux --release' first" >&2
  exit 1
fi

# ── AppDir layout ───────────────────────────────────────────────────────────
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

# AppRun entry point
cat > "$APPDIR/AppRun" <<EOF
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
exec "\$HERE/usr/bin/${BINARY}" "\$@"
EOF
chmod 0755 "$APPDIR/AppRun"

# .desktop + icon must sit at AppDir root (AppImage convention)
cat > "$APPDIR/${PKG}.desktop" <<EOF
[Desktop Entry]
Name=Arma VPN
Comment=Privacy-first proxy/VPN client
Exec=${BINARY}
Icon=${PKG}
Terminal=false
Type=Application
Categories=Network;Security;
StartupWMClass=com.arma.vpn
EOF
cp "$ICON_SRC" "$APPDIR/${PKG}.png"

# ── fetch appimagetool ──────────────────────────────────────────────────────
mkdir -p "$TOOLS" "$OUT_DIR"
TOOL="${TOOLS}/appimagetool-${ARCH}.AppImage"
if [ ! -x "$TOOL" ]; then
  curl -fL -o "$TOOL" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
  chmod +x "$TOOL"
fi

# ── build ───────────────────────────────────────────────────────────────────
OUT="${OUT_DIR}/ArmaVPN-${VERSION}-linux-${ARCH}.AppImage"
# --appimage-extract-and-run avoids needing FUSE on CI runners.
ARCH="$ARCH" "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT"
echo "Built: $OUT"
