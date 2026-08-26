import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/features/checkout/domain/entities/checkout_entity.dart';
import 'package:fastway/features/checkout/presentation/widgets/city_dropdown.dart';
import 'package:fastway/features/user_data/auth_guard.dart';
import 'package:fastway/features/profile/presentation/view/addresses_screen.dart';
import 'package:fastway/features/profile/presentation/view/add_edit_address_screen.dart';
import 'package:fastway/features/profile/presentation/cubit/addresses_cubit.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../../../core/layout/simple_web_shell.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/sar_symbol.dart' show SarText;
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/saved_address_entity.dart';
import '../../domain/entities/shipping_method_entity.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../cubit/web_apple_pay.dart';
import '../../domain/entities/place_order_result.dart';
import '../widgets/checkout_section_card.dart';
import '../../presentation/widgets/order_summary_card.dart';
import '../../presentation/widgets/shipping_method_picker.dart';
import '../widgets/saved_address_tile.dart';
import '../widgets/selectable_option_tile.dart';
import '../widgets/points_redemption_card.dart';
import '../widgets/wallet_toggle_card.dart';
import 'external_payment_page.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../cart/presentation/widgets/coupon_section.dart';

/// Splits the backend's single "Telr" payment method into two tiles when Apple
/// Pay is actually available on this platform: a card-only "Telr" tile and a
/// separate "Apple Pay" tile — so a customer can tap Apple Pay directly instead
/// of it appearing as a second button hidden under Telr. Both tiles carry the
/// SAME backend `id` (Apple Pay is still charged via the Telr gateway), and are
/// told apart in the UI via `isApplePayTile` (see PaymentMethodEntity).
List<PaymentMethodEntity> _withApplePayTile(List<PaymentMethodEntity> methods) {
  final telrIndex = methods.indexWhere((m) => m.provider == PaymentProvider.telr);
  if (telrIndex == -1) return methods;

  final telr = methods[telrIndex];
  final merchantId = telr.appleMerchantId;
  final eligible = telr.applePayEnabled &&
      (merchantId?.isNotEmpty ?? false) &&
      ((!kIsWeb && Platform.isIOS) || (kIsWeb && webApplePayAvailable()));
  if (!eligible) return methods;

  final cardOnly = PaymentMethodEntity(
    id: telr.id,
    name: telr.name,
    provider: telr.provider,
    iconUrl: telr.iconUrl,
    isCod: telr.isCod,
  );
  final applePayTile = PaymentMethodEntity(
    id: telr.id,
    name: 'Apple Pay',
    provider: telr.provider,
    applePayEnabled: true,
    appleMerchantId: merchantId,
    isApplePayTile: true,
  );

  final result = List<PaymentMethodEntity>.from(methods);
  result[telrIndex] = cardOnly;
  result.insert(telrIndex + 1, applePayTile);
  return result;
}

class CheckoutScreen extends StatefulWidget {
  /// Optional prefill for the admin payment-link flow (`/pay/{token}`). When
  /// set, they are applied ONCE after the first successful load: the wallet
  /// amount is applied and the shipping/payment methods are pre-selected.
  /// Items + coupon come from the seeded cart, so they need no prefill.
  final double? prefillWalletAmount;
  final int? prefillShippingMethodId;
  final int? prefillPaymentMethodId;

