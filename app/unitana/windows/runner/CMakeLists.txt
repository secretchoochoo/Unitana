cmake_minimum_required(VERSION 3.14)

project(runner LANGUAGES CXX)

# The runner is built as part of the top-level windows/CMakeLists.txt and uses
# the BINARY_NAME set there.

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "flutter_window.h"
  "main.cpp"
  "run_loop.cpp"
  "run_loop.h"
  "utils.cpp"
  "utils.h"
  "win32_window.cpp"
  "win32_window.h"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

# Ensure Flutter's build steps run first.
add_dependencies(${BINARY_NAME} flutter_assemble)
