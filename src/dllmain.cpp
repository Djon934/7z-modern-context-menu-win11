// SevenZipMenuExt: расширение нового контекстного меню Windows 11 (IExplorerCommand).
//
// Идея: не воспроизводить пункты меню вручную, а попросить установленный у
// пользователя 7-Zip (его классический обработчик IContextMenu) построить меню,
// после чего показать те же пункты в новом меню и пробрасывать нажатия обратно.
// Код 7-Zip не используется и не распространяется: общение идёт только через
// публичные интерфейсы Windows (COM) во время работы.
//
// Написано по публичной документации Microsoft (IExplorerCommand, IContextMenu).

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shobjidl.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <atomic>
#include <cstdarg>
#include <cstdio>
#include <memory>
#include <new>
#include <string>
#include <vector>

// В некоторых версиях SDK эта константа не объявлена (значение постоянное).
#ifndef RRF_SUBKEY_WOW64_64KEY
#define RRF_SUBKEY_WOW64_64KEY 0x00010000
#endif

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "uuid.lib")

// CLSID нашей команды. Должен совпадать с packaging/AppxManifest.xml.template
// {5B7E2C41-9A3D-4F68-B1E7-0C4A8D6F2E93}
static const CLSID CLSID_ModernMenuCommand =
    {0x5b7e2c41, 0x9a3d, 0x4f68, {0xb1, 0xe7, 0x0c, 0x4a, 0x8d, 0x6f, 0x2e, 0x93}};

static const UINT kIdFirst = 1;
static const UINT kIdLast  = 0x7FFF;

static std::atomic<long> g_objects{0};
static std::atomic<long> g_locks{0};

