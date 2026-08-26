import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/profile/presentation/cubit/addresses_cubit.dart';
import 'package:fastway/features/profile/presentation/cubit/addresses_state.dart';
import 'package:fastway/features/user_data/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/cubit/delivery_location/delivery_location_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/di/injection_container.dart';

class LocationPickerSheet extends StatelessWidget {
  const LocationPickerSheet({super.key});

  // ── Mobile: bottom-sheet (unchanged) ─────────────────────────────────────
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cubit = sl<AddressesCubit>();
        if (!AuthGuard.isGuest(context)) {
          cubit.load();
        }
        return BlocProvider<AddressesCubit>.value(
          value: cubit,
          child: const LocationPickerSheet(),
        );
      },
    );
  }

  // ── Web: Overlay dropdown anchored below the button ───────────────────────
  static OverlayEntry? _activeEntry;

  static void showDropdown(BuildContext context, GlobalKey anchorKey) {
    _dismiss();

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size   = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Grab cubit before inserting overlay (context is valid here)
    final cubit = sl<AddressesCubit>();
    if (!AuthGuard.isGuest(context)) cubit.load();

    // Capture BLoC providers that the sheet needs
    final deliveryCubit = context.read<DeliveryLocationCubit>();

    _activeEntry = OverlayEntry(
      builder: (_) => _LocationDropdown(
        left: offset.dx,
        top: offset.dy + size.height + 8,
        isDark: isDark,
        addressesCubit: cubit,
        deliveryCubit: deliveryCubit,
        onDismiss: _dismiss,
      ),
    );

    Overlay.of(context).insert(_activeEntry!);
  }

  static void _dismiss() {
    _activeEntry?.remove();
    _activeEntry = null;
  }

  // ── Widget (used by mobile bottom-sheet) ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = AuthGuard.isGuest(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24.h,
        left: 24.w,
        right: 24.w,
        bottom: MediaQuery.paddingOf(context).bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _LocationContent(isDark: isDark, isGuest: isGuest, onClose: () => Navigator.pop(context)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay dropdown (web)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationDropdown extends StatefulWidget {
  final double left;
  final double top;
  final bool isDark;
  final AddressesCubit addressesCubit;
  final DeliveryLocationCubit deliveryCubit;
  final VoidCallback onDismiss;

  const _LocationDropdown({
    required this.left,
    required this.top,
    required this.isDark,
    required this.addressesCubit,
    required this.deliveryCubit,
    required this.onDismiss,
  });

  @override
  State<_LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<_LocationDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final screenWidth = MediaQuery.sizeOf(context).width;

    const cardWidth = 320.0;
    final clampedLeft = (widget.left + cardWidth > screenWidth - 8)
        ? screenWidth - cardWidth - 8
        : widget.left;

    return Stack(
      children: [
        // Dismiss backdrop
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),

        // Card
        Positioned(
          left: clampedLeft,
          top: widget.top,
          width: cardWidth,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 480),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<AddressesCubit>.value(
                          value: widget.addressesCubit),
                      BlocProvider<DeliveryLocationCubit>.value(
                          value: widget.deliveryCubit),
                    ],
                    child: _LocationContent(
                      isDark: widget.isDark,
                      isGuest: AuthGuard.isGuest(context),
                      isDropdown: true,
                      onClose: widget.onDismiss,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared content (used by both mobile sheet and web dropdown)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationContent extends StatelessWidget {
  final bool isDark;
  final bool isGuest;
  final bool isDropdown;
  final VoidCallback onClose;

  const _LocationContent({
    required this.isDark,
    required this.isGuest,
    this.isDropdown = false,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, isDropdown ? 20 : 24.h, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: ColorsManager.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'home.choose_delivery_location'.tr(),
                  style: TextStyle(
                    fontSize: isDropdown ? 15 : 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              if (isDropdown)
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Addresses list
          if (!isGuest)
            BlocBuilder<AddressesCubit, AddressesState>(
              builder: (context, state) {
                if (state is AddressesLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is AddressesLoaded) {
                  final addresses = state.addresses;
                  if (addresses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'home.no_saved_addresses'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subColor, fontSize: 13),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...addresses.asMap().entries.map((e) {
                        final address = e.value;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: e.key < addresses.length - 1 ? 10 : 0),
                          child: BlocBuilder<DeliveryLocationCubit,
                              DeliveryLocationState>(
                            builder: (context, locationState) {
                              final isSelected =
                                  locationState is DeliveryLocationResolved &&
                                      locationState.selectedAddress?.id ==
                                          address.id;
                              return InkWell(
                                onTap: () {
                                  context
                                      .read<DeliveryLocationCubit>()
                                      .setManualAddress(address);
                                  onClose();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? ColorsManager.primaryColor
                                          : (isDark
                                              ? Colors.white12
                                              : Colors.black12),
                                    ),
                                    color: isSelected
                                        ? ColorsManager.primaryColor
                                            .withValues(alpha: 0.06)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 18,
                                        color: isSelected
                                            ? ColorsManager.primaryColor
                                            : subColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              address.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1A1A2E),
                                                fontFamily: 'Tajawal',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              address.fullAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: subColor,
                                                  fontFamily: 'Tajawal'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded,
                                            size: 16,
                                            color: ColorsManager.primaryColor),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),

          if (isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'home.login_to_view_addresses'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13),
              ),
            ),

          const SizedBox(height: 12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),

          // Use GPS button
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                onClose();
                context
                    .read<DeliveryLocationCubit>()
                    .requestLocationFromUser();
              },
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: Text('home.use_current_location'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // "Manage addresses" link
          if (!isGuest) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                onClose();
                AppNavigator.pushNamed(context, Routes.addresses);
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              child: Text(
                'checkout.manageAddresses'.tr(),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
