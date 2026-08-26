import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration delay;

  const ShakeAnimation({
    Key? key,
    required this.child,
    this.animate = true,
    this.delay = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> {


  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _triggerSlideHint();
    }
  }

  Future<void> _triggerSlideHint() async {
    await Future.delayed(widget.delay);
    if (!mounted) return;

    final slidable = Slidable.of(context);
    if (slidable == null) return;

    // Peek with custom slower animation
    slidable.openStartActionPane(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    slidable.close(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