// ---------------------------------------------------------------- журнал
// Включается командой: reg add HKCU\Software\SevenZipModernMenu /v Debug /t REG_DWORD /d 1 /f
// Файл: %LOCALAPPDATA%\SevenZipModernMenu\log.txt
static void Log(const wchar_t* fmt, ...)
{
    static int enabled = -1;
    if (enabled < 0) {
        DWORD v = 0, cb = sizeof(v);
        enabled = (RegGetValueW(HKEY_CURRENT_USER, L"Software\\SevenZipModernMenu", L"Debug",
                                RRF_RT_REG_DWORD, nullptr, &v, &cb) == ERROR_SUCCESS && v) ? 1 : 0;
    }
    if (!enabled) return;

    wchar_t msg[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnwprintf_s(msg, ARRAYSIZE(msg), _TRUNCATE, fmt, ap);
    va_end(ap);

    wchar_t path[MAX_PATH];
    if (!GetEnvironmentVariableW(L"LOCALAPPDATA", path, ARRAYSIZE(path))) return;
    PathAppendW(path, L"SevenZipModernMenu");
    CreateDirectoryW(path, nullptr);
    PathAppendW(path, L"log.txt");

    char utf8[3072];
    int n = WideCharToMultiByte(CP_UTF8, 0, msg, -1, utf8, sizeof(utf8) - 3, nullptr, nullptr);
    if (n <= 1) return;
    utf8[n - 1] = '\r'; utf8[n] = '\n';

    HANDLE h = CreateFileW(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                           OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) return;
    DWORD written = 0;
    WriteFile(h, utf8, (DWORD)(n + 1), &written, nullptr);
    CloseHandle(h);
}

// ---------------------------------------------------------------- вспомогательное
template <class T>
class Ptr {
    T* p = nullptr;
public:
    Ptr() = default;
    Ptr(const Ptr&) = delete;
    Ptr& operator=(const Ptr&) = delete;
    ~Ptr() { reset(); }
    T* operator->() const { return p; }
    T* get() const { return p; }
    T** put() { reset(); return &p; }
    explicit operator bool() const { return p != nullptr; }
    void reset() { if (p) { p->Release(); p = nullptr; } }
};

static bool RegString(HKEY root, const wchar_t* sub, const wchar_t* value, std::wstring& out)
{
    DWORD cb = 0;
    const DWORD flags = RRF_RT_REG_SZ | RRF_RT_REG_EXPAND_SZ | RRF_SUBKEY_WOW64_64KEY;
    if (RegGetValueW(root, sub, value, flags, nullptr, nullptr, &cb) != ERROR_SUCCESS || cb < sizeof(wchar_t))
        return false;
    std::wstring s(cb / sizeof(wchar_t), L'\0');
    if (RegGetValueW(root, sub, value, flags, nullptr, &s[0], &cb) != ERROR_SUCCESS)
        return false;
    s.resize(wcslen(s.c_str()));
    out = s;
    return true;
}

// CLSID классического обработчика 7-Zip берём из реестра, запасной вариант - известное значение.
static CLSID SevenZipHandlerClsid()
{
    static const CLSID fallback =
        {0x23170F69, 0x40C1, 0x278A, {0x10, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00}};
    std::wstring s;
    CLSID c;
    if (RegString(HKEY_CLASSES_ROOT, L"*\\shellex\\ContextMenuHandlers\\7-Zip", nullptr, s) &&
        SUCCEEDED(CLSIDFromString(s.c_str(), &c)))
        return c;
    return fallback;
}

// Папка установки 7-Zip (для значка).
static std::wstring SevenZipDir(const CLSID& clsid)
{
    std::wstring dir;
    wchar_t g[64];
    StringFromGUID2(clsid, g, ARRAYSIZE(g));
    std::wstring key = L"CLSID\\";
    key += g;
    key += L"\\InprocServer32";
    if (RegString(HKEY_CLASSES_ROOT, key.c_str(), nullptr, dir)) {
        dir.resize(dir.size() + 1);
        PathRemoveFileSpecW(&dir[0]);
        dir.resize(wcslen(dir.c_str()));
        if (!dir.empty()) return dir;
    }
    if (RegString(HKEY_LOCAL_MACHINE, L"SOFTWARE\\7-Zip", L"Path64", dir) ||
        RegString(HKEY_LOCAL_MACHINE, L"SOFTWARE\\7-Zip", L"Path", dir) ||
        RegString(HKEY_CURRENT_USER,  L"Software\\7-Zip", L"Path64", dir) ||
        RegString(HKEY_CURRENT_USER,  L"Software\\7-Zip", L"Path", dir))
        return dir;
    return L"";
}

// Убираем из заголовка "&" (клавиши быстрого доступа) и хвост после табуляции.
static std::wstring CleanTitle(const wchar_t* s)
{
    std::wstring r;
    for (; *s && *s != L'\t'; ++s) {
        if (*s == L'&') {
            if (s[1] == L'&') { r += L'&'; ++s; }
            continue;
        }
        r += *s;
    }
    return r;
}

// ---------------------------------------------------------------- сеанс и пункты меню
struct Session {
    Ptr<IContextMenu> handler;
    HMENU menu = nullptr;
    std::wstring icon;
    Session() { ++g_objects; }
    ~Session() {
        handler.reset();
        if (menu) DestroyMenu(menu);
        --g_objects;
    }
};

struct Item {
    UINT id = 0;
    std::wstring title;
    bool separator = false;
    bool disabled = false;
    HMENU sub = nullptr;
};

static std::vector<Item> ReadMenu(HMENU hm)
{
    std::vector<Item> items;
    const int n = GetMenuItemCount(hm);
    for (int i = 0; i < n; ++i) {
        wchar_t buf[512] = {};
        MENUITEMINFOW mii = {};
        mii.cbSize = sizeof(mii);
        mii.fMask = MIIM_FTYPE | MIIM_STATE | MIIM_ID | MIIM_SUBMENU | MIIM_STRING;
        mii.dwTypeData = buf;
        mii.cch = ARRAYSIZE(buf) - 1;
        if (!GetMenuItemInfoW(hm, (UINT)i, TRUE, &mii)) continue;

        Item it;
        it.id = mii.wID;
        it.separator = (mii.fType & MFT_SEPARATOR) != 0;
        it.disabled = (mii.fState & (MFS_DISABLED | MFS_GRAYED)) != 0;
        it.sub = mii.hSubMenu;
        it.title = CleanTitle(buf);
        if (!it.separator && it.title.empty()) continue;
        items.push_back(std::move(it));
    }
    return items;
}

static std::shared_ptr<Session> BuildSession(IShellItemArray* items)
{
    if (!items) return nullptr;

    Ptr<IDataObject> data;
    HRESULT hr = items->BindToHandler(nullptr, BHID_DataObject, IID_PPV_ARGS(data.put()));
    if (FAILED(hr)) { Log(L"BindToHandler(DataObject) failed: 0x%08X", hr); return nullptr; }

    const CLSID clsid = SevenZipHandlerClsid();
    auto s = std::make_shared<Session>();

    hr = CoCreateInstance(clsid, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(s->handler.put()));
    if (FAILED(hr)) { Log(L"CoCreateInstance(7-Zip handler) failed: 0x%08X", hr); return nullptr; }

    Ptr<IShellExtInit> init;
    hr = s->handler->QueryInterface(IID_PPV_ARGS(init.put()));
    if (FAILED(hr)) { Log(L"IShellExtInit not supported: 0x%08X", hr); return nullptr; }

    hr = init->Initialize(nullptr, data.get(), nullptr);
    if (FAILED(hr)) { Log(L"Initialize failed: 0x%08X", hr); return nullptr; }

    s->menu = CreatePopupMenu();
    if (!s->menu) return nullptr;

    hr = s->handler->QueryContextMenu(s->menu, 0, kIdFirst, kIdLast, CMF_NORMAL);
    if (FAILED(hr) || GetMenuItemCount(s->menu) <= 0) {
        Log(L"QueryContextMenu: hr=0x%08X, items=%d", hr, GetMenuItemCount(s->menu));
        return nullptr;
    }

    const std::wstring dir = SevenZipDir(clsid);
    if (!dir.empty()) {
        std::wstring exe = dir + L"\\7zFM.exe";
        if (PathFileExistsW(exe.c_str())) s->icon = exe + L",0";
    }
    Log(L"Session built, top-level items=%d, icon=%s", GetMenuItemCount(s->menu), s->icon.c_str());
    return s;
}

static HRESULT InvokeId(Session& s, UINT id)
{
    CMINVOKECOMMANDINFO ici = {};
    ici.cbSize = sizeof(ici);
    ici.hwnd = GetForegroundWindow();
    ici.lpVerb = MAKEINTRESOURCEA(id - kIdFirst);
    ici.nShow = SW_SHOWNORMAL;
    HRESULT hr = s.handler->InvokeCommand(&ici);
    Log(L"InvokeCommand(offset=%u) -> 0x%08X", id - kIdFirst, hr);
    return hr;
}

#define COM_REFCOUNT()                                                          \
public:                                                                         \
    std::atomic<ULONG> m_ref{1};                                                \
    ULONG STDMETHODCALLTYPE AddRef() override { return ++m_ref; }               \
    ULONG STDMETHODCALLTYPE Release() override {                                \
        ULONG r = --m_ref;                                                      \
        if (r == 0) delete this;                                                \
        return r;                                                               \
    }

static HRESULT MakeEnum(std::shared_ptr<Session> s, HMENU hm, IEnumExplorerCommand** ppEnum);

// ---------------------------------------------------------------- пункт меню
class ItemCommand final : public IExplorerCommand {
    COM_REFCOUNT()
private:
    std::shared_ptr<Session> m_s;
    Item m_it;
public:
    ItemCommand(std::shared_ptr<Session> s, Item it) : m_s(std::move(s)), m_it(std::move(it)) { ++g_objects; }
    ~ItemCommand() { --g_objects; }

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == __uuidof(IExplorerCommand)) {
            *ppv = static_cast<IExplorerCommand*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray*, LPWSTR* name) override {
        return SHStrDupW(m_it.separator ? L"" : m_it.title.c_str(), name);
    }
    HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray*, LPWSTR* icon) override {
        *icon = nullptr;
        if (m_it.separator || m_s->icon.empty()) return E_NOTIMPL;
        return SHStrDupW(m_s->icon.c_str(), icon);
    }
    HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*, LPWSTR* tip) override { *tip = nullptr; return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* g) override { *g = GUID_NULL; return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE GetState(IShellItemArray*, BOOL, EXPCMDSTATE* st) override {
        *st = m_it.disabled ? ECS_DISABLED : ECS_ENABLED;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray*, IBindCtx*) override {
        if (m_it.separator || m_it.sub) return S_OK;
        return InvokeId(*m_s, m_it.id);
    }
    HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* f) override {
        *f = m_it.separator ? ECF_ISSEPARATOR : (m_it.sub ? ECF_HASSUBCOMMANDS : ECF_DEFAULT);
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** ppEnum) override {
        *ppEnum = nullptr;
        if (!m_it.sub) return E_NOTIMPL;
        return MakeEnum(m_s, m_it.sub, ppEnum);
    }
};

