import 'dart:math';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_buton.dart';
import '../../../../core/widgets/sar_symbol.dart';
import '../../../../core/widgets/selectable.dart';
import '../../domain/entities/place_order_result.dart';
import 'package:fastway/features/user_data/user_repo.dart';

// BUG-9 FIX: was OrderEntity — checkout now hands us a PlaceOrderResult.
// OrderEntity is only available after a GET /orders/{id} call which checkout
// does not perform. PlaceOrderResult carries orderNumber, status, and total
// which is all we need for the success screen.
//
// T8.7: Added confetti animation using CustomPainter + AnimationController.
class OrderSuccessScreen extends StatefulWidget {
  final PlaceOrderResult result;

  const OrderSuccessScreen({super.key, required this.result});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  // ── Confetti (T8.7) ──────────────────────────────────────────────────────
  late final AnimationController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Confetti falls over 3 seconds
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    // Success icon bounces in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show "create account" sheet only for actual guests.
      if (UserRepository().currentUser == null) {
        _showCreateAccountBottomSheet();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showCreateAccountBottomSheet() {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(h.s24, v.s24, h.s24, v.s32 + MediaQuery.viewInsetsOf(context).bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.zero),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12))),
              SizedBox(height: v.s24),
              const Icon(Icons.person_add_alt_1_rounded, size: 48, color: ColorsManager.primaryColor),
              SizedBox(height: v.s16),
              Text(
                'checkout.success.track_easy'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: v.s8),
              Text(
                'checkout.success.create_account_desc'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: v.s24),
              AppButton(
                text: 'order_success.create_account_cta'.tr(),
                onPressed: () {
                  Navigator.pop(context);
                  AppNavigator.pushNamed(context, Routes.login);
                },
                horizontalPadding: 0,
              ),
              SizedBox(height: v.s12),
              AppOutlinedButton(
                text: 'order_success.not_now'.tr(),
                onPressed: () => Navigator.pop(context),
                active: true,
                horizontalPadding: 0,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWebLayout(context)) {
      return _WebOrderSuccessBody(
        result: widget.result,
        confettiController: _confettiController,
        scaleAnim: _scaleAnim,
      );
    }

    return _MobileOrderSuccessBody(
      result: widget.result,
      confettiController: _confettiController,
      scaleAnim: _scaleAnim,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB LAYOUT — SimpleWebShell with header + footer
// ═══════════════════════════════════════════════════════════════════════════════
class _WebOrderSuccessBody extends StatelessWidget {
  final PlaceOrderResult result;
  final AnimationController confettiController;
  final Animation<double> scaleAnim;

  const _WebOrderSuccessBody({
    required this.result,
    required this.confettiController,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SimpleWebShell(
      content: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.95).clamp(0.0, 560.0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                    // ── Bouncing success icon ─────────────────────────────
                    ScaleTransition(
                      scale: scaleAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: ColorsManager.successSurface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.primaryColor.withValues(alpha: 0.15),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Title ────────────────────────────────────────────
                    Text(
                      'order_success.title'.tr(),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // ── Subtitle ─────────────────────────────────────────
                    Text(
                      'order_success.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: ColorsManager.defaultTextSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Order details card ────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          _WebDetailRow(
                            label: 'order_success.order_number'.tr(),
                            value: result.orderNumber,
                            isHighlighted: true,
                          ),
                          _WebDivider(isDark: isDark),
                          _WebDetailRow(
                            label: 'order_success.status'.tr(),
                            value: result.status,
                          ),
                          if (result.estimatedDelivery != null) ...[
                            _WebDivider(isDark: isDark),
                            _WebDetailRow(
                              label: 'order_success.estimated_delivery'.tr(),
                              value: result.estimatedDelivery!,
                            ),
                          ],
                          _WebDivider(isDark: isDark),
                          _WebDetailRow(
                            label: 'order_success.total'.tr(),
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SarSymbol(
                                  size: 13,
                                  color: ColorsManager.primaryColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  result.total.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: ColorsManager.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),

                    // ── Points earned banner ──────────────────────────────
                    if ((result.pointsEarned ?? 0) > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: ColorsManager.primaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorsManager.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: ColorsManager.primaryColor, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'order_success.points_earned'.tr(
                                namedArgs: {'points': result.pointsEarned.toString()},
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorsManager.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Action buttons ────────────────────────────────────
                    LayoutBuilder(builder: (context, cs) {
                      final isNarrow = cs.maxWidth < 420;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              text: 'order_success.track_order'.tr(),
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, Routes.orderTracking,
                                arguments: result.orderNumber, (_) => false,
                              ),
                              horizontalPadding: 0,
                              verticalPadding: 16,
                              borderRadius: 16,
                            ),
                            const SizedBox(height: 12),
                            AppOutlinedButton(
                              text: 'order_success.continue_shopping'.tr(),
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, Routes.dashBoard, (_) => false,
                              ),
                              active: true,
                              horizontalPadding: 0,
                              verticalPadding: 0,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'order_success.track_order'.tr(),
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, Routes.orderTracking,
                                arguments: result.orderNumber, (_) => false,
                              ),
                              horizontalPadding: 0,
                              verticalPadding: 16,
                              borderRadius: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppOutlinedButton(
                              text: 'order_success.continue_shopping'.tr(),
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, Routes.dashBoard, (_) => false,
                              ),
                              active: true,
                              horizontalPadding: 0,
                              verticalPadding: 0,
                            ),
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Web helper widgets ────────────────────────────────────────────────────────

class _WebDivider extends StatelessWidget {
  final bool isDark;
  const _WebDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 28,
        thickness: 1,
        color: isDark ? Colors.white10 : Colors.grey.shade100,
      );
}

class _WebDetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isHighlighted;

  const _WebDetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Selectable(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: ColorsManager.defaultTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (valueWidget != null)
            valueWidget!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted
                    ? ColorsManager.primaryColor
                    : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT — original full-screen design preserved
// ═══════════════════════════════════════════════════════════════════════════════
class _MobileOrderSuccessBody extends StatelessWidget {
  final PlaceOrderResult result;
  final AnimationController confettiController;
  final Animation<double> scaleAnim;

  const _MobileOrderSuccessBody({
    required this.result,
    required this.confettiController,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;

    return Scaffold(
      backgroundColor: ColorsManager.inputSurface,
      body: Stack(
        children: [
          // ── T8.7: Confetti overlay ────────────────────────────────────────
          AnimatedBuilder(
            animation: confettiController,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(progress: confettiController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: h.s24, vertical: v.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: v.s16),

                  // ── Bouncing success icon ─────────────────────────────────
                  ScaleTransition(
                    scale: scaleAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: ColorsManager.successSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 60,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: v.s24),

                  // ── Title ──────────────────────────────────────────────────
                  Text(
                    'order_success.title'.tr(),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ColorsManager.defaultText,
                    ),
                  ),

                  SizedBox(height: v.s10),

                  // ── Subtitle ───────────────────────────────────────────────
                  Text(
                    'order_success.subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorsManager.defaultTextSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: v.s24),

                  // ── Order details card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorsManager.defaultSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorsManager.backgroundCard),
                    ),
                    child: Column(
                      children: [
                        _OrderDetailRow(
                          label: 'order_success.order_number'.tr(),
                          value: result.orderNumber,
                          isHighlighted: true,
                        ),
                        Divider(height: v.s24, color: ColorsManager.backgroundCard),
                        _OrderDetailRow(
                          label: 'order_success.status'.tr(),
                          value: result.status,
                        ),
                        if (result.estimatedDelivery != null) ...[
                          Divider(height: v.s24, color: ColorsManager.backgroundCard),
                          _OrderDetailRow(
                            label: 'order_success.estimated_delivery'.tr(),
                            value: result.estimatedDelivery!,
                          ),
                        ],
                        Divider(height: v.s24, color: ColorsManager.backgroundCard),
                        _OrderDetailRow(
                          label: 'order_success.total'.tr(),
                          valueWidget: SarText(
                            price: result.total.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ColorsManager.primaryColor,
                            ),
                          ),
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),

                  // ── Points earned banner ───────────────────────────────────
                  if ((result.pointsEarned ?? 0) > 0) ...[
                    SizedBox(height: v.s16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorsManager.primaryColor.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded, color: ColorsManager.primaryColor, size: 20),
                          SizedBox(width: h.s8),
                          Text(
                            'order_success.points_earned'.tr(
                              namedArgs: {'points': result.pointsEarned.toString()},
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ColorsManager.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: v.s32),

                  // ── Track order button ─────────────────────────────────────
                  AppButton(
                    text: 'order_success.track_order'.tr(),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.orderTracking,
                      arguments: result.orderNumber,
                          (_) => false,
                    ),
                    horizontalPadding: 0,
                    verticalPadding: 0,
                  ),

                  SizedBox(height: v.s12),

                  // ── Continue shopping button ───────────────────────────────
                  AppOutlinedButton(
                    text: 'order_success.continue_shopping'.tr(),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.dashBoard,
                          (_) => false,
                    ),
                    active: true,
                    horizontalPadding: 0,
                    verticalPadding: 0,
                  ),

                  SizedBox(height: v.s16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── T8.7: Confetti Painter ────────────────────────────────────────────────────
// Draws animated confetti pieces falling down the screen.
// Uses a seeded Random for deterministic positions per frame.

class _ConfettiPiece {
  final double x;       // 0–1 horizontal start position
  final double speed;   // fall speed multiplier
  final double size;
  final Color color;
  final double rotation;
  final double wave;    // horizontal sway amplitude

  const _ConfettiPiece({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.wave,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  static final List<_ConfettiPiece> _pieces = _generate();

  static List<_ConfettiPiece> _generate() {
    final rng = Random(42);
    const colors = [
      Color(0xFF6366F1), // indigo
      Color(0xFFF59E0B), // amber
      Color(0xFF10B981), // emerald
      Color(0xFFEF4444), // red
      Color(0xFF3B82F6), // blue
      Color(0xFFA855F7), // purple
      Color(0xFFEC4899), // pink
    ];
    return List.generate(60, (_) => _ConfettiPiece(
      x:        rng.nextDouble(),
      speed:    0.4 + rng.nextDouble() * 0.6,
      size:     5.0 + rng.nextDouble() * 7.0,
      color:    colors[rng.nextInt(colors.length)],
      rotation: rng.nextDouble() * pi * 2,
      wave:     rng.nextDouble() * 40 - 20,
    ));
  }

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Fade out in last 30% of animation
    final opacity = progress > 0.7 ? (1.0 - (progress - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;

    for (final p in _pieces) {
      final t = ((progress * p.speed + p.x) % 1.0);
      final y = t * (size.height + 40) - 20;
      final x = p.x * size.width + sin(t * pi * 4 + p.x * 10) * p.wave;

      paint.color = p.color.withValues(alpha: opacity * 0.85);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 4 * p.speed);

      // Draw alternating shapes: rectangle or circle
      if (p.x < 0.5) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isHighlighted;

  const _OrderDetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Selectable(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: ColorsManager.defaultTextSecondary),
          ),
          if (valueWidget != null) valueWidget! else if (value != null)
          Text(
            value!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight:
              isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultText,
            ),
          ),
        ],
      ),
    );
  }
}