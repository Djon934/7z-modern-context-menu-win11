// Launcher stub. The package manifest must point to an executable, and Microsoft Store does not
// allow packages without a launchable app (no AppListEntry="none"), so launching it from the
// Start menu shows a short information message. The real work is done by ModernMenu7z.dll.
// Text is written with \u escapes on purpose: the file is compiled without /utf-8.
#include <windows.h>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    const bool ru = PRIMARYLANGID(GetUserDefaultUILanguage()) == LANG_RUSSIAN;
    const wchar_t* title = L"Context Menu for 7-Zip (unofficial)";
    const wchar_t* text = ru
        ? L"\u0420\u0430\u0441\u0448\u0438\u0440\u0435\u043D\u0438\u0435 \u00ABContext Menu for 7-Zip (unofficial)\u00BB \u0443\u0441\u0442\u0430\u043D\u043E\u0432\u043B\u0435\u043D\u043E. \u0423 \u043D\u0435\u0433\u043E \u043D\u0435\u0442 \u0441\u043E\u0431\u0441\u0442\u0432\u0435\u043D\u043D\u043E\u0433\u043E \u043E\u043A\u043D\u0430.\n\n\u041D\u0430\u0436\u043C\u0438\u0442\u0435 \u043F\u0440\u0430\u0432\u043E\u0439 \u043A\u043D\u043E\u043F\u043A\u043E\u0439 \u043D\u0430 \u0444\u0430\u0439\u043B \u0438\u043B\u0438 \u043F\u0430\u043F\u043A\u0443: \u0432 \u043D\u043E\u0432\u043E\u043C \u043C\u0435\u043D\u044E Windows 11 \u043F\u043E\u044F\u0432\u0438\u0442\u0441\u044F \u043F\u0443\u043D\u043A\u0442 7-Zip. \u041D\u0443\u0436\u0435\u043D \u0443\u0441\u0442\u0430\u043D\u043E\u0432\u043B\u0435\u043D\u043D\u044B\u0439 7-Zip.\n\n\u0415\u0441\u043B\u0438 \u043F\u0443\u043D\u043A\u0442\u0430 \u043D\u0435\u0442 \u0432 \u043E\u0441\u043D\u043E\u0432\u043D\u043E\u043C \u043C\u0435\u043D\u044E, \u043E\u0442\u043A\u0440\u043E\u0439\u0442\u0435 \u041F\u0430\u0440\u0430\u043C\u0435\u0442\u0440\u044B \u2192 \u041F\u0435\u0440\u0441\u043E\u043D\u0430\u043B\u0438\u0437\u0430\u0446\u0438\u044F \u2192 \u041A\u043E\u043D\u0442\u0435\u043A\u0441\u0442\u043D\u043E\u0435 \u043C\u0435\u043D\u044E \u2192 \u0420\u0430\u0441\u0448\u0438\u0440\u0435\u043D\u0438\u044F \u043F\u0440\u0438\u043B\u043E\u0436\u0435\u043D\u0438\u0439 \u0438 \u0432\u043A\u043B\u044E\u0447\u0438\u0442\u0435 \u044D\u0442\u043E \u0440\u0430\u0441\u0448\u0438\u0440\u0435\u043D\u0438\u0435.\n\n\u041F\u0440\u043E\u0435\u043A\u0442: https://github.com/Djon934/7z-modern-context-menu-win11"
        : L"The \"Context Menu for 7-Zip (unofficial)\" extension is installed. It has no window of its own.\n\nRight-click a file or folder: a 7-Zip item appears in the new Windows 11 menu. 7-Zip must be installed.\n\nIf the item is not in the main menu, open Settings > Personalization > Context menu > App extensions and turn this extension on.\n\nProject: https://github.com/Djon934/7z-modern-context-menu-win11";
    MessageBoxW(nullptr, text, title, MB_OK | MB_ICONINFORMATION);
    return 0;
}
