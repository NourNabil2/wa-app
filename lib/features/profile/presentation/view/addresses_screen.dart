// lib/features/addresses/presentation/view/addresses_screen.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/layout/simple_web_shell.dart';
import '../../../../core/responsive/responsive_grid.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../cubit/addresses_cubit.dart';
import '../cubit/addresses_state.dart';
import 'add_edit_address_screen.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/web_breadcrumb.dart';

class AddressesScreen extends StatefulWidget {
  final bool isModal;
  const AddressesScreen({super.key, this.isModal = false});

  static Future<void> show(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BlocProvider(
          create: (_) => di.sl<AddressesCubit>(),
          child: const AddressesScreen(isModal: true),
        ),
      );
    }

    // Web / Tablet / Desktop: responsive dialog
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) {
        final dialogWidth = screenWidth < 900
            ? screenWidth * 0.9
            : 620.0;
        final maxH = MediaQuery.sizeOf(context).height * 0.88;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: maxH),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: BlocProvider(
                create: (_) => di.sl<AddressesCubit>(),
                child: const AddressesScreen(isModal: true),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    // Defer load until after the first frame so the cubit is fully mounted
    // and won't be closed before the first emit (fixes "emit after close" crash).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddressesCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (widget.isModal) {
        return _buildWebModal(context);
      }
      return _buildWeb(context);
    }
    return _buildMobileSheet(context);
  }

  // ── Web full page ───────────────────────────────────────────────────────────

  Widget _buildWebModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dialog header with title + close button ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: ColorsManager.primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'profile.addresses'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => AddEditAddressScreen.show(context, context.read<AddressesCubit>()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text('address.add'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          
          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: BlocConsumer<AddressesCubit, AddressesState>(
              listener: (context, state) {
                if (state is AddressesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              },
              builder: (context, state) {
                final addresses = (state is AddressesLoaded)
                    ? state.addresses
                    : (state is AddressActionLoading ? state.currentAddresses : <AddressEntity>[]);

                if (state is AddressesLoading || state is AddressesInitial) {
                  return const Padding(padding: EdgeInsets.only(top: 80), child: AddressesSkeleton());
                } else if (addresses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off_rounded, size: 72, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'address.empty'.tr(),
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final int crossAxisCount = w < 500 ? 1 : 2;
                        final double spacing = 16.0;
                        final double cardWidth = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                        // floor the width to avoid subpixel layout issues
                        final safeWidth = cardWidth.floorToDouble();

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: addresses.map((addr) => SizedBox(
                            width: safeWidth,
                            child: _AddressCard(address: addr, isModal: true),
                          )).toList(),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SimpleWebShell(
      content: BlocConsumer<AddressesCubit, AddressesState>(
        listener: (context, state) {
          if (state is AddressesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final addresses = (state is AddressesLoaded)
              ? state.addresses
              : (state is AddressActionLoading
                  ? state.currentAddresses
                  : <AddressEntity>[]);

          return Center(
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WebBreadcrumb(
                    isDark: isDark,
                    labels: ['dashboard.home'.tr(), 'footer.account'.tr(), 'profile.addresses'.tr()],
                    onTaps: [
                      () => AppNavigator.pushNamed(context, Routes.dashBoard),
                      () => AppNavigator.pushNamed(context, Routes.profile),
                      null,
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Page header ─────────────────────────────────────────────
                  Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.location_on_rounded,
                            color: ColorsManager.primaryColor, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'profile.addresses'.tr(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0D0D14),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      // Add button
                      ElevatedButton(
                        onPressed: () => AddEditAddressScreen.show(
                            context, context.read<AddressesCubit>()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: Text('address.add'.tr(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Content ─────────────────────────────────────────────────
                  if (state is AddressesLoading || state is AddressesInitial)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: AddressesSkeleton(),
                    )
                  else if (addresses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.location_off_rounded,
                                size: 72,
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'address.empty'.tr(),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final int crossAxisCount = w < 600 ? 1 : 2;
                        final double spacing = 16.0;
                        final double cardWidth = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                        final safeWidth = cardWidth.floorToDouble();

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: addresses
                              .map((addr) => SizedBox(
                                    width: safeWidth,
                                    child: _AddressCard(address: addr, isModal: widget.isModal),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  // ── Mobile bottom sheet ─────────────────────────────────────────────────────

  Widget _buildMobileSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FB);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
          // BoxShadow removed — blur:32 on bottom sheet opening
        ),
      child: BlocConsumer<AddressesCubit, AddressesState>(
        listener: (context, state) {
          if (state is AddressesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final addresses = (state is AddressesLoaded)
              ? state.addresses
              : (state is AddressActionLoading
                  ? state.currentAddresses
                  : <AddressEntity>[]);

          return Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.zero),
              ),
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: ColorsManager.primaryColor, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('profile.addresses'.tr(),
                          style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A))),
                    ),
                    ElevatedButton(
                      onPressed: () => AddEditAddressScreen.show(
                          context, context.read<AddressesCubit>()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text('address.add'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.sp)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color:
                                isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200),
              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: (state is AddressesLoading || state is AddressesInitial)
                    ? const AddressesSkeleton()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addresses.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60),
                                  child: Column(
                                    children: [
                                      Icon(Icons.location_off_rounded,
                                          size: 64,
                                          color: isDark
                                              ? Colors.grey[700]
                                              : Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'address.empty'.tr(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ResponsiveGrid(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 1,
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: addresses
                                    .map((addr) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _AddressCard(address: addr, isModal: widget.isModal),
                                        ))
                                    .toList(),
                              ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLEAN & BORDERLESS ADDRESS CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _AddressCard extends StatelessWidget {
  final AddressEntity address;
  final bool isModal;
  const _AddressCard({required this.address, this.isModal = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final cubit = context.read<AddressesCubit>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        // حد خفيف جداً فقط إذا كان العنوان الافتراضي
        border: address.isDefault
            ? Border.all(
                color: ColorsManager.primaryColor.withValues(alpha: 0.5),
                width: 1.5)
            : null,
        // BoxShadow removed from address card
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Icon, Label, Badge, PopupMenu ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  address.label.toLowerCase().contains('عمل') ||
                          address.label.toLowerCase().contains('work')
                      ? Icons.work_outline_rounded
                      : Icons.home_rounded,
                  color: ColorsManager.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorsManager.primaryColor
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'address.default'.tr(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ColorsManager.primaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Popup Menu بديل للـ BottomSheet المزعج ──
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    AddEditAddressScreen.show(context, cubit, address: address);
                  } else if (value == 'default') {
                    cubit.setDefault(address.id);
                  } else if (value == 'delete') {
                    cubit.deleteAddress(address.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: isDark ? Colors.white : Colors.black87),
                        const SizedBox(width: 8),
                        Text('common.edit'.tr(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                  if (!address.isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 20, color: ColorsManager.primaryColor),
                          const SizedBox(width: 8),
                          Text('address.setDefault'.tr(),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: ColorsManager.primaryColor)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 20, color: ColorsManager.errorFill),
                        const SizedBox(width: 8),
                        Text('common.delete'.tr(),
                            style: const TextStyle(
                                fontSize: 14,
                                color: ColorsManager.errorFill)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Address Details ──
          Text(
            address.fullAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                address.phone,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
