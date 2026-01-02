import "dart:async";

import "package:flutter/material.dart";

import "../widgets/unitana_notice_card.dart";

class UnitanaToast {
  static void showSuccess(
    BuildContext context,
    String text, {
    Duration duration = const Duration(seconds: 2),
    Key? key,
  }) {
    _show(
      context,
      text: text,
      kind: UnitanaNoticeKind.success,
      duration: duration,
      key: key,
    );
  }

  static void showInfo(
    BuildContext context,
    String text, {
    Duration duration = const Duration(seconds: 2),
    Key? key,
  }) {
    _show(
      context,
      text: text,
      kind: UnitanaNoticeKind.info,
      duration: duration,
      key: key,
    );
  }

  static void showError(
    BuildContext context,
    String text, {
    Duration duration = const Duration(seconds: 2),
    Key? key,
  }) {
    _show(
      context,
      text: text,
      kind: UnitanaNoticeKind.error,
      duration: duration,
      key: key,
    );
  }

  static void _show(
    BuildContext context, {
    required String text,
    required UnitanaNoticeKind kind,
    required Duration duration,
    Key? key,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        key: key,
        text: text,
        kind: kind,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    super.key,
    required this.text,
    required this.kind,
    required this.duration,
    required this.onDismissed,
  });

  final String text;
  final UnitanaNoticeKind kind;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });

    _timer = Timer(widget.duration, _beginDismiss);
  }

  void _beginDismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep toasts visible while avoiding interference with AppBar actions.
    // We bias toward "below the toolbar" so that taps on top-right buttons
    // (like Dashboard edit Done/Cancel) remain reliable.
    const toolbarOffset = kToolbarHeight + 8;

    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: toolbarOffset),
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: _beginDismiss,
                child: UnitanaNoticeCard(
                  text: widget.text,
                  kind: widget.kind,
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
