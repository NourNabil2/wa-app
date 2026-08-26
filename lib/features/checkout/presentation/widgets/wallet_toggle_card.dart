import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../../presentation/cubit/checkout_cubit.dart';
import '../../presentation/cubit/checkout_state.dart';

/// S7: Checkout wallet balance toggle card.
///
/// - Shows available wallet balance pulled from checkout summary.
/// - Toggle applies / removes wallet amount.
/// - Disabled when BNPL (Tabby/Tamara) or COD is selected — with a
///   visible lock icon + helper text.
/// - Payment picker hides Tabby/Tamara/COD when walletAmount > 0 (see checkout_screen.dart).
class WalletToggleCard extends StatelessWidget {
  /// The user's current wallet balance (SAR), from the /checkout/prepare response.
  final double walletBalance;

  /// Maximum usable amount at this checkout (clamped to payable total).
  final double maxUsable;

  const WalletToggleCard({
    super.key,
    required this.walletBalance,
    required this.maxUsable,
  });

  @override
  Widget build(BuildContext context) {
    if (walletBalance <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (p, n) {
        if (p is CheckoutLoaded && n is CheckoutLoaded) {
          return p.walletAmount != n.walletAmount ||
              p.selectedPayment != n.selectedPayment;
        }
        return false;
      },
      builder: (context, state) {
        if (state is! CheckoutLoaded) return const SizedBox.shrink();

        final cubit = context.read<CheckoutCubit>();
        final method = state.selectedPayment;
        final isBnpl = method?.provider == PaymentProvider.tabby ||
            method?.provider == PaymentProvider.tamara;
        final isCod = method?.provider == PaymentProvider.cod;
        final isBlocked = isBnpl || isCod;

        final isOn = !isBlocked && state.walletAmount > 0;
        final usable = isBlocked ? 0.0 : maxUsable;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: ColorsManager.primary2Color,
                    size: 26,
                  ),
                ),
                SizedBox(width: h.s10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wallet.checkout_use'.tr(),
                          style: TextStyle(
                            fontSize: t.s14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ColorsManager.defaultText,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'wallet.balance_available'.tr().split('{amount}').first,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w300,
                                  fontSize: t.s12,
                                  color: ColorsManager.primary2Color,
                                ),
                              ),
                              TextSpan(
                                text: '${walletBalance.toStringAsFixed(2)}${'wallet.balance_available'.tr().split('{amount}').length > 1 ? 'wallet.balance_available'.tr().split('{amount}').last : ''}',
                                style: TextStyle(
                                  fontSize: t.s12,
                                  color: ColorsManager.primary2Color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBlocked)
                    Icon(Icons.lock_outline_rounded,
                        size: t.s18, color: Colors.grey)
                  else
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: isOn,
                        onChanged: (val) {
                          if (val) {
                            cubit.setWalletAmount(usable);
                          } else {
                            cubit.clearWalletAmount();
                          }
                        },
                        activeColor: ColorsManager.primary2Color,
                        activeTrackColor: ColorsManager.primary2Color.withValues(alpha: 0.35),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
              if (isBlocked) ...[
                SizedBox(height: v.s8),
                Text(
                  isBnpl
                      ? 'wallet.blocked_bnpl'.tr()
                      : 'wallet.blocked_cod'.tr(),
                  style: TextStyle(
                    fontSize: t.s10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (isOn && !isBlocked) ...[
                SizedBox(height: v.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'wallet.applied'.tr(namedArgs: {
                        'amount': state.walletAmount.toStringAsFixed(2),
                      }),
                      style: TextStyle(
                        fontSize: t.s12,
                        color: ColorsManager.primary2Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'wallet.remaining_gateway'.tr(namedArgs: {
                        'amount':
                            (maxUsable - state.walletAmount).clamp(0.0, double.infinity).toStringAsFixed(2),
                      }),
                      style: TextStyle(
                        fontSize: t.s12,
                        color: ColorsManager.defaultTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
