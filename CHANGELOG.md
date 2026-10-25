# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/), versions: [SemVer](https://semver.org/).

## [Unreleased]

## [1.1.0-beta.1] - 2026-10-26

### Added
- **ARM64 build** (experimental, not yet tested on real ARM64 hardware). Releases now contain two archives: `ModernMenu7z-<version>-x64.zip` and `ModernMenu7z-<version>-arm64.zip`. On ARM64 Windows, install 7-Zip for ARM64.
- The installer checks that the package matches the Windows architecture and stops with a clear message if it does not.

### Changed
- The build checks that the DLL and the stub are really built for the requested architecture.
- CI and Release build both architectures; the release is published only when both builds succeed.

## [1.0.1] - 2026-10-25

### Added
- 7-Zip menu for drives (C:, D:...) in the new Windows 11 menu.

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
