import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with a secondary "super long-press" detector.
///
/// Only active in debug mode ([kDebugMode]). The gesture works alongside the
/// child's existing long-press (multi-select ~500ms):
///
/// - Press < [triggerDuration] then release → normal long-press triggers as
///   usual (handled by the child widget's own GestureRecognizer / InkWell).
/// - Hold for ≥ [triggerDuration] → [onDebugLongPress] fires with a haptic
///   heavy impact, and the press is consumed (the child's long-press is NOT
///   re-triggered on release).
///
/// Visual feedback: a progress indicator appears after the first 500ms of
/// holding so the user knows they're in the "keep holding" zone.
class DebugLongPressWrapper extends StatefulWidget {
  const DebugLongPressWrapper({
    super.key,
    required this.child,
    required this.onDebugLongPress,
    this.triggerDuration = const Duration(seconds: 3),
  });

  final Widget child;
  final VoidCallback onDebugLongPress;

  /// How long the user must hold to trigger the debug action.
  final Duration triggerDuration;

  @override
  State<DebugLongPressWrapper> createState() => _DebugLongPressWrapperState();
}

class _DebugLongPressWrapperState extends State<DebugLongPressWrapper>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _triggered = false;

  // Animation for the hold-progress indicator
  late final AnimationController _progressController;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.triggerDuration,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    _triggered = false;
    _timer?.cancel();

    // Show progress indicator after 600ms (just after normal long-press fires)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _timer != null) {
        setState(() => _showProgress = true);
        _progressController.forward(from: 0);
      }
    });

    _timer = Timer(widget.triggerDuration, () {
      if (!mounted) return;
      _triggered = true;
      _cleanup();
      HapticFeedback.heavyImpact();
      widget.onDebugLongPress();
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (_triggered) return; // Already handled
    _cleanup();
  }

  void _onLongPressCancel() {
    _cleanup();
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _showProgress = false);
      _progressController.stop();
      _progressController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    // In release builds, return the child as-is — no overhead, no gesture layer
    if (!kDebugMode) return widget.child;

    return GestureDetector(
      // Recognize long-press start/end without competing with the child's tap
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: Stack(
        children: [
          widget.child,
          // Hold-progress overlay (debug only)
          if (_showProgress)
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (_, _) => SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.error,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
