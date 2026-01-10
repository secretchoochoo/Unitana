#include "run_loop.h"

#include <windows.h>

void RunLoop::Quit() const {
  ::PostQuitMessage(0);
}
