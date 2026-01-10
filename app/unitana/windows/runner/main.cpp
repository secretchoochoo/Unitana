#include <flutter/dart_project.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line,
                      _In_ int show_command) {
  // Allow console output when launched from a terminal.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) &&
      ::GetLastError() != ERROR_ACCESS_DENIED) {
    // No console to attach to.
  }

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(GetCommandLineArguments());

  FlutterWindow window(project);

  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  if (!window.CreateAndShow(L"Unitana", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  return EXIT_SUCCESS;
}
