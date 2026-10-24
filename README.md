<p align="center"><img src="assets/icon-256.png" width="96" alt="icon"></p>

# 7-Zip Modern Context Menu for Windows 11

**Windows 11 modern context menu for 7-Zip.** Puts the full 7-Zip menu into the new Windows 11 right-click menu,
so you don't have to click "Show more options".

🇷🇺 [Читать на русском](README.ru.md)

<!-- SCREENSHOT: drag your screenshot here while editing this file on GitHub -->

## Features
- All 7-Zip items in the new menu: open, extract, test, add to archive, CRC SHA and more.
- Items, order, language and icons come **from your installed 7-Zip**, so everything matches the classic menu.
- 7-Zip settings still work: *7-Zip File Manager → Tools → Options → 7-Zip* (hide items, cascade on/off, icons).
- Works for files and folders, including multiple selection.
- Nothing from 7-Zip is bundled or modified. Open source, MIT license, built publicly by GitHub Actions.

## Requirements
- Windows 11 (tested on Windows 11 Pro 26H2).
- [7-Zip](https://www.7-zip.org/) **x64**, installed normally (tested with 7-Zip 26.05).
- In 7-Zip options, the checkbox **"Integrate 7-Zip to shell context menu"** must stay enabled. The extension uses it.

## Installation
1. Open the [Releases](../../releases) page and download `ModernMenu7z-<version>-x64.zip`.
2. Extract the archive to any folder (don't run files from inside the zip).
3. Double-click **`install.cmd`** and confirm the administrator prompt (UAC).
4. Wait for "Done" and press Enter. The taskbar may blink for a moment: Explorer restarts.
5. Right-click any file or folder. The **7-Zip** item appears in the new menu.

If it does not appear, sign out of Windows and sign in again.

### Verify the download (optional)
Compare the SHA-256 of the zip with `SHA256SUMS.txt` from the release:
`certutil -hashfile ModernMenu7z-<version>-x64.zip SHA256`

## Uninstallation
Run **`uninstall.cmd`** from the extracted folder.

## Known limitations
- **Nested submenus are flattened.** Windows 11 supports only one submenu level in the new menu
  ([Microsoft documentation](https://learn.microsoft.com/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorercommand-enumsubcommands)).
  7-Zip groups such as *CRC SHA* appear as items like `CRC SHA › SHA-256`. Hide unneeded ones in the 7-Zip options.
- x64 only. Requires the classic 7-Zip handler (see Requirements).
- The menu for the empty space inside a folder (background) is not supported yet.

## How it works
The extension implements `IExplorerCommand` and is registered through a signed *sparse MSIX package*.
When you right-click, it asks the installed 7-Zip for its classic context menu (`IContextMenu`) and shows the same
items in the new menu. Clicks are passed back to 7-Zip. See [`src/dllmain.cpp`](src/dllmain.cpp).

## About the certificate
Windows only accepts signed packages, so releases are signed with the author's certificate (`CN=Djon934`).
The installer adds this **public** certificate to *Trusted People* on your PC. This means Windows will trust other
software signed with the same key too. If you don't want that, build the project yourself (below) and use your own certificate,
or remove the certificate after installation: `Win+R → certlm.msc → Trusted People → Certificates`.
The package keeps working after the certificate is removed from the store.

## Troubleshooting
Enable the log and right-click a file:
```
reg add HKCU\Software\ModernMenu7z /v Debug /t REG_DWORD /d 1 /f
```
The log is in `%LOCALAPPDATA%\ModernMenu7z\log.txt`. Attach it to an issue.

## Build it yourself
Fork the repository, enable GitHub Actions, push a commit. The `CI` workflow produces an artifact signed with a temporary
test certificate. For your own permanent certificate run `tools/New-SigningCertificate.cmd` and add the secrets
`SIGN_PFX_BASE64` and `SIGN_PFX_PASSWORD` (repository *Settings → Secrets and variables → Actions*).
A release is made by pushing a tag `vX.Y.Z` that matches the `VERSION` file.

## Disclaimer
This software is provided **"as is"**, without warranty of any kind. You use it at your own risk. The installer
installs a Windows package, adds a certificate to *Trusted People* and restarts Windows Explorer. The author is not
liable for any damage or data loss. This project is **not affiliated with** or endorsed by the 7-Zip project
(Igor Pavlov) or Microsoft. 7-Zip and Windows are trademarks or property of their owners.
See [NOTICE.md](NOTICE.md).

## Credits
Created by [Djon934](https://github.com/Djon934). The code, build scripts and documentation were written with the help of
**Claude** (an AI assistant by Anthropic) and tested by the author on Windows 11. The project icon was drawn for this project.

## License
[MIT](LICENSE) © 2026 Djon934
