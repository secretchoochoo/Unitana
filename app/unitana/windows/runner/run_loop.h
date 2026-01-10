#ifndef RUNNER_RUN_LOOP_H_
#define RUNNER_RUN_LOOP_H_

// Included for compatibility with older runner templates.
// The current runner uses a standard Win32 message loop in main.cpp.

class RunLoop {
 public:
  RunLoop() = default;
  ~RunLoop() = default;

  void Quit() const;
};

#endif  // RUNNER_RUN_LOOP_H_
