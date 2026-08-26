import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:fastway/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:fastway/features/checkout/presentation/view/checkout_screen.dart';
import 'package:fastway/features/user_data/user_repo.dart';

/// Entry point for admin payment links: `/pay/{token}`.
///
/// Flow (mirrors the FCM discount-push idea — seed then open the NORMAL checkout):
///  1. Require login (owner-only endpoint). If logged out → prompt to log in.
///  2. POST /pay/{token}/load-to-cart → seeds the cart from the order (items +
///     coupon) and returns a prefill (wallet / shipping / payment).
///  3. Replace with the normal [CheckoutScreen], passing the prefill so wallet
///     and shipping/payment are auto-applied once. Items + coupon come from the
///     seeded cart, so no checkout-engine change is needed.
class PayLinkGate extends StatefulWidget {
  final String token;
  const PayLinkGate({super.key, required this.token});

  @override
  State<PayLinkGate> createState() => _PayLinkGateState();
}

class _PayLinkGateState extends State<PayLinkGate> {
  bool _loading = true;
  String? _error;
  bool _needLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!UserRepository().isLoggedIn) {
      setState(() {
        _loading = false;
        _needLogin = true;
      });
      return;
    }

    final result = await sl<CheckoutRepository>().loadPayLinkToCart(widget.token);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (prefill) {
        // Refresh the cart so checkout reads the freshly-seeded items/coupon.
        context.read<CartCubit>().loadCart();

        final wallet = (prefill['wallet_to_apply'] as num?)?.toDouble() ?? 0.0;
        final shippingId = (prefill['shipping_method_id'] as num?)?.toInt();
        final paymentId = (prefill['payment_method_id'] as num?)?.toInt();

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (ctx) => MultiBlocProvider(
            providers: [
              BlocProvider<CheckoutCubit>(
                create: (c) => sl<CheckoutCubit>(
                  param1: c.read<DeliveryLocationCubit>(),
                ),
              ),
              BlocProvider.value(value: ctx.read<CartCubit>()),
            ],
            child: CheckoutScreen(
              prefillWalletAmount: wallet > 0 ? wallet : null,
              prefillShippingMethodId: shippingId,
              prefillPaymentMethodId: paymentId,
            ),
          ),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('checkout.title'.tr()),
        leading: const BackButton(),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _needLogin
                ? _loginPrompt(context)
                : _errorView(context),
      ),
    );
  }

  Widget _loginPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text('pay_link.login_required'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            // After logging in, the user returns to this URL (/pay/{token}) and
            // the gate re-runs — now authenticated.
            onPressed: () => Navigator.pushNamed(context, Routes.login),
            child: Text('auth.login'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text(_error ?? 'pay_link.expired'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, Routes.dashBoard, (r) => false),
            child: Text('common.back_to_home'.tr()),
          ),
        ],
      ),
    );
  }
}
