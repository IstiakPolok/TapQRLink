import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../res/colors/app_color.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final IconData icon;
  final Duration duration;

  const SnackBarConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.icon,
    required this.duration,
  });

  factory SnackBarConfig.fromType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return SnackBarConfig(
          backgroundColor: AppColor.defaultColor,
          textColor: AppColor.backgroundColor,
          accentColor: AppColor.defaultColor.withValues(alpha: 0.8),
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 2),
        );
      case SnackBarType.error:
        return SnackBarConfig(
          backgroundColor: AppColor.redColor,
          textColor: AppColor.backgroundColor,
          accentColor: AppColor.redColor,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 3),
        );
      case SnackBarType.warning:
        return SnackBarConfig(
          backgroundColor: AppColor.warningColor,
          textColor: AppColor.backgroundColor,
          accentColor: AppColor.warningColor.withValues(alpha: 0.8),
          icon: Icons.warning,
          duration: const Duration(seconds: 2),
        );
      case SnackBarType.info:
        return SnackBarConfig(
          backgroundColor: AppColor.defaultColor,
          textColor: AppColor.backgroundColor,
          accentColor: AppColor.defaultColor.withValues(alpha: 0.8),
          icon: Icons.info_outline,
          duration: const Duration(seconds: 2),
        );
    }
  }
}

// ─── Queue ────────────────────────────────────────────────────────────────────

class _SnackBarQueue {
  static final _SnackBarQueue _instance = _SnackBarQueue._internal();
  factory _SnackBarQueue() => _instance;
  _SnackBarQueue._internal();

  bool _isProcessing = false;
  final List<_SnackBarJob> _queue = [];

  void enqueue(_SnackBarJob job) {
    _queue.add(job);
    if (!_isProcessing) _processQueue();
  }

  Future<void> _processQueue() async {
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      final completer = Completer<void>();
      _showOverlayEntry(job, onDone: completer.complete);
      await completer.future;
    }
    _isProcessing = false;
  }
}

class _SnackBarJob {
  final String title;
  final String message;
  final SnackBarConfig config;
  _SnackBarJob({
    required this.title,
    required this.message,
    required this.config,
  });
}

// ─── Core overlay presenter (no GetX context lookup) ─────────────────────────

void _showOverlayEntry(_SnackBarJob job, {required VoidCallback onDone}) {
  // Use GetX's own navigator key — always valid, no Overlay.of() lookup needed
  final overlayState = Get.key.currentState?.overlay;
  if (overlayState == null) {
    onDone();
    return;
  }

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _SnackBarOverlay(
      job: job,
      onDismiss: () {
        try {
          entry.remove();
        } catch (_) {}
        onDone();
      },
    ),
  );

  overlayState.insert(entry);
}

// ─── Animated overlay widget ──────────────────────────────────────────────────

class _SnackBarOverlay extends StatefulWidget {
  final _SnackBarJob job;
  final VoidCallback onDismiss;

  const _SnackBarOverlay({required this.job, required this.onDismiss});

  @override
  State<_SnackBarOverlay> createState() => _SnackBarOverlayState();
}

class _SnackBarOverlayState extends State<_SnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.job.config.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.job.config;
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [config.backgroundColor, config.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        config.icon,
                        color: config.textColor,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.title,
                            style: TextStyle(
                              color: config.textColor,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.job.message,
                            style: TextStyle(
                              color: config.textColor.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Public API ───────────────────────────────────────────────────────────────

void customSnackBar({
  required String title,
  required String message,
  SnackBarType type = SnackBarType.success,
  Color? backgroundColor,
  Color? textColor,
  Duration? duration,
}) {
  final base = SnackBarConfig.fromType(type);
  final config =
      (backgroundColor != null || textColor != null || duration != null)
      ? SnackBarConfig(
          backgroundColor: backgroundColor ?? base.backgroundColor,
          textColor: textColor ?? base.textColor,
          accentColor:
              backgroundColor?.withValues(alpha: 0.8) ?? base.accentColor,
          icon: base.icon,
          duration: duration ?? base.duration,
        )
      : base;

  _SnackBarQueue().enqueue(
    _SnackBarJob(title: title, message: message, config: config),
  );
}

void showCustomSnackBar({
  String? title,
  required String message,
  Color? backgroundColor,
  Duration? duration,
  bool isSuccess = false,
}) {
  SnackBarType snackBarType;

  if (title == 'Warning' || backgroundColor == AppColor.orangeColor) {
    snackBarType = SnackBarType.warning;
  } else if (isSuccess) {
    snackBarType = SnackBarType.success;
  } else {
    snackBarType = SnackBarType.error;
  }

  customSnackBar(
    title:
        title ??
        (isSuccess
            ? 'Success'
            : snackBarType == SnackBarType.warning
            ? 'Warning'
            : 'Error'),
    message: message,
    type: snackBarType,
    duration: duration,
  );
}

void showErrorSnackBar({
  String? title,
  required String message,
  Duration? duration,
}) => customSnackBar(
  title: title ?? 'Error',
  message: message,
  type: SnackBarType.error,
  duration: duration,
);

void showWarningSnackBar({
  String? title,
  required String message,
  Duration? duration,
}) => customSnackBar(
  title: title ?? 'Warning',
  message: message,
  type: SnackBarType.warning,
  duration: duration,
);

void showInfoSnackBar({
  required String title,
  required String message,
  Duration? duration,
}) => customSnackBar(
  title: title,
  message: message,
  type: SnackBarType.info,
  duration: duration,
);