  const CheckoutScreen({
    super.key,
    this.prefillWalletAmount,
    this.prefillShippingMethodId,
    this.prefillPaymentMethodId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  /// Caches the last successfully loaded checkout data.
  /// Used to keep the form visible during transient states like PlacingOrder,
  /// InitiatingPayment, PaymentInitiationFailed, PaymentFailed, etc.
  CheckoutLoaded? _lastLoadedState;

  /// One-shot guard so the pay-link prefill is applied exactly once.
  bool _prefillApplied = false;

  @override
  void initState() {
    super.initState();
    _loadInitialCheckout();
  }

  /// Apply the pay-link prefill (wallet + shipping/payment) once the checkout
  /// data is loaded. Mirrors CartScreen's one-shot `applyCouponCode` pattern.
  void _applyPayLinkPrefill(CheckoutLoaded state) {
    if (_prefillApplied) return;
    final hasPrefill = widget.prefillWalletAmount != null ||
        widget.prefillShippingMethodId != null ||
        widget.prefillPaymentMethodId != null;
    if (!hasPrefill) return;
    _prefillApplied = true;

    final cubit = context.read<CheckoutCubit>();

    if (widget.prefillShippingMethodId != null) {
      // 1. Match against the global flat shipping methods list (single-group).
      ShippingMethodEntity? matched;
      for (final m in state.shippingMethods) {
        if (int.tryParse(m.id) == widget.prefillShippingMethodId) {
          matched = m;
          cubit.selectShippingMethod(m);
          break;
        }
      }

      // 2. Also match + select within every group's available methods so the
      //    per-group shipping card shows the correct pre-selection.
      //    (Payment links always come from single-group orders so this loop
      //    typically runs once, but it's safe for multi-group carts too.)
      final groups = state.checkout.groups ?? [];
      for (final group in groups) {
        for (final m in group.availableShippingMethods ?? <ShippingMethodEntity>[]) {
          if (int.tryParse(m.id) == widget.prefillShippingMethodId) {
            cubit.selectGroupShippingMethod(group.id, m);
            matched ??= m;
            break;
          }
        }
      }
    }

    if (widget.prefillPaymentMethodId != null) {
      for (final m in state.paymentMethods) {
        if (int.tryParse(m.id) == widget.prefillPaymentMethodId) {
          cubit.selectPaymentMethod(m);
          break;
        }
      }
    }
    if ((widget.prefillWalletAmount ?? 0) > 0) {
      cubit.setWalletAmount(widget.prefillWalletAmount!);
    }
  }

  void _loadInitialCheckout() {
    context.read<CheckoutCubit>().loadCheckout();
  }

  /// Builds the success-screen argument from a confirmed online payment.
  /// Carries the real paid amount (group total) so the success screen and
  /// admin agree with what the customer paid.
  PlaceOrderResult _successResult(PaymentConfirmed state) => PlaceOrderResult(
        orderId:     '',
        orderNumber: state.orderNumber,
        status:      'processing',
        total:       state.total ?? 0,
        isCod:       false,
      );

  void _openExternalPaymentPage(
      String paymentUrl, String orderNumber, PaymentProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      constraints: const BoxConstraints(maxWidth: 800),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<CheckoutCubit>(),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false,
                body: ExternalPaymentPage(
                  paymentUrl: paymentUrl,
                  orderNumber: orderNumber,
                  provider: provider,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when a payment gateway deliberately declines the order (e.g. Tabby
  /// "amount too high"). The order is not created and the cart is preserved, so
  /// the customer just needs to pick another payment method.
  void _showPaymentRejectedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'checkout.payment.rejectedTitle'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('checkout.payment.chooseAnother'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPaymentErrorSheet({
    required BuildContext context,
    required String message,
    required String orderNumber,
    String? orderId,
    bool allowBackToCart = false,
  }) {
    final cubit = context.read<CheckoutCubit>();
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12)),
              ),
              const Icon(Icons.payment_outlined,
                  size: 52, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('checkout.payment.failedTitle'.tr(),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (orderId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      cubit.retryPayment(orderId, orderNumber);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('checkout.payment.retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (allowBackToCart) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await cubit.backToCart(orderId ?? orderNumber);
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, Routes.cart, (r) => r.isFirst);
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'checkout.payment.backToCartFailed'.tr(),
                          type: SnackBarType.error,
                        );
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text('checkout.payment.backToCart'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.orders);
                },
                child: Text('checkout.payment.viewOrder'.tr(),
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final body = BlocConsumer<CheckoutCubit, CheckoutState>(
        // Only re-trigger listener when shipping selection changes or when
        // order/payment state changes — not on every points or notes update.
        listenWhen: (prev, next) {
          if (next is! CheckoutLoaded) return true;
          if (prev is! CheckoutLoaded) return true;
          return prev.selectedShipping?.id != next.selectedShipping?.id;
        },
        listener: (context, state) {
          // ── Pay-link prefill (one-shot, after first load) ────────────────
          if (state is CheckoutLoaded) {
            _applyPayLinkPrefill(state);
          }

          // ── Errors ──────────────────────────────────────────────────────
          if (state is CheckoutError) {
            CustomSnackBar.show(
              context,
              message: state.failure.message,
              type: SnackBarType.error,
            );
          }
          if (state is OrderError) {
            CustomSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }

          // ── Gateway declined the order (e.g. Tabby amount too high) ─────
          // Prominent dialog — the customer must pick a different payment method.
          if (state is PaymentRejected) {
            _showPaymentRejectedDialog(context, state.message);
          }

          // ── COD: go straight to success ──────────────────────────────
          if (state is OrderPlaced && state.result.isCod) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.orderSuccess,
              arguments: state.result,
              (_) => false,
            );
          }

          // ── Online: payment initiation finished ───────────
          if (state is PaymentInitiated) {
            _openExternalPaymentPage(
                state.paymentUrl, state.orderNumber, state.provider);
          }

          // ── initiate-payment call failed → bottom sheet with retry ────
          if (state is PaymentInitiationFailed) {
            _showPaymentErrorSheet(
              context: context,
              message: state.message,
              orderId: state.orderId,
              orderNumber: state.orderNumber,
            );
          }

          // ── Telr authorised ───────────────────────────────────────────
          if (state is PaymentConfirmed) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.orderSuccess,
              arguments: _successResult(state),
              (_) => false,
            );
          }

          // ── Payment declined / cancelled / failed ─────────────────────
          // Offer retry (re-open the gateway on the same order) or back-to-cart
          // (cancel the unpaid order + restore the full cart).
          if (state is PaymentFailed) {
            _showPaymentErrorSheet(
              context: context,
              message: state.message,
              orderId: state.orderNumber, // backend accepts order_number too
              orderNumber: state.orderNumber,
              allowBackToCart: true,
            );
          }

          // ── TASK-C6: Cold-chain incompatibility warning ────────────────
          // Shows an alert dialog when the cart has cold-chain items but the
          // selected shipping method does not support cold chain.
          if (state is CheckoutLoaded) {
            final hasColdItems =
                state.checkout.groups?.any((g) => g.hasColdItems) ?? false;
            final shipping = state.selectedShipping;
            if (hasColdItems && shipping != null && !shipping.supportsColdChain) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Row(
                      children: [
                        const Icon(Icons.ac_unit, color: Colors.lightBlue),
                        const SizedBox(width: 8),
                        Text('checkout.coldChainWarningTitle'.tr()),
                      ],
                    ),
                    content: Text('checkout.coldChainWarningBody'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('common.ok'.tr()),
                      ),
                    ],
                  ),
                );
              });
            }
          }
        },
        builder: (context, state) {
          // Always cache the latest loaded state so the form stays visible
          // during transient states (placing order, initiating payment, etc.).
          if (state is CheckoutLoaded) {
            _lastLoadedState = state;
          }

          if (state is CheckoutLoading) {
            return const Center(child: CheckoutSkeleton());
          }

          if (state is CheckoutError) {
            final msg = state.failure.message.toLowerCase();
            final isEmptyCart = msg.contains('cart') && msg.contains('empty');

            if (isEmptyCart) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'checkout.cartEmpty'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'checkout.cartEmptyHint'.tr(),
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (_) => false),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text('checkout.goShopping'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () => context.read<CheckoutCubit>().loadCheckout(),
            );
          }

          // For any state that carries checkout data, show the form.
          // _lastLoadedState is used for transient states so the form never
          // disappears while orders are being placed / payment is initiating.
          final loaded =
              (state is CheckoutLoaded ? state : null) ?? _lastLoadedState;

          if (loaded != null) {
            if (isWebLayout(context)) {
              return _WebCheckoutBody(state: loaded);
            }
            return _MobileCheckoutBody(state: loaded);
          }

          return const Center(child: CheckoutSkeleton());
        },
      );

    if (isWeb) {
      return SimpleWebShell(content: body);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ColorsManager.backgroundSurface,
        appBar: CustomAppBar(
          title: 'checkout.title'.tr(),
          showBackIcon: true,
        ),
        body: body,
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final bool isVisible;
  final Widget child;

  const _AccordionSection({required this.isVisible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isVisible ? child : const SizedBox(width: double.infinity),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MobileCheckoutBody extends StatelessWidget {
  final CheckoutLoaded state;

  const _MobileCheckoutBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final cubit = context.read<CheckoutCubit>();
    final checkout = state.checkout;

    final hasAddress = state.selectedAddress != null;
    final bool hasShipping;
    if (state.checkout.groups != null && state.checkout.groups!.isNotEmpty) {
      hasShipping = state.groupShippingSelections.length == state.checkout.groups!.length;
    } else {
      hasShipping = state.selectedShipping != null;
    }
    // O4b: when the wallet fully covers the order, no payment method/gateway
    // is needed — the payment section is hidden entirely in that case.
    final walletCovers = state.isWalletFullyCovering;
    final hasPayment = walletCovers || state.selectedPayment != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s16),
            children: [
              // ── 1. Saved Addresses ─────────────────────
              CheckoutSectionCard(
                title: 'checkout.deliveryAddress'.tr(),
                titleIcon: Icons.location_on_outlined,
                child: AuthGuard.isGuest(context)
                    ? _GuestAddressForm(
                        cities: state.cities,
                        onSubmit: (addr) =>
                            context.read<CheckoutCubit>().setGuestAddress(addr),
                      )
                    : _SavedAddressesSection(
                        addresses: state.addresses,
                        selectedId: state.selectedAddress?.id,
                        onSelect: cubit.selectAddress,
                        onAddAddress: () async {
                          await AddEditAddressScreen.show(
                              context, context.read<AddressesCubit>());
                          if (context.mounted) cubit.loadCheckout();
                        },
                        onManageAddresses: () async {
                          await AddressesScreen.show(context);
                          if (context.mounted) cubit.loadCheckout();
                        },
                      ),
              ),

              SizedBox(height: v.s12),

              // ── 2. Shipping Methods ────────────────────
              _AccordionSection(
                isVisible: hasAddress,
                child: Padding(
                  padding: EdgeInsets.only(bottom: v.s12),
                  child: _CheckoutShippingSection(
                    state: state,
                    cubit: cubit,
                    isExpanded: true,
                  ),
                ),
              ),

              // ── 3. Payment Methods & Notes ─────────────
              // Hidden once the wallet alone covers the order — nothing to pick.
              if (!walletCovers) ...[
                _AccordionSection(
                  isVisible: hasAddress && hasShipping,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: v.s12),
                    child: CheckoutSectionCard(
                      title: 'checkout.paymentMethod'.tr(),
                      titleIcon: Icons.credit_card_outlined,
                      isExpanded: true,
                      child: _PaymentSection(
                        methods: _withApplePayTile(state.paymentMethods),
                        selectedPayment: state.selectedPayment,
                        selectedShipping: state.selectedShipping,
                        onSelect: cubit.selectPaymentMethod,
                      ),
                    ),
                  ),
                ),
              ],
              _AccordionSection(
                isVisible: hasAddress && hasShipping,
                child: Padding(
                  padding: EdgeInsets.only(bottom: v.s12),
                  child: BlocBuilder<CheckoutCubit, CheckoutState>(
                    builder: (context, couponState) {
                      return CouponSection(
                        appliedCoupon: (checkout.couponCode?.isNotEmpty ?? false)
                            ? checkout.couponCode
                            : null,
                        onApply: cubit.setCouponCode,
                        onRemove: cubit.removeCouponCode,
                        isLoading: false,
                      );
                    },
                  ),
                ),
              ),

              // ── 4. Points Redemption ───────────────────────
              // Points and wallet both just need address+shipping settled —
              // neither needs a payment method picked first (O4b: wallet can
              // BE the payment method when it fully covers the order).
              if (checkout.pointsInfo != null &&
                  (checkout.pointsInfo!['enabled'] as bool? ?? false) &&
                  ((checkout.pointsInfo!['available_points'] as num?)?.toInt() ?? 0) > 0) ...[
                _AccordionSection(
                  isVisible: hasAddress && hasShipping,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: v.s12),
                    child: PointsRedemptionCard(state: state, cubit: cubit),
                  ),
                ),
              ],

              // ── 4b. Wallet toggle ─────────────────────────
              if (hasAddress && hasShipping &&
                  (checkout.walletBalance ?? 0) > 0) ...[
                _AccordionSection(
                  isVisible: hasAddress && hasShipping,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: v.s12),
                    child: WalletToggleCard(
                      walletBalance: checkout.walletBalance ?? 0,
                      maxUsable: checkout.walletMaxUsable ?? checkout.walletBalance ?? 0,
                    ),
                  ),
                ),
              ],
              _AccordionSection(
                isVisible: hasAddress && hasShipping && hasPayment,
                child: BlocBuilder<CheckoutCubit, CheckoutState>(
                  buildWhen: (p, n) {
                    if (p is CheckoutLoaded && n is CheckoutLoaded) {
                      return p.selectedShipping?.id != n.selectedShipping?.id ||
                          p.groupShippingSelections != n.groupShippingSelections ||
                          p.pointsToUse != n.pointsToUse ||
                          p.walletAmount != n.walletAmount;
                    }
                    return true;
                  },
                  builder: (context, snapState) {
                    final snap = snapState is CheckoutLoaded ? snapState : state;
                    final shipping = snap.selectedShipping ?? snap.groupShippingSelections.values.firstOrNull;
                    final isFree = shipping?.isFree ?? false;
                    final originalShippingCost = shipping?.originalCost ?? snap.checkout.shippingCost;
                    final effectiveShipping = isFree ? 0.0 : (shipping?.cost ?? snap.checkout.shippingCost);
                    return OrderSummaryCard(
                      isExpanded: true,
                      itemsTotal: snap.checkout.subtotal,
                      // Server-authoritative once a shipping method is chosen: the
                      // delivery fee is VAT-inclusive and joins the taxable base, so
                      // the VAT line covers goods + delivery. Never recompute it here.
                      serverVatAmount: snap.quote?.vatAmount,
                      shippingExclVat: snap.quote?.shippingExclVat,
                      couponDiscount: (snap.checkout.couponDiscount ?? 0) > 0 ? snap.checkout.couponDiscount : null,
                      tierDiscount: (snap.checkout.tierDiscount ?? 0) > 0 ? snap.checkout.tierDiscount : null,
                      shippingCost: effectiveShipping,
                      originalShippingCost: originalShippingCost,
                      isFreeShipping: isFree,
                      // The server already priced this exact selection — use its total.
                      // The local sum stays only as a pre-quote fallback.
                      total: snap.quote?.total ??
                          (snap.checkout.subtotal -
                              (snap.checkout.discount) -
                              (snap.pointsToUse / (snap.checkout.pointsInfo?['rate'] as num? ?? 100)) +
                              effectiveShipping -
                              snap.walletAmount)
                          .clamp(0.0, double.infinity),
                      earnedPoints: snap.checkout.pointsToEarn,
                      pointsToUse: snap.pointsToUse,
                      walletApplied: snap.walletAmount,
                      pointsRate: (snap.checkout.pointsInfo?['rate'] as num? ?? 100).toInt(),
                      vatEnabled: AppSettingsService.instance.vatVisible,
                      vatAmount: AppSettingsService.instance.vatVisible
                          ? (snap.checkout.vatAmount ?? (snap.checkout.total * 15 / 115))
                          : 0,
                    );
                  },
                ),
                ),
              ],
            ),
              ),

              _AccordionSection(
                isVisible: hasAddress && hasShipping && hasPayment,
                child: Padding(
                  padding: EdgeInsets.only(top: v.s16),
                  child: BlocBuilder<CheckoutCubit, CheckoutState>(
                    builder: (context, state) {
                      final provider = state is CheckoutLoaded
                          ? (state.selectedPayment?.provider ?? PaymentProvider.telr)
                          : PaymentProvider.telr;
                      final appleEnabled = state is CheckoutLoaded
                          ? (state.selectedPayment?.applePayEnabled ?? false)
                          : false;
                      final merchantId = state is CheckoutLoaded
                          ? state.selectedPayment?.appleMerchantId
                          : null;
                      return _ConfirmButton(
                        isLoading: state is PlacingOrder || state is InitiatingPayment,
                        provider: provider,
                        applePayEnabled: appleEnabled,
                        appleMerchantId: merchantId,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: v.s24),
            ],
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WebCheckoutBody extends StatelessWidget {
  final CheckoutLoaded state;

  const _WebCheckoutBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CheckoutCubit>();
    final checkout = state.checkout;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasAddress = state.selectedAddress != null;
    final bool hasShipping;
    if (state.checkout.groups != null && state.checkout.groups!.isNotEmpty) {
      hasShipping = state.groupShippingSelections.length == state.checkout.groups!.length;
    } else {
      hasShipping = state.selectedShipping != null;
    }
    // O4b: when the wallet fully covers the order, no payment method/gateway
    // is needed — the payment section is hidden entirely in that case.
    final walletCovers = state.isWalletFullyCovering;
    final hasPayment = walletCovers || state.selectedPayment != null;

    // ── Reusable: left-column forms ─────────────────────────────────────────
    Widget leftForms = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckoutSectionCard(
          title: 'checkout.deliveryAddress'.tr(),
          titleIcon: Icons.location_on_outlined,
          child: AuthGuard.isGuest(context)
              ? _GuestAddressForm(
                  cities: state.cities,
                  onSubmit: (addr) => cubit.setGuestAddress(addr),
                )
              : _SavedAddressesSection(
                  addresses: state.addresses,
                  selectedId: state.selectedAddress?.id,
                  onSelect: cubit.selectAddress,
                  onAddAddress: () async {
                    await AddEditAddressScreen.show(
                        context, context.read<AddressesCubit>());
                    if (context.mounted) cubit.loadCheckout();
                  },
                  onManageAddresses: () async {
                    await AddressesScreen.show(context);
                    if (context.mounted) cubit.loadCheckout();
                  },
                ),
        ),
        _AccordionSection(
          isVisible: hasAddress,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _CheckoutShippingSection(state: state, cubit: cubit, isExpanded: true),
          ),
        ),
      ],
    );

    // ── Reusable: right-column summary card ─────────────────────────────────
    // Visible once address+shipping are set (not gated on payment) so the
    // wallet toggle inside it is reachable before a payment method is chosen —
    // that's the only way a customer can discover wallet-only covers them.
    Widget summaryCard = _AccordionSection(
      isVisible: hasAddress && hasShipping,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checkout.pointsInfo != null &&
                (checkout.pointsInfo!['enabled'] as bool? ?? false) &&
                ((checkout.pointsInfo!['available_points'] as num?)?.toInt() ?? 0) > 0) ...[
              PointsRedemptionCard(state: state, cubit: cubit),
              const SizedBox(height: 16),
            ],
            // Wallet toggle (real-money SAR) — web tree. Mirrors the mobile
            // body; renders only when the user has a positive balance.
            if ((checkout.walletBalance ?? 0) > 0) ...[
              WalletToggleCard(
                walletBalance: checkout.walletBalance ?? 0,
                // maxUsable = backend-clamped amount (≤ cart total).
                maxUsable: checkout.walletMaxUsable ?? checkout.walletBalance ?? 0,
              ),
              const SizedBox(height: 16),
            ],
            _AccordionSection(
              isVisible: hasPayment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlocBuilder<CheckoutCubit, CheckoutState>(
              buildWhen: (p, n) {
                if (p is CheckoutLoaded && n is CheckoutLoaded) {
                  return p.selectedShipping?.id != n.selectedShipping?.id ||
                      p.groupShippingSelections != n.groupShippingSelections ||
                      p.pointsToUse != n.pointsToUse ||
                      p.walletAmount != n.walletAmount;
                }
                return true;
              },
              builder: (context, snapState) {
                final snap = (snapState is CheckoutLoaded ? snapState : null)
                    ?? (state);
                final shipping = snap.selectedShipping
                    ?? snap.groupShippingSelections.values.firstOrNull;
                final isFree = shipping?.isFree ?? false;
                final originalShippingCost = shipping?.originalCost ?? snap.checkout.shippingCost;
                final effectiveShipping = isFree ? 0.0 : (shipping?.cost ?? snap.checkout.shippingCost);
                return OrderSummaryCard(
                  itemsTotal: snap.checkout.subtotal,
                      // Server-authoritative once a shipping method is chosen: the
                      // delivery fee is VAT-inclusive and joins the taxable base, so
                      // the VAT line covers goods + delivery. Never recompute it here.
                      serverVatAmount: snap.quote?.vatAmount,
                      shippingExclVat: snap.quote?.shippingExclVat,
                  couponDiscount: (snap.checkout.couponDiscount ?? 0) > 0
                      ? snap.checkout.couponDiscount
                      : null,
                  tierDiscount: (snap.checkout.tierDiscount ?? 0) > 0
                      ? snap.checkout.tierDiscount
                      : null,
                  shippingCost: effectiveShipping,
                  originalShippingCost: originalShippingCost,
                  isFreeShipping: isFree,
                  // Grand total is net of the applied wallet amount (a tender),
                  // so the displayed total matches what the gateway will charge.
                  total: snap.quote?.total ??
                      (snap.checkout.subtotal -
                      (snap.checkout.discount) -
                      (snap.pointsToUse /
                          (snap.checkout.pointsInfo?['rate'] as num? ?? 100)) +
                      effectiveShipping -
                      snap.walletAmount).clamp(0.0, double.infinity),
                  earnedPoints: snap.checkout.pointsToEarn,
                  pointsToUse: snap.pointsToUse,
                  walletApplied: snap.walletAmount,
                  pointsRate:
                      (snap.checkout.pointsInfo?['rate'] as num? ?? 100).toInt(),
                  vatEnabled: AppSettingsService.instance.vatVisible,
                  vatAmount: AppSettingsService.instance.vatVisible
                      ? (snap.checkout.vatAmount ?? (snap.checkout.total * 15 / 115))
                      : 0,
                );
              },
            ),
            const SizedBox(height: 24),
            BlocBuilder<CheckoutCubit, CheckoutState>(
              builder: (context, checkoutState) {
                final isLoading = checkoutState is PlacingOrder ||
                    checkoutState is InitiatingPayment;
                final provider = checkoutState is CheckoutLoaded
                    ? (checkoutState.selectedPayment?.provider ?? PaymentProvider.telr)
                    : PaymentProvider.telr;
                final appleEnabled = checkoutState is CheckoutLoaded
                    ? (checkoutState.selectedPayment?.applePayEnabled ?? false)
                    : false;
                final merchantId = checkoutState is CheckoutLoaded
                    ? checkoutState.selectedPayment?.appleMerchantId
                    : null;
                return _ConfirmButton(
                  isLoading: isLoading,
                  provider: provider,
                  applePayEnabled: appleEnabled,
                  appleMerchantId: merchantId,
                );
              },
            ),
          ],
        ),
      ),
          ],
    )
      )
    );

    // Hidden once the wallet alone covers the order — nothing to pick.
    Widget paymentCard = walletCovers
        ? const SizedBox.shrink()
        : _AccordionSection(
            isVisible: hasAddress && hasShipping,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CheckoutSectionCard(
                title: 'checkout.paymentMethod'.tr(),
                titleIcon: Icons.credit_card_outlined,
                isExpanded: true,
                child: _PaymentSection(
                  methods: _withApplePayTile(state.paymentMethods),
                  selectedPayment: state.selectedPayment,
                  selectedShipping: state.selectedShipping,
                  onSelect: cubit.selectPaymentMethod,
                ),
              ),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final hPad = isNarrow ? constraints.maxWidth * 0.04 : 32.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
              child: isNarrow
                  // ── Narrow: single column, sequential order ────────────
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftForms,
                        paymentCard,
                        const SizedBox(height: 16),
                        summaryCard,
                      ],
                    )
                  // ── Wide: side-by-side ────────────────────────────
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: leftForms),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              summaryCard,
                              const SizedBox(height: 16),
                              paymentCard,
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SavedAddressesSection extends StatelessWidget {
  final List<AddressEntity> addresses;
  final String? selectedId;
  final ValueChanged<AddressEntity> onSelect;
  final VoidCallback onAddAddress;
  final VoidCallback onManageAddresses;

  const _SavedAddressesSection({
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onAddAddress,
    required this.onManageAddresses,
  });

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;

    if (addresses.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: v.s8),
        child: Column(
          children: [
            Text(
              'checkout.noAddresses'.tr(),
              style: TextStyle(
                fontSize: t.s12,
                color: ColorsManager.defaultTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: v.s12),
            GestureDetector(
              onTap: onAddAddress,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: t.s18, color: ColorsManager.primaryColor),
                  SizedBox(width: h.s6),
                  Text(
                    'checkout.addAddress'.tr(),
                    style: TextStyle(
                      fontSize: t.s14,
                      color: ColorsManager.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final selectedAddress = addresses.firstWhere(
      (a) => a.id == selectedId,
      orElse: () => addresses.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAddressesSheet(context, isDark),
          child: Container(
            padding: EdgeInsets.all(h.s14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(h.s8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary2Color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_outlined, color: ColorsManager.primary2Color, size: t.s18),
                ),
                SizedBox(width: h.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedAddress.label,
                              style: TextStyle(
                                fontSize: t.s14,
                                fontWeight: FontWeight.bold,
                                color: ColorsManager.defaultText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorsManager.primary2Color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'checkout.changeAddress'.tr(),
                              style: TextStyle(
                                fontSize: t.s12,
                                color: ColorsManager.primary2Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: v.s6),
                      Text(
                        selectedAddress.fullAddress,
                        style: TextStyle(
                          fontSize: t.s12,
                          color: ColorsManager.defaultTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (selectedAddress.phone.isNotEmpty) ...[
                        SizedBox(height: v.s4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: t.s12, color: ColorsManager.defaultTextSecondary),
                            SizedBox(width: h.s4),
                            Text(
                              selectedAddress.phone,
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddressesSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'checkout.selectAddress'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorsManager.defaultText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: addresses.map((addr) {
                      return SavedAddressTile(
                        address: addr,
                        isSelected: selectedId == addr.id,
                        onTap: () {
                          onSelect(addr);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 16, left: 16, right: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onManageAddresses();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ColorsManager.primary2Color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'checkout.manageAddresses'.tr(),
                      style: const TextStyle(
                        color: ColorsManager.primary2Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMART SHIPPING SECTION — Multi-group aware
// Shows one shipping picker per group when cart splits (multi-vendor/warehouse).
// Falls back to the single global picker when there's only one group.
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutShippingSection extends StatelessWidget {
  final CheckoutLoaded state;
  final CheckoutCubit cubit;
  final bool isExpanded;

  const _CheckoutShippingSection({required this.state, required this.cubit, this.isExpanded = true});

  @override
  Widget build(BuildContext context) {
    final groups = state.checkout.groups;
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (groups != null && groups.isNotEmpty) {
      return Column(
        children: groups.map((group) {
          // A group is express only when the API marks the group itself as express.
          // Don't check method providers — every group has a locked express option.
          final isExpress = group.isExpressGroup || group.id == 'express';

          final selectedId = state.groupShippingSelections[group.id]?.id ??
              group.selectedShipping?.id ??
              '';
          final methods =
              group.availableShippingMethods ?? state.shippingMethods;

          return Container(
            margin: EdgeInsets.only(bottom: v.s16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpress
                    ? ColorsManager.primary2Color.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                width: isExpress ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Compact header ──────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: ColorsManager.primary2Color,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'checkout.shippingMethod'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorsManager.defaultText,
                      ),
                    ),
                    if (isExpress) ...[
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'assets/icons/shipping/express_ar.svg'
                            : 'assets/icons/shipping/express.svg',
                        height: 24,
                      ),
                    ],
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 14),
                            ShippingMethodPicker(
                              methods: methods,
                              selectedId: selectedId,
                              items: group.items,
                              isExpressGroup: isExpress,
                              errorItemName: state.errorItemName,
                              onSelect: (method) =>
                                  cubit.selectGroupShippingMethod(group.id, method),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Single-group fallback
    // Filter out disabled methods (express lock row) — they should never
    // appear as a radio option when there are no express items in cart.
    final singleGroupMethods =
        state.shippingMethods.where((m) => !m.isDisabled).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: ColorsManager.primaryColor),
              const SizedBox(width: 8),
              Text(
                'checkout.shippingMethod'.tr(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      ShippingMethodPicker(
                        methods: singleGroupMethods,
                        selectedId: state.selectedShipping?.id ?? '',
                        items: state.checkout.items,
                        onSelect: cubit.selectShippingMethod,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _GroupProductsPreview extends StatelessWidget {
  final List<CheckoutItemEntity> items;
  final String? errorItemName;
  const _GroupProductsPreview({required this.items, this.errorItemName});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    const int maxVisible = 4;
    final visibleItems = items.take(maxVisible).toList();
    final extraCount =
        items.length > maxVisible ? items.length - maxVisible : 0;

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visibleItems.length; i++)
            Positioned(
              left: (Directionality.of(context) == TextDirection.RTL)
                  ? null
                  : i * 40.0,
              right: (Directionality.of(context) == TextDirection.RTL)
                  ? i * 40.0
                  : null,
              child: _buildItemAvatar(context, visibleItems[i]),
            ),
          if (extraCount > 0)
            Positioned(
              left: (Directionality.of(context) == TextDirection.RTL)
                  ? null
                  : visibleItems.length * 40.0,
              right: (Directionality.of(context) == TextDirection.RTL)
                  ? visibleItems.length * 40.0
                  : null,
              child: _buildExtraBadge(context, extraCount),
            ),
        ],
      ),
    );
  }

  Widget _buildItemAvatar(BuildContext context, CheckoutItemEntity item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isError =
        errorItemName != null && item.name.trim() == errorItemName!.trim();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: isError
                ? Colors.redAccent
                : (isDark ? ColorsManager.surfaceDarkCard : Colors.white),
            width: isError ? 2.5 : 3),
        boxShadow: [
          if (isError)
            const BoxShadow(
              color: Colors.redAccent,
              blurRadius: 8,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: item.imageUrl.startsWith('assets/')
                ? Image.asset(item.imageUrl, fit: BoxFit.cover, width: 50, height: 50)
                : CachedNetworkImage(imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    errorWidget: (_, __, ___) => Container(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined,
                            size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
          ),
          if (item.quantity > 1)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: ColorsManager.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtraBadge(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        border: Border.all(
            color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ShippingSection extends StatelessWidget {
  final List<ShippingMethodEntity> methods;
  final String selectedId;
  final void Function(ShippingMethodEntity) onSelect;

  const _ShippingSection({
    required this.methods,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) return const SizedBox.shrink();

    final v = AppSizeVertical.instance;

    return Column(
      children: List.generate(methods.length, (i) {
        final method = methods[i];
        final isSelected = selectedId == method.id;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final costText = method.isFree ? 'checkout.free'.tr() : null;
        final costColor = method.isFree
            ? ColorsManager.primaryColor
            : (isDark ? Colors.white : Colors.black87);

        Widget? trailingBadge;
        if (method.isCodSupported) {
          trailingBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'COD',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: i < methods.length - 1 ? v.s8 : 0),
          child: SelectableOptionTile(
            title: method.name,
            subtitle:
                method.estimatedTime.isNotEmpty ? method.estimatedTime : null,
            leadingWidget: _shippingLogo(method),
            trailingWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingBadge != null) ...[
                  trailingBadge,
                  const SizedBox(width: 8),
                ],
                if (costText != null)
                  Text(
                    costText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: costColor,
                    ),
                  )
                else
                  SarText(
                    price: method.cost.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: costColor,
                    ),
                  ),
              ],
            ),
            isSelected: isSelected,
            onTap: () => onSelect(method),
            isFirst: i == 0,
            isLast: i == methods.length - 1,
          ),
        );
      }),
    );
  }

  Widget _shippingLogo(ShippingMethodEntity method) {
    final iconUrl = method.iconUrl;

    if (iconUrl != null && iconUrl.isNotEmpty) {
      final finalUrl = iconUrl.startsWith('http') 
          ? iconUrl 
          : 'https://admin.fastwayprotein.com$iconUrl';

      return Container(
        width: 40,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: CachedNetworkImage(
          imageUrl: finalUrl,
          height: 16,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          errorWidget: (_, __, ___) => _fallbackShippingSvg(method.provider),
        ),
      );
    }

    return _fallbackShippingSvg(method.provider);
  }

  Widget _fallbackShippingSvg(String provider) {
    String assetName;
    switch (provider.toLowerCase()) {
      case 'redbox':
        assetName = 'assets/icons/shipping/redbox.svg';
        break;
      case 'aramex':
        assetName = 'assets/icons/shipping/aramex.svg';
        break;
      case 'express':
        assetName = 'assets/icons/shipping/express.svg';
        break;
      case 'standard':
        assetName = 'assets/icons/shipping/standard.svg';
        break;
      case 'oto':
        assetName = 'assets/icons/shipping/oto.svg';
        break;
      default:
        return Container(
          width: 40,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              size: 16, color: ColorsManager.defaultTextSecondary),
        );
    }

    return Container(
      width: 40,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SvgPicture.asset(
        assetName,
        height: 16,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSection extends StatelessWidget {
  final List<PaymentMethodEntity> methods;
  // Full entity, not just its id: the Apple Pay tile shares its `id` with the
  // card-only Telr tile (same backend gateway), so id alone can't tell tiles
  // apart. Equatable's `==` (covers name/applePayEnabled/isApplePayTile too)
  // correctly distinguishes them.
  final PaymentMethodEntity? selectedPayment;
  final ShippingMethodEntity? selectedShipping;
  final void Function(PaymentMethodEntity) onSelect;

  const _PaymentSection({
    required this.methods,
    required this.selectedPayment,
    this.selectedShipping,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) return const SizedBox.shrink();

    final selectedMethod = methods.cast<PaymentMethodEntity?>().firstWhere(
      (m) => m == selectedPayment,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 75,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: methods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final method = methods[i];
              
              // COD constraints
              bool isEnabled = true;
              if (method.provider == PaymentProvider.cod) {
                if (selectedShipping != null && !selectedShipping!.isCodSupported) {
                  isEnabled = false;
                }
              }

              return _PaymentTile(
                method: method,
                isSelected: selectedPayment == method,
                isEnabled: isEnabled,
                onTap: () {
                  if (isEnabled) onSelect(method);
                },
              );
            },
          ),
        ),

        // Accordion Note
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: selectedMethod == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SelectedPaymentNote(method: selectedMethod),
                ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentMethodEntity method;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 75,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorsManager.primary2Color.withValues(alpha: 0.05)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ColorsManager.primary2Color
                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: _PaymentLogo(method: method),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentLogo extends StatelessWidget {
  final PaymentMethodEntity method;
  const _PaymentLogo({required this.method});

  @override
  Widget build(BuildContext context) {
    // Local overrides for known payment methods to avoid cropped backend images
    final nameLower = method.name.toLowerCase();
    final idLower = method.id.toLowerCase();
    
    String? overrideSvg;
    if (nameLower.contains('master') || idLower.contains('master')) {
      overrideSvg = 'assets/icons/payments/mastercard-svgrepo-com.svg';
    } else if (nameLower.contains('apple') || idLower.contains('apple')) {
      overrideSvg = 'assets/icons/payments/apple-pay-svgrepo-com.svg';
    } else if (nameLower.contains('mada') || idLower.contains('mada')) {
      overrideSvg = 'assets/icons/payments/mada_Logo.svg';
    } else if (nameLower.contains('visa') || idLower.contains('visa')) {
      overrideSvg = 'assets/icons/payments/visa-svgrepo-com.svg';
    }

    if (overrideSvg != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SvgPicture.asset(
          overrideSvg,
          height: 48,
          fit: BoxFit.contain,
        ),
      );
    }

    final iconUrl = method.iconUrl;

    if (iconUrl != null && iconUrl.isNotEmpty) {
      final finalUrl = iconUrl.startsWith('http') 
          ? iconUrl 
          : 'https://admin.fastwayprotein.com$iconUrl';

      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: CachedNetworkImage(
          imageUrl: finalUrl,
          height: 48,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          errorWidget: (_, __, ___) => _fallbackSvg(method.provider),
        ),
      );
    }

    return _fallbackSvg(method.provider);
  }

  Widget _fallbackSvg(PaymentProvider provider) {
    String? assetName;
    switch (provider) {
      case PaymentProvider.tamara:
        assetName = 'assets/icons/payments/tamara.svg';
        break;
      case PaymentProvider.tabby:
        assetName = 'assets/icons/payments/tabby.svg';
        break;
      case PaymentProvider.cod:
        assetName = 'assets/icons/payments/cod.svg';
        break;
      case PaymentProvider.telr:
        assetName = 'assets/icons/payments/telr.svg';
        break;
      case PaymentProvider.unknown:
        assetName = null;
        break;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: assetName != null
          ? SvgPicture.asset(
              assetName,
              height: 28,
              fit: BoxFit.contain,
            )
          : const Icon(Icons.credit_card_outlined, size: 24, color: Colors.grey),
    );
  }
}

class _SelectedPaymentNote extends StatelessWidget {
  final PaymentMethodEntity method;
  const _SelectedPaymentNote({required this.method});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String? subtitle;
    Widget? badge;
    switch (method.provider) {
      case PaymentProvider.tamara:
        subtitle = 'checkout.payment.pay_in_30'.tr();
        badge = _buildBadge('checkout.installments'.tr());
        break;
      case PaymentProvider.tabby:
        subtitle = 'checkout.payment.split_in_4'.tr();
        badge = _buildBadge('checkout.installments'.tr());
        break;
      case PaymentProvider.cod:
        subtitle = 'checkout.guest_form.pay_cod'.tr();
        break;
      default:
        subtitle = null;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              method.name,
              style: const TextStyle(fontSize: 13, color: ColorsManager.defaultTextSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: ColorsManager.defaultTextSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            badge,
          ],
        ],
      ),
    );
  }
  
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsManager.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ColorsManager.primaryColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmButton extends StatefulWidget {
  final bool isLoading;
  final PaymentProvider provider;
  // S5 — Apple Pay gate fields from the selected PaymentMethodEntity
  final bool applePayEnabled;
  final String? appleMerchantId;

  const _ConfirmButton({
    required this.isLoading,
    required this.provider,
    this.applePayEnabled = false,
    this.appleMerchantId,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconAnim;
  PaymentProvider? _animatingFor;

  // WEB-only: true when the browser can actually present Apple Pay. Checked once
  // (ApplePaySession.canMakePayments) so build() stays cheap.
  bool _webApplePaySupported = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webApplePaySupported = webApplePayAvailable();
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _iconAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _animatingFor = widget.provider;
    if (widget.provider == PaymentProvider.tabby ||
        widget.provider == PaymentProvider.tamara) {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ConfirmButton old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) {
      if (widget.provider == PaymentProvider.tabby ||
          widget.provider == PaymentProvider.tamara) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.reverse();
      }
      _animatingFor = widget.provider;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// The black Apple Pay button — shared by the native (iOS) and web flows.
  Widget _appleButton(VoidCallback onTap) {
    if (!kIsWeb && Platform.isIOS) {
      return Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        child: RawApplePayButton(
          style: ApplePayButtonStyle.black,
          type: ApplePayButtonType.buy,
          cornerRadius: 16,
          onPressed: onTap,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'checkout.payment.applePayButton'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabby   = widget.provider == PaymentProvider.tabby;
    final isTamara  = widget.provider == PaymentProvider.tamara;
    final isBranded = isTabby || isTamara;

    // ── Branded colors ──────────────────────────────────────────────────────
    final Gradient? btnGradient = isTamara
        ? const LinearGradient(
            colors: [Color(0xFFFFCB52), Color(0xFFFF9C7B), Color(0xFFFF7D7D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : isTabby
            ? const LinearGradient(
                colors: [Color(0xFF3DFFC0), Color(0xFF3DFFC0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null;

    final Color textColor = isBranded ? Colors.black : Colors.white;
    final Color spinnerColor = isBranded ? Colors.black : Colors.white;

    // ── SVG logo path ────────────────────────────────────────────────────────
    final String? logoAsset = isTabby
        ? 'assets/icons/payments/tabby.svg'
        : isTamara
            ? 'assets/icons/payments/tamara.svg'
            : null;

    // ── Apple Pay button (iOS-only, gated by backend flag + merchant id) ─────
    // kIsWeb guard is required — dart:io Platform throws on Flutter Web.
    // Require a merchant id too: without it the SDK can't present the sheet.
    final bool showApplePay = !kIsWeb
        && Platform.isIOS
        && widget.applePayEnabled
        && (widget.appleMerchantId?.isNotEmpty ?? false)
        && !widget.isLoading;

    // WEB Apple Pay (Apple Pay JS) — shown only on a browser that can actually
    // pay (ApplePaySession). Same backend flag + merchant id gate as native.
    final bool showWebApplePay = kIsWeb
        && _webApplePaySupported
        && widget.applePayEnabled
        && (widget.appleMerchantId?.isNotEmpty ?? false)
        && !widget.isLoading;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // ── Apple Pay button — native (iOS app) OR web (Apple Pay JS) ───────
          // Mutually exclusive: showApplePay is app-only, showWebApplePay is web-only.
          if (showApplePay) ...[
            _appleButton(() async {
              // Native: the cubit creates the Telr order, presents the SDK sheet
              // with this merchant id, then confirms the charge server-side.
              final merchantId = widget.appleMerchantId;
              if (merchantId == null || merchantId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('checkout.payment.applePayUnavailable'.tr())),
                );
                return;
              }
              await context.read<CheckoutCubit>().applePayPlaceOrder(
                context,
                appleMerchantId: merchantId,
              );
            }),
          ],
          if (showWebApplePay) ...[
            _appleButton(() {
              // WEB: MUST be synchronous — Safari requires the ApplePaySession to
              // be created inside this gesture (the cubit does so with no awaits
              // before it). Not awaited here on purpose.
              context.read<CheckoutCubit>().webApplePayPlaceOrder(context);
            }),
          ],
          // ── Regular confirm button ──────────────────────────────────────────
          // Hidden when Apple Pay is showing: selecting the Apple Pay tile fully
          // REPLACES this button with the black Apple Pay one above (same pattern
          // as Tabby/Tamara replacing it with their own branded button) — never
          // both at once.
          if (!showApplePay && !showWebApplePay)
          AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return MouseRegion(
            cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.isLoading
                  ? null
                  : () => context.read<CheckoutCubit>().placeOrder(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: 54,
              decoration: BoxDecoration(
                gradient: btnGradient,
                color: btnGradient == null ? ColorsManager.secondaryColor : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isTabby
                        ? const Color(0xFF3DFFC0).withValues(alpha: 0.35)
                        : isTamara
                            ? const Color(0xFFFFCB52).withValues(alpha: 0.35)
                            : ColorsManager.secondaryColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: spinnerColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Default label ──────────────────────────────────
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          child: Text('checkout.confirm'.tr()),
                        ),

                        // ── Divider + Logo (only for branded) ─────────────
                        if (logoAsset != null) ...[
                          ScaleTransition(
                            scale: _iconAnim,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.black.withValues(alpha: 0.25),
                                ),
                                const SizedBox(width: 12),
                                SvgPicture.asset(
                                  logoAsset,
                                  height: isTamara ? 15 : 20,
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          )
          );
        },
      ),
        ], // Column children
        ), // Column
      ), // Padding
    ); // SafeArea
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GuestAddressForm extends StatefulWidget {
  final List<CityEntity> cities;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const _GuestAddressForm({
    required this.cities,
    required this.onSubmit,
  });

  @override
  State<_GuestAddressForm> createState() => _GuestAddressFormState();
}

class _GuestAddressFormState extends State<_GuestAddressForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — same set as add_edit_address_screen
  final _nameCtrl          = TextEditingController();
  final _labelCtrl         = TextEditingController();
  final _shortAddressCtrl  = TextEditingController();
  final _streetCtrl        = TextEditingController();
  final _districtCtrl      = TextEditingController();
  final _buildingCtrl      = TextEditingController();
  final _postalCodeCtrl    = TextEditingController();
  final _additionalNumCtrl = TextEditingController();
  final _landmarkCtrl      = TextEditingController(); // optional notes/landmark
  final _phoneCtrl         = TextEditingController();

  CityEntity? _selectedCity;
  bool _saved         = false;
  bool _isLookingUp   = false;
  // Must search short address before allowing save (same gate as add_edit_address_screen)
  bool _lookupDone    = false;
  bool _cityLockedAfterLookup = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _shortAddressCtrl.dispose();
    _streetCtrl.dispose();
    _districtCtrl.dispose();
    _buildingCtrl.dispose();
    _postalCodeCtrl.dispose();
    _additionalNumCtrl.dispose();
    _landmarkCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupShortAddress() async {
    final shortAddr = _shortAddressCtrl.text.trim();
    if (shortAddr.isEmpty) return;

    setState(() => _isLookingUp = true);
    final repo = sl<ProfileRepository>();
    final result = await repo.lookupAddress(shortAddr);
    setState(() => _isLookingUp = false);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failure.message),
          backgroundColor: ColorsManager.errorFill,
        ));
      },
      (data) {
        if (!mounted) return;
        setState(() {
          // Auto-fill API-locked fields
          _buildingCtrl.text      = data['building']?.toString() ?? _buildingCtrl.text;
          _postalCodeCtrl.text    = data['postal_code']?.toString() ?? _postalCodeCtrl.text;
          _additionalNumCtrl.text = data['additional_number']?.toString() ?? _additionalNumCtrl.text;
          // Editable fields (pre-fill only if empty)
          if (_streetCtrl.text.isEmpty)   _streetCtrl.text   = data['street']?.toString()   ?? '';
          if (_districtCtrl.text.isEmpty) _districtCtrl.text = data['district']?.toString() ?? '';
          if (_landmarkCtrl.text.isEmpty) _landmarkCtrl.text = data['full_address']?.toString() ?? '';

          // Lock city after lookup
          final city = data['city']?.toString();
          if (city != null && widget.cities.isNotEmpty) {
            final match = widget.cities.where(
                (c) => c.name.toLowerCase() == city.toLowerCase() || c.nameAr == city);
            if (match.isNotEmpty) {
              _selectedCity = match.first;
              _cityLockedAfterLookup = true;
            }
          }

          _lookupDone = true;
          _saved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('checkout.guest_form.fetch_success'.tr()),
          backgroundColor: ColorsManager.primaryColor,
        ));
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Extra gate: must have looked up short address (same as add_edit_address_screen)
    if (!_lookupDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.guest_form.fetch_error'.tr()),
        backgroundColor: ColorsManager.errorFill,
      ));
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('address.selectCityRequired'.tr()),
        backgroundColor: ColorsManager.errorFill,
      ));
      return;
    }

    widget.onSubmit({
      'name':              _nameCtrl.text.trim(),
      'label':             _labelCtrl.text.trim(),
      'short_address':     _shortAddressCtrl.text.trim(),
      'phone':             _phoneCtrl.text.trim(),
      'street':            _streetCtrl.text.trim(),
      'district':          _districtCtrl.text.trim(),
      'building':          _buildingCtrl.text.trim(),
      'postal_code':       _postalCodeCtrl.text.trim(),
      'additional_number': _additionalNumCtrl.text.trim(),
      'full_address':      _landmarkCtrl.text.trim(),
      'city':              _selectedCity!.name,
    });
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section label ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: ColorsManager.primaryColor),
                const SizedBox(width: 5),
                Text('checkout.guest_form.title'.tr(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.primaryColor)),
              ],
            ),
          ),

          // ── Fields card ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                // ── Name (required) ──────────────────────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.person_outline_rounded,
                  label: 'checkout.guest_form.name'.tr(),
                  hint: 'checkout.guest_form.name_hint'.tr(),
                  controller: _nameCtrl,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'validation.required'.tr() : null,
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Label / nickname (optional) ──────────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.label_outline_rounded,
                  label: 'checkout.guest_form.desc'.tr(),
                  hint: 'checkout.guest_form.address_hint'.tr(),
                  controller: _labelCtrl,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Short Address + search button + lookup hint ──────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.qr_code_2_outlined,
                  label: 'checkout.guest_form.short_address'.tr(),
                  hint: 'checkout.guest_form.national_address_hint'.tr(),
                  controller: _shortAddressCtrl,
                  isDark: isDark,
                  onChanged: (_) => setState(() { _saved = false; _lookupDone = false; }),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'checkout.guest_form.short_address_req'.tr() : null,
                  suffixIcon: _isLookingUp
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _lookupShortAddress,
                          color: ColorsManager.primaryColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ),
                // Lookup status indicator (same as add_edit_address_screen)
                if (!_lookupDone)
                  Padding(
                    padding: const EdgeInsets.only(right: 62, bottom: 6),
                    child: Text(
                      'checkout.guest_form.search_short_address'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorsManager.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                if (_lookupDone)
                  Padding(
                    padding: const EdgeInsets.only(right: 62, bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 11, color: Colors.green),
                        const SizedBox(width: 3),
                        Text('checkout.guest_form.address_verified'.tr(),
                            style: const TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                    ),
                  ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Street (optional, editable) ──────────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.add_road_outlined,
                  label: 'checkout.guest_form.street'.tr(),
                  hint: 'checkout.guest_form.street_hint'.tr(),
                  controller: _streetCtrl,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── District (optional, editable) ────────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.map_outlined,
                  label: 'checkout.guest_form.district'.tr(),
                  hint: 'checkout.guest_form.district_hint'.tr(),
                  controller: _districtCtrl,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Building (read-only, auto-filled by API) ─────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.apartment_outlined,
                  label: 'checkout.guest_form.building'.tr(),
                  hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                  controller: _buildingCtrl,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Postal Code (read-only, auto-filled by API) ───────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.local_post_office_outlined,
                  label: 'checkout.guest_form.postal'.tr(),
                  hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                  controller: _postalCodeCtrl,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Additional Number (read-only, auto-filled by API) ─────────
                _CheckoutAddressFieldRow(
                  icon: Icons.numbers_outlined,
                  label: 'checkout.guest_form.extra'.tr(),
                  hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                  controller: _additionalNumCtrl,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Landmark / extra notes (optional) ────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.place_outlined,
                  label: 'checkout.guest_form.landmark'.tr(),
                  hint: 'checkout.guest_form.additional_info_hint'.tr(),
                  controller: _landmarkCtrl,
                  maxLines: 2,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── Phone (required) ─────────────────────────────────────────
                _CheckoutAddressFieldRow(
                  icon: Icons.phone_outlined,
                  label: '${'checkout.guest.phone'.tr()} *',
                  hint: 'checkout.guest_form.phone_hint'.tr(),
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _saved = false),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'validation.required'.tr() : null,
                ),
                _CheckoutRowDivider(isDark: isDark),

                // ── City Dropdown (locked after lookup) ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ColorsManager.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_city_outlined,
                            size: 17, color: ColorsManager.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('address.city'.tr(),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            _cityLockedAfterLookup
                                // City locked after lookup (greyed out) — same as add_edit_address_screen
                                ? IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.5,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                            canvasColor: isDark
                                                ? ColorsManager.surfaceDarkCard
                                                : Colors.white),
                                        child: CityDropdown(
                                          cities: widget.cities,
                                          selectedCity: _selectedCity,
                                          onChanged: (_) {},
                                        ),
                                      ),
                                    ),
                                  )
                                : Theme(
                                    data: Theme.of(context).copyWith(
                                        canvasColor: isDark
                                            ? ColorsManager.surfaceDarkCard
                                            : Colors.white),
                                    child: CityDropdown(
                                      cities: widget.cities,
                                      selectedCity: _selectedCity,
                                      onChanged: (city) => setState(() {
                                        _selectedCity = city;
                                        _saved = false;
                                      }),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: v.s14),

          // ── Save / confirm button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(
                _saved ? Icons.check_circle_outline : Icons.save_outlined,
                size: 18,
              ),
              label: Text(
                _saved ? 'checkout.guest.saved'.tr() : 'checkout.guest.save'.tr(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved
                    ? ColorsManager.primaryColor.withValues(alpha: 0.75)
                    : ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _CheckoutAddressFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final FormFieldValidator<String>? validator;

  const _CheckoutAddressFieldRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
    this.onChanged,
    this.readOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = readOnly
        ? cs.onSurfaceVariant.withValues(alpha: 0.45)
        : cs.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: readOnly ? 0.04 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17,
                color: ColorsManager.primaryColor.withValues(alpha: readOnly ? 0.45 : 1.0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  onChanged: onChanged,
                  readOnly: readOnly,
                  validator: validator,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: effectiveColor),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    suffixIcon: suffixIcon,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutRowDivider extends StatelessWidget {
  final bool isDark;
  const _CheckoutRowDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 58,
        color:
            isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
      );
}
// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY SLOTS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _DeliverySlotsSection extends StatelessWidget {
  final Map<String, List<String>> slots;
  final String? selectedDate;
  final String? selectedSlot;
  final void Function(String, String) onSelect;

  const _DeliverySlotsSection({
    required this.slots,
    this.selectedDate,
    this.selectedSlot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    final dates = slots.keys.toList();
    final activeDate = selectedDate ?? dates.first;
    final activeSlots = slots[activeDate] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dates.map((date) {
              final isSelected = date == activeDate;
              return GestureDetector(
                onTap: () {
                  if (!isSelected &&
                      slots[date] != null &&
                      slots[date]!.isNotEmpty) {
                    onSelect(date, slots[date]!.first);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorsManager.primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.primaryColor
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    date,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : ColorsManager.defaultTextSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (activeSlots.isEmpty)
          Text(
            'checkout.noSlotsAvailable'.tr(),
            style: const TextStyle(color: Colors.red),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeSlots.map((slot) {
              final isSelectedSlot =
                  slot == selectedSlot && activeDate == selectedDate;
              return GestureDetector(
                onTap: () => onSelect(activeDate, slot),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelectedSlot
                        ? ColorsManager.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelectedSlot
                          ? ColorsManager.primaryColor
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelectedSlot
                          ? ColorsManager.primaryColor
                          : ColorsManager.defaultTextSecondary,
                      fontWeight:
                          isSelectedSlot ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAP-3: Delivery Notes — optional customer note sent with the order.
// StatefulWidget so the TextEditingController is properly disposed.
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryNotesSection extends StatefulWidget {
  final CheckoutCubit cubit;
  const _DeliveryNotesSection({required this.cubit});

  @override
  State<_DeliveryNotesSection> createState() => _DeliveryNotesSectionState();
}

class _DeliveryNotesSectionState extends State<_DeliveryNotesSection> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CheckoutSectionCard(
      title: 'checkout.deliveryNotes'.tr(),
      titleIcon: Icons.notes_outlined,
      child: TextField(
        controller: _ctrl,
        maxLines: 3,
        minLines: 2,
        onChanged: widget.cubit.setNotes,
        decoration: InputDecoration(
          hintText: 'checkout.deliveryNotesHint'.tr(),
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorsManager.primaryColor),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade50,
        ),
      ),
    );
  }
}
