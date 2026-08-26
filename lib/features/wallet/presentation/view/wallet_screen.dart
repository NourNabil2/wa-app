import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/wallet_entity.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/widgets/web_breadcrumb.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';

class WalletScreen extends StatefulWidget {
  final bool isTab;
  const WalletScreen({super.key, this.isTab = false});

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
          height: MediaQuery.sizeOf(context).height * 0.92,
          child: BlocProvider(
            create: (_) => di.sl<WalletCubit>()..loadWallet(),
            child: const WalletScreen(),
          ),
        ),
      ),
    );
  }

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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
          title: Text(
            'wallet.title'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<WalletCubit, WalletState>(
          builder: (ctx, state) {
            if (state is WalletLoading || state is WalletInitial) {
              return const PointsHeaderSkeleton();
            }
            if (state is WalletError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: ColorsManager.errorFill),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ctx.read<WalletCubit>().loadWallet(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is WalletLoaded) {
              return _WalletContent(summary: state.summary, isDark: isDark, isWeb: false);
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    if (widget.isTab) {
      return BlocBuilder<WalletCubit, WalletState>(
        builder: (ctx, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const SizedBox(height: 400, child: PointsHeaderSkeleton());
          }
          if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: ColorsManager.errorFill),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ctx.read<WalletCubit>().loadWallet(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is WalletLoaded) {
            return _WalletContent(summary: state.summary, isDark: isDark, isWeb: true);
          }
          return const SizedBox.shrink();
        },
      );
    }

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (ctx, state) {
        final summary = state is WalletLoaded ? state.summary : null;
        Widget bodyContent;
        
        if (state is WalletLoading || state is WalletInitial) {
          bodyContent = const SizedBox(height: 400, child: PointsHeaderSkeleton());
        } else if (state is WalletError) {
          bodyContent = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: ColorsManager.errorFill),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ctx.read<WalletCubit>().loadWallet(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is WalletLoaded) {
          bodyContent = _WalletContent(summary: summary!, isDark: isDark, isWeb: true);
        } else {
          bodyContent = const SizedBox.shrink();
        }

        return SimpleWebShell(
          showFooter: summary != null,
          content: bodyContent,
        );
      },
    );
  }
}

class _WalletContent extends StatelessWidget {
  final WalletSummaryEntity summary;
  final bool isDark;
  final bool isWeb;
  const _WalletContent({required this.summary, required this.isDark, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWeb) ...[
          WebBreadcrumb(
            isDark: isDark,
            labels: ['dashboard.home'.tr(), 'footer.account'.tr(), 'wallet.title'.tr()],
            onTaps: [
              () => AppNavigator.pushNamed(context, Routes.dashBoard),
              () => AppNavigator.pushNamed(context, Routes.profile),
              null,
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'wallet.title'.tr(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2B2D42),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _WalletHeaderCard(summary: summary, isDark: isDark),
        SizedBox(height: v.s16),
        if (summary.expiringSoon != null) ...[
          _ExpiringBanner(expiringSoon: summary.expiringSoon!, isDark: isDark),
          SizedBox(height: v.s16),
        ],
        _WalletStatsRow(stats: summary.stats, isDark: isDark),
        SizedBox(height: v.s24),
        _WalletHowItWorks(isDark: isDark),
        SizedBox(height: v.s24),
        _WalletHistorySection(history: summary.history, isDark: isDark),
        SizedBox(height: v.s32),
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
      return RefreshIndicator(
        onRefresh: () => context.read<WalletCubit>().loadWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s16),
          child: content,
        ),
      );
    }
  }
}

// ── Header balance card ───────────────────────────────────────────────────────
class _WalletHeaderCard extends StatelessWidget {
  final WalletSummaryEntity summary;
  final bool isDark;
  const _WalletHeaderCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = TextSizeApp.instance;

