# xray-core desktop assets

Desktop **proxy mode** (Linux/Windows) runs the bundled `xray` binary from this
folder. CI populates it before building; the binaries themselves are
git-ignored (only this README is committed so the asset folder exists).

Expected files at build time:

| File | Platform |
|------|----------|
| `xray` | Linux |
| `xray.exe` | Windows |
| `geoip.dat` | both (routing geo data) |
| `geosite.dat` | both (routing geo data) |

## How they get here

`.github/workflows/release.yml` downloads the pinned xray-core release for the
target platform/arch and extracts it into this folder before `flutter build`.

## Local desktop runs

For a local desktop build/run, download an
[xray-core release](https://github.com/XTLS/Xray-core/releases) for your OS/arch
and unzip `xray`(`.exe`), `geoip.dat`, and `geosite.dat` into this folder. The
app extracts them to its app-support dir on first connect.
