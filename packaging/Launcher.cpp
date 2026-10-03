// Native single-file launcher. Qt files are extracted once per payload revision.
// The generated runtime_manifest.h and resources are supplied by the release build.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shlobj.h>
#include <string>
#include <vector>
#include "runtime_manifest.h"

namespace {
class Handle {
public:
    explicit Handle(HANDLE value = nullptr) : value(value) {}
    ~Handle() { if (value && value != INVALID_HANDLE_VALUE) CloseHandle(value); }
    Handle(const Handle &) = delete;
    Handle &operator=(const Handle &) = delete;
    HANDLE value;
};

bool regularFile(const std::wstring &path, unsigned long long expectedSize)
{
    WIN32_FILE_ATTRIBUTE_DATA info{};
    if (!GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &info)
        || (info.dwFileAttributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT)))
        return false;
    const auto size = (static_cast<unsigned long long>(info.nFileSizeHigh) << 32) | info.nFileSizeLow;
    return size == expectedSize;
}

bool cacheReady(const std::wstring &cache)
{
    if (!regularFile(cache + L"\\ready", 1))
        return false;
    for (const auto &file : runtimeFiles) {
        if (!regularFile(cache + L"\\" + file.path, file.size))
            return false;
    }
    return true;
}

bool createCache(const std::wstring &base, const std::wstring &relative)
{
    std::wstring path = base;
    size_t start = 0;
    while (start < relative.size()) {
        const size_t end = relative.find(L'\\', start);
        path += L"\\" + relative.substr(start, end - start);
        if (!CreateDirectoryW(path.c_str(), nullptr) && GetLastError() != ERROR_ALREADY_EXISTS)
            return false;
        const DWORD attributes = GetFileAttributesW(path.c_str());
        if (attributes == INVALID_FILE_ATTRIBUTES || !(attributes & FILE_ATTRIBUTE_DIRECTORY)
            || (attributes & FILE_ATTRIBUTE_REPARSE_POINT))
            return false;
        if (end == std::wstring::npos)
            break;
        start = end + 1;
    }
    return true;
}

bool launch(const std::wstring &program, const std::wstring &arguments,
            const std::wstring &directory, bool wait)
{
    std::wstring command = L"\"" + program + L"\"";
    if (!arguments.empty()) command += L" " + arguments;
    std::vector<wchar_t> buffer(command.begin(), command.end());
    buffer.push_back(L'\0');
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    if (wait) { startup.dwFlags = STARTF_USESHOWWINDOW; startup.wShowWindow = SW_HIDE; }
    PROCESS_INFORMATION process{};
    if (!CreateProcessW(program.c_str(), buffer.data(), nullptr, nullptr, FALSE, 0,
                        nullptr, directory.c_str(), &startup, &process))
        return false;
    Handle processHandle(process.hProcess), threadHandle(process.hThread);
    if (!wait) return true;
    if (WaitForSingleObject(process.hProcess, INFINITE) != WAIT_OBJECT_0) return false;
    DWORD code = 1;
    return GetExitCodeProcess(process.hProcess, &code) && code == 0;
}

bool unpack(HINSTANCE instance, const std::wstring &cache)
{
    DeleteFileW((cache + L"\\ready").c_str());
    const HRSRC resource = FindResourceW(instance, MAKEINTRESOURCEW(101), RT_RCDATA);
    if (!resource) return false;
    const DWORD size = SizeofResource(instance, resource);
    const void *bytes = LockResource(LoadResource(instance, resource));
    if (!bytes || !size) return false;
    const std::wstring extractor = cache + L"\\extract-runtime.exe";
    {
        Handle file(CreateFileW(extractor.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                                FILE_ATTRIBUTE_NORMAL, nullptr));
        DWORD written = 0;
        if (file.value == INVALID_HANDLE_VALUE
            || !WriteFile(file.value, bytes, size, &written, nullptr) || written != size)
            return false;
    }
    const bool extracted = launch(extractor, L"-s1 -d\"" + cache + L"\"", cache, true);
    DeleteFileW(extractor.c_str());
    if (!extracted) return false;
    for (const auto &file : runtimeFiles) {
        if (!regularFile(cache + L"\\" + file.path, file.size)) return false;
    }
    Handle marker(CreateFileW((cache + L"\\ready").c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr));
    DWORD written = 0;
    const char ready = '1';
    return marker.value != INVALID_HANDLE_VALUE
        && WriteFile(marker.value, &ready, 1, &written, nullptr) && written == 1;
}

int fail(const wchar_t *message)
{
    MessageBoxW(nullptr, message, L"七日杀自定义背包容量工具", MB_OK | MB_ICONERROR);
    return 1;
}
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR arguments, int)
{
    PWSTR localData = nullptr;
    if (FAILED(SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_CREATE, nullptr, &localData)))
        return fail(L"无法访问本机运行缓存目录。\nCannot access the local runtime cache.");
    const std::wstring base(localData);
    CoTaskMemFree(localData);
    const std::wstring relative = L"wangcac\\BackpackTools\\runtime\\" + std::wstring(runtimeId);
    const std::wstring cache = base + L"\\" + relative;
    if (!createCache(base, relative))
        return fail(L"无法创建运行缓存，请检查目录权限。\nCannot create the runtime cache.");

    const std::wstring mutexName = L"Local\\wangcac-BackpackTools-" + std::wstring(runtimeId);
    Handle mutex(CreateMutexW(nullptr, FALSE, mutexName.c_str()));
    if (!mutex.value) return fail(L"无法初始化程序。\nCannot initialize the application.");
    const DWORD result = WaitForSingleObject(mutex.value, 120000);
    if (result != WAIT_OBJECT_0 && result != WAIT_ABANDONED)
        return fail(L"程序正在初始化，请稍后重试。\nInitialization is still in progress. Please try again.");
    const bool ready = cacheReady(cache) || unpack(instance, cache);
    ReleaseMutex(mutex.value);
    if (!ready)
        return fail(L"运行文件解压失败，请重新下载程序或检查剩余磁盘空间。\nCould not prepare runtime files. Please download again or check free disk space.");
    if (!launch(cache + L"\\appBackpackTools.exe", arguments ? arguments : L"", cache, false))
        return fail(L"无法启动程序，请检查运行缓存目录。\nCould not start the application.");
    return 0;
}
