# CI/CD

Two workflows:

| Workflow | Trigger | Does |
|----------|---------|------|
| `ci.yml` | push/PR to `main` | format check, `flutter analyze`, `flutter test`, debug APK smoke build |
| `release.yml` | push tag `v*` (or manual) | build all platforms → GitHub Release, publish to Play + App Store |

## Cutting a release

```bash
# bump version in pubspec.yaml first (e.g. 1.1.0+5), commit, then:
git tag v1.1.0
git push origin v1.1.0
```

The tag drives the version (`v1.1.0` → build-name `1.1.0`). The build-number is
the GitHub Actions run number (monotonic). You can also run it from the Actions
tab (**Release → Run workflow**) and type a version.

> **Why tags, not every main push?** Deterministic, reviewable version
> boundaries and far fewer CI minutes. `main`/PRs are validated by `ci.yml`;
> only tags produce shippable, store-published artifacts. This is the common
> best practice for mobile apps.

## What lands where

- **GitHub Releases page** (free, no credentials needed): Android APK + AAB,
  Linux `.tar.gz`, Windows `.zip`. iOS (unsigned) and macOS `.zip` are attached
  too **once their builds succeed** — see the iOS note below.
- **Google Play** (internal track): the signed `.aab` — needs Play + Android
  signing secrets.
- **App Store / TestFlight**: signed `.ipa` — needs the Apple secrets.

Every store/signing step is **gated on its secrets**, so the release runs green
and still populates the GitHub Releases page before you've added anything.

## Required GitHub Secrets

Add under **Settings → Secrets and variables → Actions → New repository secret**.

### Android signing (needed for Play + a real release-signed APK)
| Secret | How to get it |
|--------|----------------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (create key with `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | e.g. `upload` |
| `ANDROID_KEY_PASSWORD` | key password |

### Google Play publishing
| Secret | How to get it |
|--------|----------------|
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console → Setup → API access → create a service account in Google Cloud, grant it "Release to testing tracks", download the JSON. Paste the whole file. |

> The app must already exist in the Play Console and have had **one manual
> upload** of the first AAB (Google requires the first upload by hand). After
> that, CI can push to the `internal` track. Change `track:` in `release.yml`
> to `alpha`/`beta`/`production` to target another track.

### Apple / App Store Connect
| Secret | How to get it |
|--------|----------------|
| `APP_STORE_CONNECT_API_KEY` | App Store Connect → Users and Access → Integrations → App Store Connect API → generate key, download the `.p8`, paste its **contents** |
| `APP_STORE_CONNECT_KEY_ID` | the key's ID |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer ID on the same page |
| `APPLE_DISTRIBUTION_CERT_BASE64` | export your Apple Distribution cert as `.p12`, then `base64 -w0 cert.p12` |
| `APPLE_DISTRIBUTION_CERT_PASSWORD` | the `.p12` export password |
| `APPLE_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for `com.arma.vpn`, `base64 -w0 profile.mobileprovision` |
| `APPLE_TEAM_ID` | 10-char Apple Developer Team ID |

## Free-plan / cost notes

- **Public repo:** GitHub Actions minutes (incl. macOS) are **free/unlimited**.
- **Private repo:** free tier = 2,000 min/month, and **macOS runners bill at
  10×**. The iOS/macOS jobs are the expensive ones; if you're private and want
  to conserve minutes, comment out the `ios` / `macos` / `publish-appstore`
  jobs until you need them.
- iOS/macOS jobs are `continue-on-error`, so failures there never fail the
  overall release.

## Desktop VPN (proxy mode)

Linux/Windows builds now include a working VPN core in **proxy mode**: the
release jobs download the xray-core binary + geo data into `assets/xray/`
(the `Fetch xray-core` steps), the app runs xray with SOCKS/HTTP inbounds and
sets the OS system proxy. No admin/root needed. Caveats: Linux system-proxy
targets GNOME (`gsettings`); traffic stats aren't shown on desktop yet; TUN
(full system-wide) mode is deferred; the Windows path is currently unverified.
See `desktop-vpn-proxy-mode` in project memory.

## Windows package formats

The Windows release job (x64) produces:

| Artifact | For |
|----------|-----|
| `ArmaVPN-<ver>-windows-x64-setup.exe` | Inno Setup wizard installer (Start-menu shortcut, uninstaller) |
| `ArmaVPN-<ver>-windows-x64.zip` | portable (extract + run the `.exe`) |

Built by `packaging/windows/installer.iss` via Inno Setup (`choco install
innosetup`). Unsigned installers trigger a SmartScreen warning until code-signed.

> **Why x64 only (no native arm64):** Flutter's stable channel doesn't publish a
> Windows-arm64 SDK, so `subosito/flutter-action` can't build it (`Unable to
> determine Flutter version ... architecture: arm64`). It's also unnecessary —
> **Windows-on-ARM runs x64 apps under emulation**, so this build serves arm64
> machines too. Revisit if/when Flutter ships a native Windows-arm64 toolchain.

## Linux package formats

The release Linux job produces four artifacts (all attached to the GitHub
Release), built by `packaging/linux/*.sh`:

| Format | Install | For |
|--------|---------|-----|
| `.deb` | `sudo apt install ./ArmaVPN-*.deb` | Debian/Ubuntu |
| `.rpm` | `sudo dnf install ./ArmaVPN-*.rpm` | Fedora/RHEL/openSUSE |
| `.AppImage` | `chmod +x *.AppImage && ./ArmaVPN-*.AppImage` | any distro, no install |
| `.tar.gz` | extract + run the binary | portable/manual |

Build any of them locally after `flutter build linux --release`:

```bash
V=$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')
packaging/linux/build-deb.sh      "$V" amd64
packaging/linux/build-rpm.sh      "$V" x86_64   # needs `rpmbuild`
packaging/linux/build-appimage.sh "$V" x86_64   # downloads appimagetool
```

All install to `/usr/lib/arma-vpn`, a `/usr/bin/arma-vpn` launcher, a desktop
entry, and an icon. Depends: `libgtk-3-0`/`gtk3`, `libsecret-1-0`/`libsecret`.

## Known blockers

- **iOS/macOS won't build yet** until the Xcode target + Xray xcframework wiring
  is finished (tracked separately). The jobs are wired and will start producing
  artifacts as soon as that lands — no workflow change needed.
- **Play versionCode:** the build-number comes from the run number. If your
  existing Play listing already has a higher versionCode, bump future tags so
  the run number stays ahead, or add an offset to `--build-number` in
  `release.yml`.
