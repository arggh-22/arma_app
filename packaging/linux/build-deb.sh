#!/usr/bin/env bash
# Builds a .deb from the release Linux bundle.
#
# Usage: packaging/linux/build-deb.sh <version> [arch]
#   version : e.g. 1.0.10  (no leading v)
#   arch    : dpkg arch, default amd64 (use arm64 on arm64 hosts)
#
# Assumes `flutter build linux --release` has already produced
# build/linux/x64/release/bundle. Outputs dist/ArmaVPN-<version>-linux-<arch>.deb
set -euo pipefail

VERSION="${1:?version required, e.g. 1.0.10}"
ARCH="${2:-amd64}"

PKG="arma-vpn"                 # debian package name
BINARY="arma_proxy_vpn_client" # flutter BINARY_NAME
INSTALL_DIR="usr/lib/${PKG}"   # where the bundle lands

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="${ROOT}/build/linux/x64/release/bundle"
ICON_SRC="${ROOT}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" # 192x192
OUT_DIR="${ROOT}/dist"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ ! -d "$BUNDLE" ]; then
  echo "error: $BUNDLE not found — run 'flutter build linux --release' first" >&2
  exit 1
fi

# ── lay out the package tree ────────────────────────────────────────────────
mkdir -p "$STAGE/${INSTALL_DIR}"
cp -r "$BUNDLE/." "$STAGE/${INSTALL_DIR}/"

# launcher symlink on PATH
mkdir -p "$STAGE/usr/bin"
ln -s "/${INSTALL_DIR}/${BINARY}" "$STAGE/usr/bin/${PKG}"

# desktop entry
mkdir -p "$STAGE/usr/share/applications"
cat > "$STAGE/usr/share/applications/${PKG}.desktop" <<EOF
[Desktop Entry]
Name=Arma VPN
Comment=Privacy-first proxy/VPN client
Exec=/usr/bin/${PKG}
Icon=${PKG}
Terminal=false
Type=Application
Categories=Network;Security;
StartupWMClass=com.arma.vpn
EOF

# icon (reuse the Android launcher icon; it is 192x192)
mkdir -p "$STAGE/usr/share/icons/hicolor/192x192/apps"
cp "$ICON_SRC" "$STAGE/usr/share/icons/hicolor/192x192/apps/${PKG}.png"

# ── control metadata ────────────────────────────────────────────────────────
INSTALLED_KB=$(du -sk "$STAGE" | cut -f1)
mkdir -p "$STAGE/DEBIAN"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: ${PKG}
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, libsecret-1-0
Installed-Size: ${INSTALLED_KB}
Maintainer: Arma VPN <noreply@arma-web.org>
Description: Arma Proxy VPN client
 Privacy-first Xray-core proxy/VPN client. On Linux it runs in proxy mode
 (local SOCKS/HTTP inbound + system proxy).
EOF

# GTK apps refresh the icon/desktop caches on install.
cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q || true
fi
EOF
chmod 0755 "$STAGE/DEBIAN/postinst"

# ── build ───────────────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
DEB="${OUT_DIR}/ArmaVPN-${VERSION}-linux-${ARCH}.deb"
fakeroot dpkg-deb --build "$STAGE" "$DEB"
echo "Built: $DEB"
dpkg-deb --info "$DEB"
