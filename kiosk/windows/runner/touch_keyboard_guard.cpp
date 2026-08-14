#include "touch_keyboard_guard.h"

#include <windows.h>

#include <atomic>
#include <cstdio>
#include <cwchar>
#include <memory>
#include <string>
#include <sys/stat.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

namespace touch_keyboard_guard {

namespace {

// The legacy touch-keyboard host (TabTip.exe, used through Windows 10 1809)
// creates a window of this class.
constexpr wchar_t kTouchKeyboardClassName[] = L"IPTip_Main_Window";

// Since Windows 10 1903, the touch keyboard is instead drawn by a separate
// process, TextInputHost.exe, as a CoreWindow with no distinctive class name
// of its own — so on that (now much more common) path, matching only
// IPTip_Main_Window silently matches nothing. Checking the owning process
// name catches this case too. (TextInputHost.exe also hosts the emoji panel
// and clipboard-history flyout; closing those unexpectedly is an acceptable
// trade-off for a single-purpose kiosk app that doesn't use either.)
constexpr wchar_t kTextInputHostProcessName[] = L"TextInputHost.exe";

constexpr char kChannelName[] = "pos_kiosk/touch_keyboard";

// Whether Dart currently reports a real text field as focused. Written from
// the UI thread's method-channel handler, read from the WinEvent callback
// (also delivered on the UI thread via its message loop, but kept atomic
// since WinEvent delivery timing relative to the message loop isn't a hard
// guarantee we want to depend on).
std::atomic<bool> g_allowed{false};
UINT_PTR g_poll_timer = 0;

// Raw pointer into the channel RegisterChannel() leaks intentionally (see
// below) — used to call back into Dart when the keyboard is closed by
// something other than us (the user tapping its own close button, which
// never touches Flutter's focus tree at all).
flutter::MethodChannel<flutter::EncodableValue>* g_channel = nullptr;

// Closes the touch keyboard the same way the previous Dart-only guard did:
// hide it immediately, then ask it to retract via WM_SYSCOMMAND/SC_CLOSE so
// it doesn't just repaint itself on the next trigger.
void CloseIfVisible(HWND hwnd) {
  if (!::IsWindow(hwnd)) return;
  ::ShowWindow(hwnd, SW_HIDE);
  ::SendMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
}

// Empty string if the owning process can't be queried (e.g. it's running
// elevated and we aren't).
std::wstring GetOwningProcessName(HWND hwnd) {
  DWORD pid = 0;
  ::GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0) return L"";

  HANDLE process =
      ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (process == nullptr) return L"";