// ---------------------------------------------------------------- перечислитель
class EnumCommands final : public IEnumExplorerCommand {
    COM_REFCOUNT()
private:
    std::vector<IExplorerCommand*> m_cmds;   // владеем одной ссылкой на каждый
    size_t m_pos = 0;
public:
    explicit EnumCommands(std::vector<IExplorerCommand*> cmds) : m_cmds(std::move(cmds)) { ++g_objects; }
    ~EnumCommands() {
        for (auto* c : m_cmds) c->Release();
        --g_objects;
    }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == __uuidof(IEnumExplorerCommand)) {
            *ppv = static_cast<IEnumExplorerCommand*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    HRESULT STDMETHODCALLTYPE Next(ULONG celt, IExplorerCommand** out, ULONG* fetched) override {
        ULONG n = 0;
        while (n < celt && m_pos < m_cmds.size()) {
            m_cmds[m_pos]->AddRef();
            out[n++] = m_cmds[m_pos++];
        }
        if (fetched) *fetched = n;
        return n == celt ? S_OK : S_FALSE;
    }
    HRESULT STDMETHODCALLTYPE Skip(ULONG celt) override {
        m_pos = (m_pos + celt > m_cmds.size()) ? m_cmds.size() : m_pos + celt;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE Reset() override { m_pos = 0; return S_OK; }
    HRESULT STDMETHODCALLTYPE Clone(IEnumExplorerCommand** ppEnum) override {
        *ppEnum = nullptr;
        std::vector<IExplorerCommand*> copy = m_cmds;
        for (auto* c : copy) c->AddRef();
        auto* e = new (std::nothrow) EnumCommands(std::move(copy));
        if (!e) return E_OUTOFMEMORY;
        e->m_pos = m_pos;
        *ppEnum = e;
        return S_OK;
    }
};

static HRESULT MakeEnum(std::shared_ptr<Session> s, HMENU hm, IEnumExplorerCommand** ppEnum)
{
    std::vector<IExplorerCommand*> cmds;
    for (auto& it : ReadMenu(hm)) {
        auto* c = new (std::nothrow) ItemCommand(s, std::move(it));
        if (c) cmds.push_back(c);
    }
    auto* e = new (std::nothrow) EnumCommands(std::move(cmds));
    if (!e) return E_OUTOFMEMORY;
    *ppEnum = e;
    return S_OK;
}

// ---------------------------------------------------------------- корневая команда
class RootCommand final : public IExplorerCommand {
    COM_REFCOUNT()
private:
    std::shared_ptr<Session> m_s;
    std::wstring m_title = L"7-Zip";
    HMENU m_children = nullptr;

    void Build(IShellItemArray* items) {
        m_s = BuildSession(items);
        m_children = nullptr;
        m_title = L"7-Zip";
        if (!m_s) return;

        m_children = m_s->menu;
        // Если 7-Zip отдал одну вложенную группу "7-Zip" - показываем её содержимое напрямую.
        int real = 0;
        const Item* only = nullptr;
        std::vector<Item> top = ReadMenu(m_s->menu);
        for (auto& i : top) if (!i.separator) { ++real; only = &i; }
        if (real == 1 && only->sub) {
            m_children = only->sub;
            m_title = only->title;
        }
    }
public:
    RootCommand() { ++g_objects; }
    ~RootCommand() { --g_objects; }

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == __uuidof(IExplorerCommand)) {
            *ppv = static_cast<IExplorerCommand*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray* items, LPWSTR* name) override {
        if (!m_s) Build(items);
        return SHStrDupW(m_title.c_str(), name);
    }
    HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray* items, LPWSTR* icon) override {
        *icon = nullptr;
        if (!m_s) Build(items);
        if (!m_s || m_s->icon.empty()) return E_NOTIMPL;
        return SHStrDupW(m_s->icon.c_str(), icon);
    }
    HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*, LPWSTR* tip) override { *tip = nullptr; return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* g) override { *g = GUID_NULL; return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE GetState(IShellItemArray* items, BOOL, EXPCMDSTATE* st) override {
        Build(items);                       // выбор мог измениться - строим заново
        *st = m_s ? ECS_ENABLED : ECS_HIDDEN;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray*, IBindCtx*) override { return S_OK; }
    HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* f) override { *f = ECF_HASSUBCOMMANDS; return S_OK; }
    HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** ppEnum) override {
        *ppEnum = nullptr;
        if (!m_s || !m_children) return E_FAIL;
        return MakeEnum(m_s, m_children, ppEnum);
    }
};

