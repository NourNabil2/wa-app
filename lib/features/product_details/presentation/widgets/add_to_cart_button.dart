// lib/core/widgets/add_to_cart_button.dart

import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/theme/colors.dart';

/// زرار "أضف إلى السلة" مع أنيميشن:
///   1. Wobble لما يتضغط
///   2. Spinner أثناء الـ loading
///   3. Confetti burst + checkmark لما ينجح
///
/// الاستخدام:
///   AddToCartButton(
///     isLoading: cartState is AddingToCart,
///     onPressed: () => cubit.addToCart(...),
///   )
class AddToCartButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;

  const AddToCartButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton>
    with TickerProviderStateMixin {
  // ── Wobble ────────────────────────────────────────────────────────────────
  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  // ── Content slide (idle ↔ loading ↔ success) ──────────────────────────────
  late final AnimationController _slideCtrl;
  late final Animation<double> _idleSlide;
  late final Animation<double> _loadingSlide;
  late final Animation<double> _successSlide;
  late final Animation<Color?> _bgColor;

  // ── Checkmark draw-on ─────────────────────────────────────────────────────
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkDraw;

  // ── Confetti ──────────────────────────────────────────────────────────────
  late final AnimationController _confettiCtrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  _Phase _phase = _Phase.idle;
  bool _didSucceed = false;

  static const _successColor = Color(0xFF0F6E56);
  static const _idleColor    = ColorsManager.primaryColor;

  @override
  void initState() {
    super.initState();

    // Wobble — elastic bounce
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wobbleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.94), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.00), weight: 30),
    ]).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.linear));

    // Slide controller for content phases
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _idleSlide    = Tween(begin: 0.0, end: -1.0).animate(_slideCtrl);
    _loadingSlide = Tween(begin: 1.0, end: 0.0).animate(_slideCtrl);
    _successSlide = Tween(begin: 1.0, end: 0.0).animate(_slideCtrl);
    _bgColor = ColorTween(begin: _idleColor, end: _successColor)
        .animate(_slideCtrl);

    // Checkmark draw
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _checkDraw = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    // Confetti burst
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(AddToCartButton old) {
    super.didUpdateWidget(old);

    // Transition: idle → loading
    if (!old.isLoading && widget.isLoading && _phase == _Phase.idle) {
      _phase = _Phase.loading;
      _wobbleCtrl.forward(from: 0);
      _slideCtrl.forward();
    }

    // Transition: loading → success (isLoading went false and was loading before)
    if (old.isLoading && !widget.isLoading && _phase == _Phase.loading) {
      _phase = _Phase.success;
      _didSucceed = true;
      _triggerSuccess();
    }
  }

  void _triggerSuccess() {
    _slideCtrl.animateTo(1.0, duration: const Duration(milliseconds: 280));
    _checkCtrl.forward(from: 0);
    _spawnParticles();
    _confettiCtrl.forward(from: 0);

    // Reset back to idle after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _slideCtrl.animateTo(0, duration: const Duration(milliseconds: 300));
      setState(() {
        _phase = _Phase.idle;
        _didSucceed = false;
      });
      _checkCtrl.reset();
      _particles.clear();
    });
  }

  void _spawnParticles() {
    final colors = [
      ColorsManager.primaryColor,
      const Color(0xFFFAC775),
      const Color(0xFFF09595),
      const Color(0xFF85B7EB),
      const Color(0xFFAFA9EC),
      const Color(0xFF5DCAA5),
    ];
    setState(() {
      _particles.clear();
      for (int i = 0; i < 14; i++) {
        final angle = (2 * pi / 14) * i + (_rng.nextDouble() * 0.4 - 0.2);
        final dist = 55.0 + _rng.nextDouble() * 35;
        _particles.add(_Particle(
          color: colors[i % colors.length],
          dx: cos(angle) * dist,
          dy: sin(angle) * dist,
          size: 5.0 + _rng.nextDouble() * 4,
          isCircle: _rng.nextBool(),
        ));
      }
    });
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    _slideCtrl.dispose();
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _wobbleAnim,
        _slideCtrl,
        _checkCtrl,
        _confettiCtrl,
      ]),
      builder: (context, _) {
        return Transform.scale(
          scale: _wobbleAnim.value,
          child: SizedBox(
            height: widget.height,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _didSucceed ? _bgColor.value : _idleColor,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ── Confetti layer ───────────────────────────────
                    if (_particles.isNotEmpty)
                      ..._particles.map((p) {
                        final t = _confettiCtrl.value;
                        final opacity = (1.0 - t).clamp(0.0, 1.0);
                        final scale  = (1.0 - t * 0.7).clamp(0.0, 1.0);
                        return Positioned.fill(
                          child: OverflowBox(
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: Transform.translate(
                              offset: Offset(p.dx * t, p.dy * t),
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: p.size,
                                    height: p.size,
                                    decoration: BoxDecoration(
                                      color: p.color,
                                      shape: p.isCircle
                                          ? BoxShape.circle
                                          : BoxShape.rectangle,
                                      borderRadius: p.isCircle
                                          ? null
                                          : BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    // ── Idle label ───────────────────────────────────
                    _buildSlot(
                      visible: _phase == _Phase.idle,
                      slideAnim: _idleSlide,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'product.actions.add_to_cart'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Loading label ────────────────────────────────
                    _buildSlot(
                      visible: _phase == _Phase.loading,
                      slideAnim: _loadingSlide,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Spinner(),
                          const SizedBox(width: 10),
                          Text(
                            'product.actions.adding_to_cart'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Success label ────────────────────────────────
                    _buildSlot(
                      visible: _phase == _Phase.success,
                      slideAnim: _successSlide,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedCheck(progress: _checkDraw.value),
                          const SizedBox(width: 10),
                          Text(
                            'product.actions.added_success'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlot({
    required bool visible,
    required Animation<double> slideAnim,
    required Widget child,
  }) {
    final offset = slideAnim.value * widget.height;
    return Transform.translate(
      offset: Offset(0, visible ? 0 : offset),
      child: Opacity(
        opacity: visible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}

// ── Phase enum ────────────────────────────────────────────────────────────────

enum _Phase { idle, loading, success }

// ── Particle data ─────────────────────────────────────────────────────────────

class _Particle {
  final Color color;
  final double dx;
  final double dy;
  final double size;
  final bool isCircle;

  const _Particle({
    required this.color,
    required this.dx,
    required this.dy,
    required this.size,
    required this.isCircle,
  });
}

// ── Spinner widget ────────────────────────────────────────────────────────────

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * pi,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: 0.75,
            strokeWidth: 2.5,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

// ── Animated Checkmark ────────────────────────────────────────────────────────

class _AnimatedCheck extends StatelessWidget {
  final double progress;
  const _AnimatedCheck({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _CheckPainter(progress: progress),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Define checkmark path points (normalized 0-1)
    final p1 = Offset(size.width * 0.18, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.76);
    final p3 = Offset(size.width * 0.82, size.height * 0.26);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    // Measure and draw partial path
    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}