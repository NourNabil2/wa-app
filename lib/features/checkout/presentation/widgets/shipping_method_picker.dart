// lib/features/checkout/presentation/widgets/shipping_method_picker.dart
//
// Full redesign: shows standard methods as selectable tiles + express as a
// locked row when is_disabled: true. Product strip shows ⚡ on express items.

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/widgets/marquee_widget.dart';

import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/widgets/sar_symbol.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../domain/entities/shipping_method_entity.dart';

// ─── Colours ─────────────────────────────────────────────────────────────────
const _kExpressColor  = ColorsManager.primary2Color;

// ─── Public widget ────────────────────────────────────────────────────────────
class ShippingMethodPicker extends StatelessWidget {
  final List<ShippingMethodEntity> methods;
  final String selectedId;
  final List<CheckoutItemEntity> items;
  final bool isExpressGroup;
  final String? errorItemName;
  final void Function(ShippingMethodEntity) onSelect;

  const ShippingMethodPicker({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.items,
    required this.onSelect,
    this.isExpressGroup = false,
    this.errorItemName,
  });

  @override
  Widget build(BuildContext context) {
    // If this is an express group, ONLY show the express method.
    // If this is a standard group, do NOT show the express method.
    final displayMethods = isExpressGroup 
        ? methods.where((m) => m.isExpressMethod).toList()
        : methods.where((m) => !m.isExpressMethod).toList();

    if (displayMethods.isEmpty) return const SizedBox.shrink();

    final selectedMethod = methods.cast<ShippingMethodEntity?>().firstWhere(
      (m) => m?.id == selectedId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Product strip ──────────────────────────────────────────────
        if (items.isNotEmpty) ...[
          _ProductStrip(items: items, errorItemName: errorItemName, isExpressGroup: isExpressGroup),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 12),
        ],

        // ── Horizontal Methods List ────────────────────────────────────
        if (!isExpressGroup)
          SizedBox(
            height: 90,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: displayMethods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = displayMethods[i];
                return _MethodTile(
                  method: m,
                  isSelected: selectedId == m.id,
                  isEnabled: !m.isDisabled,
                  onTap: () {
                    if (!m.isDisabled) onSelect(m);
                  },
                );
              },
            ),
          ),

        // ── Selected Method Note (Animated Accordion) ──────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: selectedMethod == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SelectedMethodNote(method: selectedMethod),
                ),
        ),
      ],
    );
  }
}

class _SelectedMethodNote extends StatelessWidget {
  final ShippingMethodEntity method;
  const _SelectedMethodNote({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method.isDisabled) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr   = Localizations.localeOf(context).languageCode == 'ar';

    // For standard methods this line is written entirely by the admin (shipping method →
    // "Delivery Statement", EN + AR) — nothing is auto-calculated, so a blank statement
    // simply leaves the price on its own. Express is synthetic (no admin row) and keeps
    // its own translated SLA line.
    final String estimateText = method.isExpressMethod
        ? 'checkout.expressSLA'.tr()
        : (isAr ? method.estimatedTimeAr : method.estimatedTime);

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
          if (estimateText.isNotEmpty) ...[
            Flexible(
              child: MarqueeWidget(
                child: Text(
                  estimateText,
                  style: const TextStyle(fontSize: 13, color: ColorsManager.defaultTextSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: ColorsManager.defaultTextSecondary, fontSize: 13)),
            const SizedBox(width: 8),
          ],
          if (method.isFree)
            Text('checkout.free'.tr(), style: const TextStyle(fontSize: 13, color: ColorsManager.primaryColor, fontWeight: FontWeight.bold))
          else
            SarText(
              price: method.cost.toStringAsFixed(0),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
            ),
          if (method.supportsColdChain && !method.isExpressMethod) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.ac_unit_rounded, size: 10, color: Color(0xFF0EA5E9)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Selectable method tile ───────────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  final ShippingMethodEntity method;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBorderColor = ColorsManager.primary2Color;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 75,
                  height: 75,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                  color: isSelected
                      ? ColorsManager.primary2Color.withValues(alpha: 0.05)
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? selectedBorderColor
                        : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: _ShippingLogo(method: method),
                ),
              ),
              if (method.supportsColdChain && !method.isExpressMethod)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A2236) : const Color(0xFFE0F4FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.ac_unit_rounded,
                      size: 12,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product strip with ⚡ badge on express items ─────────────────────────────
class _ProductStrip extends StatelessWidget {
  final List<CheckoutItemEntity> items;
  final String? errorItemName;
  final bool isExpressGroup;

  const _ProductStrip({required this.items, this.errorItemName, this.isExpressGroup = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.RTL;
    const maxVisible = 5;
    final visible = items.take(maxVisible).toList();
    final extra = items.length > maxVisible ? items.length - maxVisible : 0;

    return SizedBox(
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: !isRtl ? i * 42.0 : null,
              right: isRtl ? i * 42.0 : null,
              child: _ItemAvatar(
                item: visible[i],
                isDark: isDark,
                isError: errorItemName != null &&
                    visible[i].name.trim() == errorItemName!.trim(),
                isExpressGroup: isExpressGroup,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: !isRtl ? visible.length * 42.0 : null,
              right: isRtl ? visible.length * 42.0 : null,
              child: _ExtraBadge(count: extra, isDark: isDark),
            ),
        ],
      ),
    );
  }
}

class _ItemAvatar extends StatefulWidget {
  final CheckoutItemEntity item;
  final bool isDark;
  final bool isError;
  final bool isExpressGroup;

