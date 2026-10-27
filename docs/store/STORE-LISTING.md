# Texts for the Microsoft Store listing (Partner Center)

Copy each block into the matching field. Add two languages: **English (United States)** and **Russian**.
The reserved product name must stay exactly as reserved in Partner Center.

Privacy policy URL: https://github.com/Djon934/7z-modern-context-menu-win11/blob/main/PRIVACY.md
Support contact / website: https://github.com/Djon934/7z-modern-context-menu-win11
Category: Utilities & tools (Utilities).  Pricing: Free.  Markets: all.

## English (en-us)

### Description
Shows the full 7-Zip menu in the new Windows 11 right-click menu, so you don't need "Show more options".

This is an unofficial extension. It does not include 7-Zip: install 7-Zip from 7-zip.org first (the "Integrate 7-Zip to shell context menu" option must be on, it is on by default).

How it works: the app asks your installed 7-Zip for its classic context menu and shows exactly the same items in the new menu. Because of that, the items, their order, language and your 7-Zip settings (7-Zip File Manager > Tools > Options > 7-Zip) are always the same as in the classic menu. Nested 7-Zip groups (for example CRC SHA) are shown as flat items with a group prefix, because the new Windows 11 menu does not support submenus inside submenus.

Works for files and folders, including multiple selection. Open source (MIT): https://github.com/Djon934/7z-modern-context-menu-win11

7-Zip is a project of Igor Pavlov. This app is not affiliated with, endorsed by, or sponsored by the 7-Zip project.

### Short description
Show the 7-Zip menu in the new Windows 11 context menu. Unofficial; requires 7-Zip.

### Features (up to 20 lines)
- Full 7-Zip menu in the new Windows 11 context menu
- Same items, order and language as the classic 7-Zip menu
- Respects your 7-Zip settings
- Files, folders and multiple selection
- No data collection, no internet access
- Free and open source (MIT)

### Release notes
First Microsoft Store release. Shows the 7-Zip menu in the new Windows 11 context menu.

### Search terms
7-Zip; context menu; right click; archive; zip; Windows 11 menu

### Notes for certification (max 2000 characters)
This app has no window and no Start menu entry. It adds one item to the Windows 11 File Explorer context menu (windows.fileExplorerContextMenus extension, IExplorerCommand).
The item shows the menu of the 7-Zip shell extension that is already installed on the computer. 7-Zip is a separate free program; the app does nothing without it.
HOW TO TEST: 1) Install 7-Zip x64 from https://www.7-zip.org/ (keep "Integrate 7-Zip to shell context menu" on, it is the default). 2) Install this app. 3) In File Explorer right-click any file or folder: a "7-Zip" item appears in the new (short) context menu. Click it to see the 7-Zip commands, for example "Add to archive".
WHY runFullTrust: the app loads the classic Win32 COM shell extension of 7-Zip (a native DLL outside the package) inside its COM surrogate and calls IContextMenu. This cannot be done from an AppContainer app.
The app has no network code and collects no data. Source code: https://github.com/Djon934/7z-modern-context-menu-win11
The app name includes "7-Zip" only to say which program the menu belongs to. It is marked "unofficial" and is not affiliated with the 7-Zip project.

## Русский (ru)

### Описание
Показывает полное меню 7-Zip в новом контекстном меню Windows 11, без пункта «Показать дополнительные параметры».

Это неофициальное расширение. Сам 7-Zip в него не входит: сначала установите 7-Zip с сайта 7-zip.org (параметр «Встроить 7-Zip в контекстное меню оболочки» должен быть включён, по умолчанию он включён).

Как это работает: приложение запрашивает у установленного 7-Zip его классическое контекстное меню и показывает те же пункты в новом меню. Поэтому состав пунктов, порядок, язык и ваши настройки 7-Zip (Диспетчер файлов 7-Zip > Сервис > Настройки > 7-Zip) всегда совпадают с классическим меню. Вложенные группы 7-Zip (например, CRC SHA) показываются плоским списком с приставкой группы, потому что новое меню Windows 11 не поддерживает подменю внутри подменю.

Работает для файлов и папок, в том числе при выделении нескольких объектов. Открытый исходный код (MIT): https://github.com/Djon934/7z-modern-context-menu-win11

7-Zip - проект Игоря Павлова. Это приложение не связано с проектом 7-Zip, не одобрено и не спонсируется им.

### Краткое описание
Показывает меню 7-Zip в новом контекстном меню Windows 11. Неофициальное; нужен 7-Zip.

### Возможности
- Полное меню 7-Zip в новом контекстном меню Windows 11
- Те же пункты, порядок и язык, что в классическом меню 7-Zip
- Учитывает ваши настройки 7-Zip
- Файлы, папки и выделение нескольких объектов
- Не собирает данные, не использует интернет
- Бесплатно, открытый исходный код (MIT)

### Что нового
Первый выпуск в Microsoft Store. Показывает меню 7-Zip в новом контекстном меню Windows 11.

### Ключевые слова
7-Zip; контекстное меню; правая кнопка; архив; zip; меню Windows 11

## Images
- App icon (logo 1:1): `docs/store/StoreIcon-300x300.png` (300x300).
- Screenshots: at least one, **1366x768 or larger (PNG)**. Take new full-screen shots (Win+Shift+S, whole screen) with the right-click menu open. The files in `docs/images` are too small for Store.

## Age rating (IARC questionnaire)
Category: Utility / reference. Answer "No" to all questions about violence, sexual content, language, gambling, purchases, user-generated content, location sharing and personal data. Expected rating: 3+/Everyone.