// ---------------------------------------------------------------- фабрика и экспорты
class Factory final : public IClassFactory {
    COM_REFCOUNT()
public:
    Factory() { ++g_objects; }
    ~Factory() { --g_objects; }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == __uuidof(IClassFactory)) {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        *ppv = nullptr;
        if (outer) return CLASS_E_NOAGGREGATION;
        auto* c = new (std::nothrow) RootCommand();
        if (!c) return E_OUTOFMEMORY;
        HRESULT hr = c->QueryInterface(riid, ppv);
        c->Release();
        return hr;
    }
    HRESULT STDMETHODCALLTYPE LockServer(BOOL lock) override {
        if (lock) ++g_locks; else --g_locks;
        return S_OK;
    }
};

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv)
{
    if (!ppv) return E_POINTER;
    *ppv = nullptr;
    if (rclsid != CLSID_ModernMenuCommand) return CLASS_E_CLASSNOTAVAILABLE;
    auto* f = new (std::nothrow) Factory();
    if (!f) return E_OUTOFMEMORY;
    HRESULT hr = f->QueryInterface(riid, ppv);
    f->Release();
    return hr;
}

STDAPI DllCanUnloadNow()
{
    return (g_objects.load() == 0 && g_locks.load() == 0) ? S_OK : S_FALSE;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) DisableThreadLibraryCalls(hModule);
    return TRUE;
}