  const _ItemAvatar({required this.item, required this.isDark, required this.isError, this.isExpressGroup = false});

  @override
  State<_ItemAvatar> createState() => _ItemAvatarState();
}

class _ItemAvatarState extends State<_ItemAvatar> {
  OverlayEntry? _overlay;
  final _key = GlobalKey();

  void _showTooltip() {
    _removeTooltip();
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(builder: (ctx) {
      final item = widget.item;
      final isDark = widget.isDark;
      // Position above the avatar, centred
      const cardW = 180.0;
      double left = pos.dx + size.width / 2 - cardW / 2;
      double top  = pos.dy - 200;
      // Keep within screen
      final screenW = MediaQuery.of(ctx).size.width;
      left = left.clamp(8.0, screenW - cardW - 8);
      if (top < 8) top = pos.dy + size.height + 8;

      return Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: cardW,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: (item.isExpress && widget.isExpressGroup)
                      ? _kExpressColor.withValues(alpha: 0.4)
                      : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                  width: (item.isExpress && widget.isExpressGroup) ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 120,
                      width: cardW,
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                child: const Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              child: const Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey),
                            ),
                    ),
                  ),
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isExpress && widget.isExpressGroup)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kExpressColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text('Express', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            SarText(
                              price: item.price.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kExpressColor,
                              ),
                            ),
                            if (item.quantity > 1) ...[
                              const SizedBox(width: 4),
                              Text(
                                '×${item.quantity}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
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
    });
    Overlay.of(context).insert(_overlay!);
  }

  void _removeTooltip() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final isError = widget.isError;
    final hasProductId = item.productId != null && item.productId!.isNotEmpty;

    return GestureDetector(
      onTap: hasProductId
          ? () => AppNavigator.pushNamed(
                context,
                '${Routes.productDetails}/${SlugUtils.slugify(item.name, item.productId!)}',
              )
          : null,
      child: SafeMouseRegion(
        onEnter: (_) => _showTooltip(),
        onExit: (_) => _removeTooltip(),
        cursor: SystemMouseCursors.click,
        child: Stack(
          key: _key,
          clipBehavior: Clip.none,
          children: [
          // Circle image
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isError
                    ? Colors.redAccent
                    : ((item.isExpress && widget.isExpressGroup) ? _kExpressColor : (isDark ? ColorsManager.surfaceDarkCard : Colors.white)),
                width: isError ? 2.5 : ((item.isExpress && widget.isExpressGroup) ? 2 : 2.5),
              ),
              boxShadow: [
                if (isError)
                  const BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 1)
                else if (item.isExpress && widget.isExpressGroup)
                  BoxShadow(color: _kExpressColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)
                else
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: ClipOval(
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                    ),
            ),
          ),

          // ⚡ badge: item IS express
          if (item.isExpress && widget.isExpressGroup)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: _kExpressColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
              ),
            )
          // 🔵 badge: item is eligible but NOT express-toggled
          else if (item.isExpressEligible && widget.isExpressGroup)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
              ),
            )
          // Qty badge
          else if (item.quantity > 1)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: ColorsManager.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraBadge extends StatelessWidget {
  final int count;
  final bool isDark;
  const _ExtraBadge({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        border: Border.all(color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ─── Provider logo chip ───────────────────────────────────────────────────────
class _ShippingLogo extends StatelessWidget {
  final ShippingMethodEntity method;
  const _ShippingLogo({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method.isExpressMethod) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SvgPicture.asset(
          isAr ? 'assets/icons/shipping/express_ar.svg' : 'assets/icons/shipping/express.svg',
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
          errorWidget: (_, __, ___) => _fallbackLogo(method.provider),
        ),
      );
    }

    return _fallbackLogo(method.provider);
  }

  Widget _fallbackLogo(String provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Icon(
        _iconFor(provider),
        size: 28,
        color: ColorsManager.defaultTextSecondary,
      ),
    );
  }

  IconData _iconFor(String p) {
    switch (p.toLowerCase()) {
      case 'express': return Icons.bolt_rounded;
      default:        return Icons.local_shipping_outlined;
    }
  }
}
