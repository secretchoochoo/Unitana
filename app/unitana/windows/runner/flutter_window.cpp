#include "flutter_window.h"

#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() = default;

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([this]() { this->Show(); });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  flutter_controller_ = nullptr;

  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND window,
                                      UINT message,
                                      WPARAM wparam,
                                      LPARAM lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(window, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  return Win32Window::MessageHandler(window, message, wparam, lparam);
}
