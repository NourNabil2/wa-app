import 'dart:async';
import 'package:flutter/material.dart';

/// Simple inline countdown — e.g. "ينتهي خلال 02:14"
/// Updates every minute (not every second) to avoid per-second repaints
/// on every product card in the grid.
class ProductCountdownTimer extends StatefulWidget {
  final DateTime endsAt;
  const ProductCountdownTimer({super.key, required this.endsAt});

  @override
  State<ProductCountdownTimer> createState() => _ProductCountdownTimerState();
}

class _ProductCountdownTimerState extends State<ProductCountdownTimer> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    // Update every minute — seconds ticking on every product card caused
    // dozens of repaints per second across the home page grid.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final diff = widget.endsAt.difference(DateTime.now());
    setState(() => _left = diff.isNegative ? Duration.zero : diff);
    if (diff.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_left.inMinutes <= 0) return const SizedBox.shrink();

    final h = _left.inHours.toString().padLeft(2, '0');
    final m = _left.inMinutes.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 11, color: Color(0xFFE53935)),
        const SizedBox(width: 4),
        Text(
          '$h:$m',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE53935),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
