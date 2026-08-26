import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loading spinner shown as a loading indicator.
/// Uses a simple CircularProgressIndicator instead of an animated logo
/// to avoid per-frame GPU repaints (the animated logo used repeat+reverse
/// which kept CanvasKit busy even during idle browsing).
class LoadingSpinner extends StatefulWidget {
  final Color? color;
  final double size;
  final bool alwaysShow;

  const LoadingSpinner({
    super.key,
    this.color,
    this.size = 80.0,
    this.alwaysShow = false,
  });

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner> {
  bool? _shouldShow;

  @override
  void initState() {
    super.initState();
    if (widget.alwaysShow) {
      _shouldShow = true;
    } else {
      _checkFirstLaunch();
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool('has_launched_logo') ?? false;
    if (!hasLaunched) {
      await prefs.setBool('has_launched_logo', true);
    }
    if (mounted) setState(() => _shouldShow = !hasLaunched);
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShow == null || !_shouldShow!) return const SizedBox.shrink();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
