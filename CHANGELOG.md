# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions: [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-24
### Added
- The full classic 7-Zip context menu in the new Windows 11 context menu (IExplorerCommand extension packaged as a sparse MSIX package).
- Menu content, language and settings are taken from the installed 7-Zip, so they always match the classic menu.
- Nested 7-Zip submenus (for example "CRC SHA") are shown as flat items with a group prefix, because Windows 11 does not support nested submenus in the new menu.
- Installer and uninstaller scripts, SHA-256 checksums, optional debug log.

## [0.0.1-alpha.1] - 2026-10-24
### Added
- Repository skeleton, build and release automation.