    return Selectable(
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6B3C), Color(0xFF2ECA8B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECA8B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('wallet.balance_label'.tr(),
                  style: TextStyle(
                    fontSize: t.s14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SAR ${summary.balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: t.s32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceSplitTile(
                  icon: Icons.savings_rounded,
                  label: 'wallet.real_money'.tr(),
                  amount: summary.realMoneyBalance,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
              ),
              Expanded(
                child: _BalanceSplitTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'wallet.cashback_money'.tr(),
                  amount: summary.cashbackBalance,
                  sublabel: summary.expiringSoon != null
                      ? 'wallet.expiring_soon_short'.tr(namedArgs: {
                          'amount': summary.expiringSoon!.amount.toStringAsFixed(2),
                          'date': summary.expiringSoon!.expiresAt != null
                              ? '${summary.expiringSoon!.expiresAt!.day}/${summary.expiringSoon!.expiresAt!.month}'
                              : '',
                        })
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _BalanceSplitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final String? sublabel;
  const _BalanceSplitTile({
    required this.icon,
    required this.label,
    required this.amount,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'SAR ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sublabel!,
            style: TextStyle(fontSize: 10, color: Colors.orange.shade100, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ── Expiring soon banner ──────────────────────────────────────────────────────
class _ExpiringBanner extends StatelessWidget {
  final WalletExpiringSoon expiringSoon;
  final bool isDark;
  const _ExpiringBanner({required this.expiringSoon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Selectable(
              child: Text(
                'wallet.expiring_soon'.tr(namedArgs: {
                  'amount': expiringSoon.amount.toStringAsFixed(2),
                  'date': expiringSoon.expiresAt != null
                      ? '${expiringSoon.expiresAt!.day}/${expiringSoon.expiresAt!.month}/${expiringSoon.expiresAt!.year}'
                      : '',
                }),
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _WalletStatsRow extends StatelessWidget {
  final WalletStats stats;
  final bool isDark;
  const _WalletStatsRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Selectable(
        child: Row(
          children: [
            _Stat('SAR ${stats.totalCashback.toStringAsFixed(0)}',
                'wallet.stat_cashback'.tr(), color),
            _Divider(),
            _Stat('SAR ${stats.totalSpent.toStringAsFixed(0)}',
                'wallet.stat_spent'.tr(), color),
            _Divider(),
            _Stat('SAR ${stats.totalRefunded.toStringAsFixed(0)}',
                'wallet.stat_refunded'.tr(), color),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.25));
}

// ── How it works ──────────────────────────────────────────────────────────────
class _WalletHowItWorks extends StatelessWidget {
  final bool isDark;
  const _WalletHowItWorks({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.primary2Color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, size: 20, color: ColorsManager.primary2Color),
              ),
              const SizedBox(width: 12),
              Text('wallet.how_it_works'.tr(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 20),
          _HowStep('💰', 'wallet.how_earn'.tr(), isDark),
          _HowStep('🛒', 'wallet.how_use'.tr(), isDark),
          _HowStep('⏱', 'wallet.how_expire'.tr(), isDark),
          _HowStep('🚫', 'wallet.how_restriction'.tr(), isDark),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String emoji;
  final String text;
  final bool isDark;
  const _HowStep(this.emoji, this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Selectable(
                child: Text(text,
                    maxLines: 5,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History section ───────────────────────────────────────────────────────────
class _WalletHistorySection extends StatelessWidget {
  final List<WalletHistoryEntity> history;
  final bool isDark;
  const _WalletHistorySection({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final textColor = isDark ? Colors.white : ColorsManager.defaultText;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18),
              const SizedBox(width: 8),
              Text('wallet.history_title'.tr(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ],
          ),
          SizedBox(height: v.s12),
          if (history.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: v.s16),
              child: Center(
                child: Text('wallet.no_history'.tr(),
                    style: const TextStyle(
                        fontSize: 14,
                        color: ColorsManager.defaultTextSecondary)),
              ),
            )
          else
            ...List.generate(history.length, (i) {
              final item = history[i];
              return Column(
                children: [
                  _WalletHistoryItem(item: item, isDark: isDark),
                  if (i < history.length - 1)
                    Divider(height: v.s16, color: ColorsManager.backgroundCard),
                ],
              );
            }),
          // Load more
          BlocBuilder<WalletCubit, WalletState>(
            builder: (ctx, state) {
              if (state is WalletLoaded) {
                if (state.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (!state.hasReachedMax && history.length >= 10) {
                  return InkWell(
                    onTap: () => ctx.read<WalletCubit>().loadMoreHistory(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}

class _WalletHistoryItem extends StatelessWidget {
  final WalletHistoryEntity item;
  final bool isDark;
  const _WalletHistoryItem({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = TextSizeApp.instance;
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    final isCredit = item.isCredit;
    final amountColor = isCredit ? ColorsManager.primary2Color : ColorsManager.errorFill;
    final bgColor = isCredit
        ? ColorsManager.primary2Color.withValues(alpha: 0.1)
        : ColorsManager.errorFill.withValues(alpha: 0.1);

    final dateStr = '${item.date.day}/${item.date.month}/${item.date.year}';
    final desc = item.description.isNotEmpty ? item.description : item.source;

    return Selectable(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child: Icon(
                isCredit ? Icons.add_rounded : Icons.remove_rounded,
                color: amountColor,
                size: t.s20,
              ),
            ),
          ),
          SizedBox(width: h.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        fontSize: t.s12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : ColorsManager.defaultText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: v.s3),
                Text(dateStr,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        fontSize: t.s12, color: ColorsManager.defaultTextSecondary)),
              ],
            ),
          ),
          SizedBox(width: h.s12),
          Text(
            '${isCredit ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: t.s16, fontWeight: FontWeight.bold, color: amountColor),
          ),
        ],
      ),
    );
  }
}
