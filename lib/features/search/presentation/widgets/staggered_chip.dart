// lib/core/widgets/staggered_chip.dart

import 'package:flutter/material.dart';

class StaggeredChip extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const StaggeredChip({
    super.key,
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<StaggeredChip> createState() => _StaggeredChipState();
}

class _StaggeredChipState extends State<StaggeredChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}