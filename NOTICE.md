# Legal notes / Правовые заметки

- This project is **not affiliated with or endorsed by** Igor Pavlov / the 7-Zip project or Microsoft.
  "7-Zip" and "Windows" are used only to describe compatibility; they belong to their respective owners.
- The repository and releases **do not contain or distribute** any 7-Zip code, binaries, icons or resources.
  The extension only talks to the 7-Zip that is already installed on the user's PC, at run time, through the
  standard Windows COM interface (`IContextMenu`). Menu item names come from the installed 7-Zip.
- The code was written from scratch using Microsoft's public documentation (`IExplorerCommand`, sparse packages).
  No code from NanaZip or other projects was copied.
- The project icon (`assets/`) was created for this project, is unrelated to the 7-Zip logo and is covered by the MIT license.
- License of this project: MIT (see `LICENSE`).

Проект не связан с 7-Zip (Игорь Павлов) и Microsoft и не одобрен ими. В репозитории и релизах нет кода,
файлов, значков и ресурсов 7-Zip: расширение лишь обращается во время работы к уже установленному у
пользователя 7-Zip через стандартный интерфейс Windows. Код написан с нуля по публичной документации Microsoft.
