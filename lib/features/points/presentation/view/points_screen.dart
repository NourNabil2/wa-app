// lib/features/points/presentation/view/points_screen.dart

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/core/widgets/web_breadcrumb.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/features/points/domain/entities/points_entity.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../cubit/points_cubit.dart';
import '../cubit/points_state.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';

class PointsScreen extends StatefulWidget {
  final bool isTab;
  const PointsScreen({super.key, this.isTab = false});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.zero),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<PointsCubit>()),
              BlocProvider(create: (_) => di.sl<WalletCubit>()),
            ],
            child: const PointsScreen(),
          ),
        ),
      ),
    );
  }

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PointsCubit>().loadPoints();
    context.read<WalletCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Force rebuild on language change
    final isWeb = isWebLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F6FA);

    if (!isWeb) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.maybePop(context),
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        body: BlocBuilder<PointsCubit, PointsState>(
          builder: (ctx, state) {
            final summary = state is PointsLoaded ? state.summary : null;
            if (state is PointsLoading || summary == null) {
              return const PointsHeaderSkeleton();
            }
            return _PointsLayoutContent(summary: summary, isWeb: false);
          },
        ),
      );
    }

    if (widget.isTab) {
      return BlocBuilder<PointsCubit, PointsState>(
        builder: (ctx, state) {
          final summary = state is PointsLoaded ? state.summary : null;
          if (state is PointsLoading || summary == null) {
            return const SizedBox(height: 400, child: PointsHeaderSkeleton());
          }
          return _PointsLayoutContent(summary: summary, isWeb: true);
        },
      );
    }

    return BlocBuilder<PointsCubit, PointsState>(
      builder: (ctx, state) {
        final summary = state is PointsLoaded ? state.summary : null;
        final bodyContent = (state is PointsLoading || summary == null)
            ? const SizedBox(height: 400, child: PointsHeaderSkeleton())
            : _PointsLayoutContent(summary: summary, isWeb: true);

        return SimpleWebShell(
          showFooter: summary != null,
          content: bodyContent,
        );
      },
    );
  }
}

class _PointsLayoutContent extends StatelessWidget {
  final PointsSummaryEntity summary;
  final bool isWeb;

