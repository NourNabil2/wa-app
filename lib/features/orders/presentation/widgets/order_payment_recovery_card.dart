// lib/features/orders/presentation/widgets/order_payment_recovery_card.dart
//
// Shown on the order-details screen for orders stuck in `pending_payment` or
// `payment_unconfirmed` (an online/BNPL checkout that never completed). Offers:
//   • Retry Payment  → re-initiates the gateway session and reopens checkout
//   • Back to Cart    → cancels the unpaid order group and rebuilds the cart
//
// It owns a fresh CheckoutCubit (factory-param, like the checkout screen) so it
// can drive payment initiation independently of the orders feature.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../checkout/domain/entities/payment_method_entity.dart';
import '../../../checkout/presentation/cubit/checkout_cubit.dart';
import '../../../checkout/presentation/cubit/checkout_state.dart';
import '../../../checkout/presentation/view/external_payment_page.dart';
import '../../domain/entities/order_entity.dart';

class OrderPaymentRecoveryCard extends StatelessWidget {
  final OrderEntity order;

  const OrderPaymentRecoveryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Fresh CheckoutCubit — same factory-param pattern as the checkout screen.
    return BlocProvider<CheckoutCubit>(
      create: (_) => sl<CheckoutCubit>(
        param1: context.read<DeliveryLocationCubit>(),
      ),
      child: _RecoveryBody(order: order),
    );
  }
}

class _RecoveryBody extends StatelessWidget {
  final OrderEntity order;

  const _RecoveryBody({required this.order});

  void _openPaymentPage(
      BuildContext context, String paymentUrl, String orderNumber, PaymentProvider provider) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<CheckoutCubit>(),
        child: ExternalPaymentPage(
          paymentUrl: paymentUrl,
          orderNumber: orderNumber,
          provider: provider,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is PaymentInitiated) {
          _openPaymentPage(
              context, state.paymentUrl, state.orderNumber, state.provider);
        } else if (state is PaymentInitiationFailed) {
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        } else if (state is PaymentConfirmed) {
          // Payment completed via the reopened session — refresh order details.
          Navigator.of(context).popUntil((r) => r.isFirst);
          Navigator.pushNamed(context, Routes.orders);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorsManager.warningSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorsManager.warningText.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: ColorsManager.warningText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'orders.payment.awaiting_title'.tr(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorsManager.warningText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'orders.payment.awaiting_subtitle'.tr(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: ColorsManager.warningText, height: 1.4),
            ),
            const SizedBox(height: 16),
            BlocBuilder<CheckoutCubit, CheckoutState>(
              builder: (context, state) {
                final busy = state is InitiatingPayment;
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: busy
                            ? null
                            : () => context.read<CheckoutCubit>().retryPayment(
                                  order.id,
                                  order.orderNumber,
                                  PaymentProvider.unknown,
                                ),
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('orders.payment.retry'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : () => _backToCart(context),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: Text('orders.payment.back_to_cart'.tr()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ColorsManager.primaryColor),
                          foregroundColor: ColorsManager.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backToCart(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final ok = await cubit.backToCart(order.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.cart, (r) => r.isFirst);
    } else {
      CustomSnackBar.show(
        context,
        message: 'orders.payment.back_to_cart_failed'.tr(),
        type: SnackBarType.error,
      );
    }
  }
}