  wchar_t path[MAX_PATH];
  DWORD path_len = ARRAYSIZE(path);
  std::wstring name;
  if (::QueryFullProcessImageNameW(process, 0, path, &path_len)) {
    const wchar_t* file_name = wcsrchr(path, L'\\');
    name = file_name ? file_name + 1 : path;
  }
  ::CloseHandle(process);
  return name;
}

// Appends one line to %LOCALAPPDATA%\POSKiosk\touch_keyboard.log — evidence
// of every top-level window shown while the keyboard isn't supposed to be,
// so a report from the field ("it still appeared") can be diagnosed from
// this file instead of needing anyone to poke around in Task Manager on the
// kiosk itself. Rotated (deleted and restarted) once it passes ~2 MB so a
// kiosk that runs for weeks without a reboot doesn't grow it unbounded.
void LogEvent(const std::wstring& line) {
  wchar_t local_app_data[MAX_PATH];
  DWORD len = ::GetEnvironmentVariableW(L"LOCALAPPDATA", local_app_data,
                                         ARRAYSIZE(local_app_data));
  if (len == 0 || len >= ARRAYSIZE(local_app_data)) return;

  std::wstring dir = std::wstring(local_app_data) + L"\\POSKiosk";
  ::CreateDirectoryW(dir.c_str(), nullptr);
  std::wstring path = dir + L"\\touch_keyboard.log";

  struct _stat64 file_stat;
  if (_wstat64(path.c_str(), &file_stat) == 0 &&
      file_stat.st_size > 2 * 1024 * 1024) {
    ::DeleteFileW(path.c_str());
  }

  FILE* file = nullptr;
  if (_wfopen_s(&file, path.c_str(), L"a, ccs=UTF-8") != 0 ||
      file == nullptr) {
    return;
  }
  SYSTEMTIME t;
  ::GetLocalTime(&t);
  fwprintf(file, L"[%04d-%02d-%02d %02d:%02d:%02d] %s\n", t.wYear, t.wMonth,
            t.wDay, t.wHour, t.wMinute, t.wSecond, line.c_str());
  fclose(file);
}

bool IsTouchKeyboardWindow(const wchar_t* class_name,
                            const std::wstring& process_name) {
  if (wcscmp(class_name, kTouchKeyboardClassName) == 0) {
    return true;
  }
  return _wcsicmp(process_name.c_str(), kTextInputHostProcessName) == 0;
}

// Whether the kiosk itself is the app the user is currently interacting with.
//
// This guard must only suppress the touch keyboard *for this app*. Without this
// check it would close the keyboard system-wide for as long as the kiosk
// process is alive — including the keyboard another app legitimately opened
// after the user alt-tabbed away, which is not ours to take away.
bool IsOurAppForeground() {
  HWND foreground = ::GetForegroundWindow();
  if (foreground == nullptr) return false;

  DWORD pid = 0;
  ::GetWindowThreadProcessId(foreground, &pid);
  if (pid == ::GetCurrentProcessId()) return true;

  // The touch keyboard can itself take foreground at the moment it appears, in
  // which case the window in front is the keyboard rather than the kiosk. Treat
  // that as still-ours so it can be closed, instead of deadlocking on "the
  // keyboard is up, therefore we aren't foreground, therefore leave it alone".
  wchar_t class_name[256] = L"";
  ::GetClassNameW(foreground, class_name, ARRAYSIZE(class_name));
  return IsTouchKeyboardWindow(class_name, GetOwningProcessName(foreground));
}

// EVENT_OBJECT_SHOW/HIDE never fire for this window on Windows 11: the
// modern touch keyboard is a composition-hosted flyout (same family as the
// shell's own "Microsoft.UI.Content.PopupWindowSiteBridge" surfaces) that
// stays WS_VISIBLE the whole time and is animated fully off-screen instead
// of actually being hidden. So instead of waiting for an event that may
// never come, a short poll checks the window's real on-screen position
// directly — this works regardless of which technique (classic show/hide or
// composition slide) the OS build in use happens to rely on.
BOOL CALLBACK FindTouchKeyboardEnumProc(HWND hwnd, LPARAM out_hwnd) {
  wchar_t class_name[256] = L"";
  ::GetClassNameW(hwnd, class_name, ARRAYSIZE(class_name));
  std::wstring process_name = GetOwningProcessName(hwnd);
  if (!IsTouchKeyboardWindow(class_name, process_name)) return TRUE;
  *reinterpret_cast<HWND*>(out_hwnd) = hwnd;
  return FALSE;
}

HWND FindTouchKeyboardWindow() {
  HWND found = nullptr;
  ::EnumWindows(FindTouchKeyboardEnumProc, reinterpret_cast<LPARAM>(&found));
  return found;
}

// WS_VISIBLE alone can't tell "shown" from "animated off-screen" for this
// window (see above), so this checks whether any part of its rect actually
// falls within the virtual screen instead.
bool IsWindowOnScreen(HWND hwnd) {
  if (!::IsWindowVisible(hwnd)) return false;

  RECT rect;
  if (!::GetWindowRect(hwnd, &rect)) return false;
  if (rect.right <= rect.left || rect.bottom <= rect.top) return false;

  int screen_top = ::GetSystemMetrics(SM_YVIRTUALSCREEN);
  int screen_bottom = screen_top + ::GetSystemMetrics(SM_CYVIRTUALSCREEN);
  return rect.top < screen_bottom && rect.bottom > screen_top;
}

bool g_keyboard_was_on_screen = false;

void CALLBACK PollTimerProc(HWND, UINT, UINT_PTR, DWORD) {
  // Scope the whole guard to this app: while the user is in another window, the
  // touch keyboard is that app's business, not ours. State tracking is left
  // untouched so returning to the kiosk re-evaluates from scratch.
  if (!IsOurAppForeground()) return;

  HWND hwnd = FindTouchKeyboardWindow();
  bool on_screen = hwnd != nullptr && IsWindowOnScreen(hwnd);
  bool allowed = g_allowed.load(std::memory_order_relaxed);

  if (on_screen && !g_keyboard_was_on_screen) {
    wchar_t class_name[256] = L"";
    ::GetClassNameW(hwnd, class_name, ARRAYSIZE(class_name));
    std::wstring process_name = GetOwningProcessName(hwnd);
    wchar_t line[512];
    swprintf_s(line, L"POLL appeared class=%s process=%s allowed=%s",
               class_name, process_name.empty() ? L"?" : process_name.c_str(),
               allowed ? L"yes" : L"no (closing)");
    LogEvent(line);

    if (!allowed) {
      CloseIfVisible(hwnd);
      on_screen = false;
    }
  } else if (on_screen && !allowed) {
    // Still on screen despite not being allowed — e.g. it re-animated back
    // in, or the previous close attempt didn't stick. Keep insisting.
    CloseIfVisible(hwnd);
    on_screen = false;
  } else if (!on_screen && g_keyboard_was_on_screen && allowed) {
    // It just went away on its own while Dart still thinks a field is
    // focused — the user tapping the keyboard's own close button, which is
    // native OS chrome Flutter's focus tree never finds out about by
    // itself. Tell Dart so it can drop focus; otherwise every later tap
    // anywhere in the app re-triggers Windows' auto-invoke, since as far as
    // the app knows a field is still focused and showing is still allowed.
    LogEvent(L"POLL disappeared while allowed (externally closed, notifying Dart)");
    if (g_channel != nullptr) {
      g_channel->InvokeMethod("externallyClosed", nullptr);
    }
  }

  g_keyboard_was_on_screen = on_screen;
}

}  // namespace

void RegisterChannel(flutter::BinaryMessenger* messenger) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "setAllowed") {
          const auto* allowed = std::get_if<bool>(call.arguments());
          g_allowed.store(allowed != nullptr && *allowed,
                           std::memory_order_relaxed);
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  // Intentionally leaked: lives for the process lifetime, same as the
  // window/engine it's registered against.
  g_channel = channel.release();
}

void InstallWatcher() {
  if (g_poll_timer != 0) return;
  // 150ms: frequent enough that the keyboard sliding into view is caught
  // and reversed before it reads as "appeared" to someone watching the
  // screen, without polling aggressively enough to matter on kiosk
  // hardware. Requires a message loop on this thread to deliver WM_TIMER
  // (main.cpp's GetMessage/DispatchMessage loop provides that).
  g_poll_timer = ::SetTimer(nullptr, 0, 150, PollTimerProc);
}

}  // namespace touch_keyboard_guard
