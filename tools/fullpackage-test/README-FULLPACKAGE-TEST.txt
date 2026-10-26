EXPERIMENTAL full (non-sparse) MSIX package: a test for a possible Microsoft Store variant.
Binaries live INSIDE the package (C:\Program Files\WindowsApps\...), no files are copied to Program Files.

Install:  install-fullpackage-test.cmd   (removes the normal package first, then installs this one)
Go back:  remove-fullpackage-test.cmd    (removes this package and restores the normal version)

Debug log (if you enable the Debug registry value) goes to the package-private folder:
%LOCALAPPDATA%\Packages\Djon934.ModernMenu7zTest_*\LocalCache\Local\ModernMenu7z\log.txt