  const _PointsLayoutContent({required this.summary, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = context.watch<UserCubit>().displayName;
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWeb) ...[
          WebBreadcrumb(
            isDark: isDark,
            labels: ['dashboard.home'.tr(), 'footer.account'.tr(), 'loyalty.title'.tr()],
            onTaps: [
              () => AppNavigator.pushNamed(context, Routes.dashBoard),
              () => AppNavigator.pushNamed(context, Routes.profile),
              null,
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('loyalty.title'.tr(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 24),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('points.hello'.tr(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('points.level_name'.tr(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    Text(summary.levelName(context.locale.languageCode == 'ar'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TierHeaderCard(summary: summary),
              if (summary.tier?.enabled == true) ...[
                const SizedBox(height: 24),
                _TierBenefitsCard(tier: summary.tier!, isDark: isDark),
              ],
              const SizedBox(height: 24),
              _WhiteStatsRow(summary: summary, isDark: isDark),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HistorySection(history: summary.history, isDark: isDark),
                    const SizedBox(height: 32),
                    _FAQAccordion(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ],
    );

    if (isWeb) {
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: content,
            ),
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }
  }
}

class _TierHeaderCard extends StatefulWidget {
  final PointsSummaryEntity summary;

  const _TierHeaderCard({required this.summary});

  @override
  State<_TierHeaderCard> createState() => _TierHeaderCardState();
}

class _TierHeaderCardState extends State<_TierHeaderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tier colours.
  ///
  /// The balance card keeps ONE fixed gold treatment for every tier.
  ///
  /// This is a deliberate product decision, not an oversight: the card is the
  /// brand moment on this screen, and the client wants it identical for every
  /// customer.
  ///
  /// Fixing the BACKGROUND is not the same as making the card tier-blind — the
  /// tier is named on the card by the badge below, tinted with its own colour,
  /// and coloured again on the dots in the tiers ladder further down.
  ///
  /// Do not reintroduce per-tier theming here without checking that decision.
  (List<Color>, Color) _getTierTheme() {
    final tierName = widget.summary.tier?.current?.nameAr ?? widget.summary.tier?.current?.name ?? '';
    
    if (tierName.contains('رياضي') || tierName.toLowerCase().contains('athlete')) {
      return (const [Color(0xFFC07C46), Color(0xFFE8B68F)], Colors.black87);
    } else if (tierName.contains('محترف') || tierName.toLowerCase().contains('pro')) {
      return (const [Color(0xFF9E9E9E), Color(0xFFE0E0E0)], Colors.black87);
    } else if (tierName.contains('اسطورة') || tierName.contains('أسطورة') || tierName.toLowerCase().contains('legend')) {
      return (const [Color(0xFF5E35B1), Color(0xFF9575CD)], Colors.white);
    }
    return (const [Color(0xFFEBC14F), Color(0xFFFDE68A)], Colors.black87);
  }

  Widget? _tierBadge(BuildContext context, Color textColor) {
    final tier = widget.summary.tier?.current;
    if (tier == null) return null;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? tier.nameAr : tier.name;
    if (name.trim().isEmpty) return null;

    final bonus = tier.bonusPointsPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        if (bonus > 0) ...[
          const SizedBox(height: 2),
          Text(
            '+${bonus % 1 == 0 ? bonus.toStringAsFixed(0) : bonus.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }

  /// Still used by the tiers ladder below, which DOES colour each row's dot
  /// with that tier's own colour — only the balance card is fixed to gold.
  static Color? _parseHex(String value) {
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }


  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final theme = _getTierTheme();
    final bgColors = theme.$1;
    final textColor = theme.$2;
    // Hoisted so the null-check promotes for the spread below.
    final tierBadge = _tierBadge(context, textColor);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: bgColors, 
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColors.last.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WavyBackgroundPainter(_controller.value),
                  );
                },
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Selectable(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('points.current_balance'.tr(), style: TextStyle(fontSize: 14, color: textColor == Colors.black87 ? Colors.black87 : Colors.white70, fontWeight: FontWeight.w600)),
                          Text('${summary.currentPoints}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: textColor == Colors.black87 ? Colors.black : Colors.white, height: 1.1)),
                          Text(
                            'loyalty.worthSar'.tr(namedArgs: {'amount': summary.pointsValueSar.toStringAsFixed(2)}),
                            style: TextStyle(fontSize: 14, color: textColor == Colors.black87 ? Colors.black87 : Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (tierBadge != null) ...[
                            tierBadge,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: textColor.withValues(alpha: 0.1)),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LevelProgressBar(summary: summary, textColor: textColor),
                    const SizedBox(height: 24),
                    _TextStatsRow(summary: summary, isDark: textColor == Colors.white),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? summary.memberSinceLabelAr : summary.memberSinceLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WavyBackgroundPainter extends CustomPainter {
  final double progress;
  
  _WavyBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      
      final phase = progress * 2 * math.pi;
      
      final xOffsetControl = math.cos(phase + i) * (size.width * 0.15);
      final yOffsetControl = math.sin(phase + i) * (size.height * 0.15);
      final yOffsetStart = math.sin(phase + i + math.pi) * (size.height * 0.05);
      final yOffsetEnd = math.sin(phase + i) * (size.height * 0.08);
      
      path.moveTo(0, size.height * (0.2 + i * 0.15) + yOffsetStart);
      path.quadraticBezierTo(
        size.width * 0.5 + xOffsetControl, 
        size.height * (i * 0.1) + yOffsetControl, 
        size.width, 
        size.height * (0.5 + i * 0.1) + yOffsetEnd
      );
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyBackgroundPainter oldDelegate) => oldDelegate.progress != progress;
}

class _LevelProgressBar extends StatelessWidget {
  final PointsSummaryEntity summary;
  final Color textColor;

  const _LevelProgressBar({required this.summary, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('points.progress_to_next_level'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textColor)),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: summary.progressPercent,
              child: Shimmer.fromColors(
                baseColor: const Color(0xFF2ECA8B),
                highlightColor: const Color(0xFF6DE8B4),
                direction: Directionality.of(context) == TextDirection.rtl ? ShimmerDirection.rtl : ShimmerDirection.ltr,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WhiteStatsRow extends StatelessWidget {
  final PointsSummaryEntity summary;
  final bool isDark;

  const _WhiteStatsRow({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Selectable(
      child: Row(
        children: [
          Expanded(
            child: _buildWhiteCard(
              context,
              title: 'points.total_purchases'.tr(),
              value: summary.totalSpent.toStringAsFixed(2),
              iconAsset: 'assets/icons/wallet-icon.svg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWhiteCard(
              context,
              title: 'points.saved_with_points'.tr(),
              value: summary.totalSavedByPoints.toStringAsFixed(2),
              iconAsset: 'assets/icons/discount-icon.svg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard(BuildContext context, {required String title, required String value, required String iconAsset}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(iconAsset, width: 16, height: 16, colorFilter: ColorFilter.mode(isDark ? Colors.white70 : Colors.black87, BlendMode.srcIn)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24),
            child: SarText(
              price: value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextStatsRow extends StatelessWidget {
  final PointsSummaryEntity summary;
  final bool isDark;

  const _TextStatsRow({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : Colors.black;
    return Selectable(
      child: Row(
        children: [
          _buildTextStat('${summary.totalOrders}', 'points.total_orders_stats'.tr(), color),
          _buildDivider(),
          _buildTextStat('${summary.totalPointsEarned}', 'points.total_earned_stats'.tr(), color),
          _buildDivider(),
          _buildTextStat('${summary.totalPointsSpent}', 'points.total_spent_stats'.tr(), color),
        ],
      ),
    );
  }

  Widget _buildTextStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final bool isDark;

  const _WalletSummaryCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (ctx, state) {
        final summary = state is WalletLoaded ? state.summary : null;
        final total = summary?.balance ?? 0.0;
        final realMoney = summary?.realMoneyBalance ?? 0.0;
        final cashback = summary?.cashbackBalance ?? 0.0;
        final expiringSoon = summary?.expiringSoon;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Selectable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/wallet-icon.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                  const SizedBox(width: 8),
                  Text('wallet.total_balance'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  const Spacer(),
                  SarText(
                    price: total.toStringAsFixed(2),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.withValues(alpha: 0.3), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/wallet-icon.svg', width: 13, height: 13, colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
                            const SizedBox(width: 6),
                            Text('wallet.real_money'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SarText(
                          price: realMoney.toStringAsFixed(2),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text('wallet.never_expires'.tr(), style: TextStyle(fontSize: 11, color: subColor)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/cash-back-icon.svg', width: 11, height: 15, colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
                            const SizedBox(width: 6),
                            Text('wallet.cashback_money'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SarText(
                          price: cashback.toStringAsFixed(2),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        if (expiringSoon != null)
                          Text(
                            'wallet.expiring_soon_short'.tr(namedArgs: {
                              'amount': expiringSoon.amount.toStringAsFixed(2),
                              'date': expiringSoon.expiresAt != null
                                  ? '${expiringSoon.expiresAt!.day}/${expiringSoon.expiresAt!.month}'
                                  : '',
                            }),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                          )
                        else
                          Text('wallet.expiring_within_30'.tr(), style: TextStyle(fontSize: 11, color: subColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _WalletHistorySection extends StatelessWidget {
  final bool isDark;

  const _WalletHistorySection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final greenColor = const Color(0xFF2ECA8B);
    final locale = Localizations.localeOf(context).languageCode;

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final summary = state is WalletLoaded ? state.summary : null;
        final history = summary?.history ?? [];

        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 20),
                const SizedBox(width: 8),
                Text('wallet.history_title'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'wallet.no_history'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6)),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('wallet.history_details'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
                    Expanded(flex: 2, child: Text('wallet.history_date'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
                    Expanded(flex: 2, child: Text('wallet.history_amount'.tr(), textAlign: TextAlign.left, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(history.length, (i) {
                    final item = history[i];
                    final desc = locale == 'ar' ? item.descriptionAr : item.description;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Selectable(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                desc.isNotEmpty ? desc : item.source,
                                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.date.day}/${item.date.month}/${item.date.year}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: SarText(
                                price: '${item.isCredit ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: item.isCredit ? greenColor : textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              BlocBuilder<WalletCubit, WalletState>(
                builder: (context, state) {
                  if (state is WalletLoaded) {
                    if (state.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: PointsHeaderSkeleton(),
                      );
                    }
                    if (!state.hasReachedMax && history.length >= 10) {
                      return InkWell(
                        onTap: () => context.read<WalletCubit>().loadMoreHistory(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'wallet.load_more'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ColorsManager.primary2Color,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<PointsHistoryEntity> history;
  final bool isDark;

  const _HistorySection({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final greenColor = const Color(0xFF2ECA8B);

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, size: 20),
            const SizedBox(width: 8),
            Text('points.history_title'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('points.history_details'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
              Expanded(flex: 2, child: Text('points.history_date'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
              Expanded(flex: 2, child: Text('points.history_point_header'.tr(), textAlign: TextAlign.left, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: greenColor))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(history.length, (i) {
              final item = history[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Selectable(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.title,
                          style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.date.day}/${item.date.month}/${item.date.year}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.isEarned ? '+' : '-'}${item.points}',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        
        BlocBuilder<PointsCubit, PointsState>(
          builder: (context, state) {
            if (state is PointsLoaded) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: PointsHeaderSkeleton(),
                );
              }
              if (!state.hasReachedMax && history.length >= 10) { 
                return InkWell(
                  onTap: () => context.read<PointsCubit>().loadMoreHistory(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'points.load_more'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorsManager.primary2Color,
                      ),
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _FAQAccordion extends StatelessWidget {
  final bool isDark;
  const _FAQAccordion({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpansionTile(context, 'points.faq_what_is'.tr(), 'points.faq_what_is_ans'.tr()),
        _buildExpansionTile(context, 'points.faq_how_to_use'.tr(), 'points.faq_how_to_use_ans'.tr()),
        _buildExpansionTile(context, 'points.faq_validity'.tr(), 'points.faq_validity_ans'.tr()),
      ],
    );
  }

  Widget _buildExpansionTile(BuildContext context, String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              content, 
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Current-tier benefits plus the full ladder.
///
/// The ladder is what makes the programme legible: without it a customer sees a
/// tier name and no reason to care. Every number here is admin-configured, so
/// nothing is hardcoded — a store that renames its tiers or adds a fifth one
/// gets a correct screen with no app release.
class _TierBenefitsCard extends StatelessWidget {
  final TierSummaryEntity tier;
  final bool isDark;

  const _TierBenefitsCard({required this.tier, required this.isDark});

  static String _pct(double value) {
    final rounded = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    return rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final current = tier.current;
    final benefits = current?.displayBenefits(isArabic) ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tier points — deliberately labelled apart from the spendable
          // balance shown above, because redeeming points never lowers a tier.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'points.tier_points_label'.tr(),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
              ),
              Text(
                '${tier.tierPoints}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : ColorsManager.defaultText,
                ),
              ),
            ],
          ),
          if (tier.basis == 'rolling') ...[
            const SizedBox(height: 2),
            Text(
              'points.earned_in_window'.tr(args: ['${tier.windowMonths}']),
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],

          // ── Progress to the next tier ────────────────────────────────────
          if (tier.next != null) ...[
            const SizedBox(height: 14),
            Text(
              'points.points_to_next'.tr(args: [
                '${tier.next!.pointsNeeded}',
                tier.next!.displayName(isArabic),
              ]),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : ColorsManager.defaultText,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'points.top_tier'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
            ),
          ],

          // ── Current benefits ─────────────────────────────────────────────
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'points.benefits_title'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : ColorsManager.defaultText,
              ),
            ),
            const SizedBox(height: 10),
            ...benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── The whole ladder ─────────────────────────────────────────────
          if (tier.allTiers.length > 1) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'points.all_tiers_title'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : ColorsManager.defaultText,
              ),
            ),
            const SizedBox(height: 12),
            ...tier.allTiers.map((t) {
              final isCurrent = t.slug == current?.slug;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF16C79A).withValues(alpha: 0.08)
                      : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(10),
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF16C79A).withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _TierHeaderCardState._parseHex(t.color ?? '') ?? Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.displayName(isArabic),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? Colors.white : ColorsManager.defaultText,
                            ),
                          ),
                          Text(
                            t.maxPoints == null
                                ? '${t.minPoints}+'
                                : '${t.minPoints} – ${t.maxPoints}',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (t.hasBonusPoints)
                          Text(
                            'points.bonus_points_badge'.tr(args: [_pct(t.bonusPointsPercent)]),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        if (t.hasExtraDiscount)
                          Text(
                            'points.extra_discount_badge'.tr(args: [_pct(t.extraDiscountPercent)]),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
