#include "utils.h"

#include <windows.h>
#include <shellapi.h>

#include <codecvt>
#include <locale>

std::vector<std::string> GetCommandLineArguments() {
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return {};
  }

  std::vector<std::string> result;
  result.reserve(argc);

  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
  for (int i = 0; i < argc; ++i) {
    result.push_back(converter.to_bytes(argv[i]));
  }

  ::LocalFree(argv);
  return result;
}
