#include "win32_window.h"

#include <windowsx.h>

#include <cassert>

namespace {

const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// Returns the DPI for the window, or 96 if the API isn't available.
int GetDpiForWindowFallback(HWND hwnd) {
  HMODULE user32 = ::GetModuleHandleW(L"user32.dll");
  if (user32) {
    using GetDpiForWindow_t = UINT(WINAPI*)(HWND);
    auto get_dpi_for_window =
        reinterpret_cast<GetDpiForWindow_t>(::GetProcAddress(user32, "GetDpiForWindow"));
    if (get_dpi_for_window) {
      return static_cast<int>(get_dpi_for_window(hwnd));
    }
  }
  return 96;
}

}  // namespace

Win32Window::Win32Window() {
  instance_handle_ = ::GetModuleHandle(nullptr);
  RegisterWindowClass();
}

Win32Window::~Win32Window() {
  if (window_handle_) {
    ::DestroyWindow(window_handle_);
  }
}

bool Win32Window::CreateAndShow(const std::wstring& title,
                                const Point& origin,
                                const Size& size) {
  DWORD style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;

  RECT window_rect = {static_cast<LONG>(origin.x),
                      static_cast<LONG>(origin.y),
                      static_cast<LONG>(origin.x + size.width),
                      static_cast<LONG>(origin.y + size.height)};

  ::AdjustWindowRect(&window_rect, style, false);

  window_handle_ = ::CreateWindowExW(
      0, kWindowClassName, title.c_str(), style, window_rect.left, window_rect.top,
      window_rect.right - window_rect.left, window_rect.bottom - window_rect.top,
      nullptr, nullptr, instance_handle_, this);

  return window_handle_ != nullptr;
}

void Win32Window::Show() const {
  ::ShowWindow(window_handle_, SW_SHOWNORMAL);
  ::UpdateWindow(window_handle_);
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

RECT Win32Window::GetClientArea() const {
  RECT rect;
  ::GetClientRect(window_handle_, &rect);
  return rect;
}

HWND Win32Window::GetHandle() const {
  return window_handle_;
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {
  if (quit_on_close_) {
    ::PostQuitMessage(0);
  }
}

LRESULT Win32Window::MessageHandler(HWND window,
                                    UINT message,
                                    WPARAM wparam,
                                    LPARAM lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      OnDestroy();
      return 0;

    case WM_SIZE:
      if (child_content_) {
        RECT frame = GetClientArea();
        ::MoveWindow(child_content_, frame.left, frame.top,
                     frame.right - frame.left, frame.bottom - frame.top, TRUE);
      }
      return 0;

    case WM_GETDPISCALEDSIZE: {
      // Provide a best-effort fallback to avoid resize glitches on DPI change.
      auto dpi = GetDpiForWindowFallback(window);
      if (dpi == 96) {
        return 0;
      }
      return 0;
    }

    default:
      return ::DefWindowProc(window, message, wparam, lparam);
  }
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  if (child_content_) {
    ::SetParent(child_content_, window_handle_);
    RECT frame = GetClientArea();
    ::MoveWindow(child_content_, frame.left, frame.top,
                 frame.right - frame.left, frame.bottom - frame.top, TRUE);
  }
}

LRESULT CALLBACK Win32Window::WindowProc(HWND window,
                                         UINT message,
                                         WPARAM wparam,
                                         LPARAM lparam) noexcept {
  Win32Window* that = nullptr;

  if (message == WM_NCCREATE) {
    auto create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    that = reinterpret_cast<Win32Window*>(create_struct->lpCreateParams);
    assert(that);
    ::SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(that));
    that->window_handle_ = window;
  } else {
    that = reinterpret_cast<Win32Window*>(::GetWindowLongPtr(window, GWLP_USERDATA));
  }

  if (that) {
    if (message == WM_CREATE) {
      if (!that->OnCreate()) {
        return -1;
      }
    }
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return ::DefWindowProc(window, message, wparam, lparam);
}

void Win32Window::RegisterWindowClass() {
  WNDCLASSW window_class = {};
  window_class.lpfnWndProc = Win32Window::WindowProc;
  window_class.hInstance = instance_handle_;
  window_class.lpszClassName = kWindowClassName;
  window_class.hCursor = ::LoadCursor(nullptr, IDC_ARROW);

  ::RegisterClassW(&window_class);
}
