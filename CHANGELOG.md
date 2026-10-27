# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/), versions: [SemVer](https://semver.org/).

## [Unreleased]

### Changed
- The launcher stub (`ModernMenu7z.exe`) now shows a short information message if started (required for a Microsoft Store package: apps without a launchable entry are not allowed).

## [1.2.0] - 2026-10-26

### Added
- **One `ModernMenu7z-<version>-Setup.exe` installer for both x64 and ARM64** (Inno Setup). It picks the right build, supports silent install (`/VERYSILENT`), and adds an uninstall entry to *Settings -> Apps*. The zip archives are still published.

## [1.1.0] - 2026-10-26

### Added
- **ARM64 build** (beta, not yet tested on real ARM64 hardware). Releases now contain two archives: `ModernMenu7z-<version>-x64.zip` and `ModernMenu7z-<version>-arm64-beta.zip`. The word "beta" will be dropped from the name once the ARM64 build is confirmed to work on real hardware. On ARM64 Windows, install 7-Zip for ARM64.
- The installer checks that the package matches the Windows architecture and stops with a clear message if it does not.

### Changed
- The build checks that the DLL and the stub are really built for the requested architecture.
- CI and Release build both architectures; the release is published only when both builds succeed.

## [1.0.0] - 2026-10-24

### Added
- The full classic 7-Zip context menu in the new Windows 11 context menu (IExplorerCommand extension packaged as a sparse MSIX package).
- Menu content, language and settings are taken from the installed 7-Zip, so they always match the classic menu.
- Nested 7-Zip submenus (for example "CRC SHA") are shown as flat items with a group prefix, because Windows 11 does not support nested submenus in the new menu.
- Installer and uninstaller scripts, SHA-256 checksums, optional debug log.
- Own project icon (embedded in the files and used for the package, also shown in Windows Settings) and file version information.

## [0.0.1-alpha.1] - 2026-10-24

### Added
- Repository skeleton, build and release automation.
