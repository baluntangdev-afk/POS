#ifndef RUNNER_TOUCH_KEYBOARD_GUARD_H_
#define RUNNER_TOUCH_KEYBOARD_GUARD_H_

#include <flutter/binary_messenger.h>

// Keeps the Windows on-screen touch keyboard (TabTip.exe /
// "IPTip_Main_Window") from appearing except when Dart tells us a real text
// field is focused.
//
// The Dart-side focus guard (`WindowsTouchKeyboard`) can only react to
// Flutter's own focus-tree changes, but the OS decides to show the touch
// keyboard based on raw touch/pointer input hitting the native window —
// including taps that land on empty space and never change Flutter's focus
// at all. That gap is invisible from Dart. `InstallTouchKeyboardWatcher`
// closes it by listening for the actual Win32 "a window became visible"
// event system-wide (no DLL injection required) and closing the touch
// keyboard window the instant it appears, unless explicitly allowed.
namespace touch_keyboard_guard {

// Registers the "pos_kiosk/touch_keyboard" MethodChannel used by Dart to
// tell native code whether the touch keyboard is currently allowed to be
// shown (i.e. a real text field is focused). Call once, after the Flutter
// engine has been created.
void RegisterChannel(flutter::BinaryMessenger* messenger);

// Installs a process-wide WinEvent hook that closes the touch keyboard
// window the instant it becomes visible while not allowed. Must be called
// from a thread that pumps a Win32 message loop (out-of-context WinEvent
// hooks are delivered via that loop). Safe to call more than once.
void InstallWatcher();

}  // namespace touch_keyboard_guard

#endif  // RUNNER_TOUCH_KEYBOARD_GUARD_H_
