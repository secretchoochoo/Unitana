#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height) : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  bool CreateAndShow(const std::wstring& title, const Point& origin, const Size& size);

  void Show() const;

  void SetQuitOnClose(bool quit_on_close);

  RECT GetClientArea() const;

  HWND GetHandle() const;

 protected:
  virtual bool OnCreate();
  virtual void OnDestroy();

  virtual LRESULT MessageHandler(HWND window,
                                 UINT message,
                                 WPARAM wparam,
                                 LPARAM lparam) noexcept;

  void SetChildContent(HWND content);

 private:
  static LRESULT CALLBACK WindowProc(HWND window,
                                     UINT message,
                                     WPARAM wparam,
                                     LPARAM lparam) noexcept;

  void RegisterWindowClass();

  HINSTANCE instance_handle_ = nullptr;
  HWND window_handle_ = nullptr;
  bool quit_on_close_ = false;
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
