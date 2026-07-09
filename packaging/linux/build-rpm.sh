#!/usr/bin/env bash
# Builds an .rpm from the release Linux bundle (Fedora/RHEL/openSUSE).
#
# Usage: packaging/linux/build-rpm.sh <version> [arch]
#   arch : rpm arch, default x86_64 (use aarch64 on arm64 hosts)
#
# Requires rpmbuild (Debian/Ubuntu: `apt-get install rpm`).
set -euo pipefail

VERSION="${1:?version required, e.g. 1.0.10}"
ARCH="${2:-x86_64}"

PKG="arma-vpn"
BINARY="arma_proxy_vpn_client"
INSTALL_DIR="usr/lib/${PKG}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Flutter emits to build/linux/<hostarch>/release/bundle where <hostarch> is
# x64 on amd64 and arm64 on arm64 — auto-detect so this works on both.
BUNDLE=""
for a in x64 arm64; do
  if [ -d "${ROOT}/build/linux/${a}/release/bundle" ]; then
    BUNDLE="${ROOT}/build/linux/${a}/release/bundle"
    break
  fi
done
ICON_SRC="${ROOT}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
OUT_DIR="${ROOT}/dist"
TOP="$(mktemp -d)"
trap 'rm -rf "$TOP"' EXIT

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "error: rpmbuild not found (apt-get install rpm / dnf install rpm-build)" >&2
  exit 1
fi
if [ ! -d "$BUNDLE" ]; then
  echo "error: $BUNDLE not found — run 'flutter build linux --release' first" >&2
  exit 1
fi

# ── stage the install tree ──────────────────────────────────────────────────
STAGE="${TOP}/stage"
mkdir -p "${STAGE}/${INSTALL_DIR}" "${STAGE}/usr/bin" \
  "${STAGE}/usr/share/applications" \
  "${STAGE}/usr/share/icons/hicolor/192x192/apps"
cp -r "$BUNDLE/." "${STAGE}/${INSTALL_DIR}/"
ln -s "/${INSTALL_DIR}/${BINARY}" "${STAGE}/usr/bin/${PKG}"
cp "$ICON_SRC" "${STAGE}/usr/share/icons/hicolor/192x192/apps/${PKG}.png"
cat > "${STAGE}/usr/share/applications/${PKG}.desktop" <<EOF
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

# ── spec ────────────────────────────────────────────────────────────────────
mkdir -p "${TOP}"/{BUILD,RPMS,SPECS}
SPEC="${TOP}/SPECS/${PKG}.spec"
cat > "$SPEC" <<EOF
Name:           ${PKG}
Version:        ${VERSION}
Release:        1
Summary:        Arma Proxy VPN client
License:        Proprietary
BuildArch:      ${ARCH}
Requires:       gtk3, libsecret
%global __os_install_post %{nil}
%global _build_id_links none

%description
Privacy-first Xray-core proxy/VPN client. On Linux it runs in proxy mode
(local SOCKS/HTTP inbound + system proxy).

%install
cp -r ${STAGE}/. %{buildroot}/

%files
/${INSTALL_DIR}
/usr/bin/${PKG}
/usr/share/applications/${PKG}.desktop
/usr/share/icons/hicolor/192x192/apps/${PKG}.png

%post
gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1 || :
update-desktop-database -q >/dev/null 2>&1 || :
EOF

mkdir -p "$OUT_DIR"
rpmbuild -bb --define "_topdir ${TOP}" --buildroot "${TOP}/buildroot" "$SPEC"
find "${TOP}/RPMS" -name '*.rpm' -exec cp {} "${OUT_DIR}/ArmaVPN-${VERSION}-linux-${ARCH}.rpm" \;
echo "Built: ${OUT_DIR}/ArmaVPN-${VERSION}-linux-${ARCH}.rpm"
