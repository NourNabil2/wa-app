import 'dart:ui';
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;


class ProductsRow extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function(String name, String id)? onTap;
  final VoidCallback? onShowAll; // kept for API compatibility only
  final double? horizontalPadding;

  const ProductsRow({
    super.key,
    required this.products,
    this.onTap,
    this.onShowAll,
    this.horizontalPadding,
  });

  @override
  State<ProductsRow> createState() => _ProductsRowState();
}

class _ProductsRowState extends State<ProductsRow> {
  late final ScrollController _sc;

  bool _canScrollBack    = false;
  bool _canScrollForward = true;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    _sc.addListener(_onScroll);
    // Delay first check until layout is done
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_sc.hasClients) return;
    final pos        = _sc.position;
    final canBack    = pos.pixels > 1;
    final canForward = pos.pixels < pos.maxScrollExtent - 1;
    if (canBack != _canScrollBack || canForward != _canScrollForward) {
      setState(() {
        _canScrollBack    = canBack;
        _canScrollForward = canForward;
      });
    }
  }

  @override
  void dispose() {
    _sc
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _scroll(double cardW, {required bool forward}) {
    if (!_sc.hasClients) return;
    final step   = (cardW + 12) * 2;
    final target = forward
        ? (_sc.offset + step).clamp(0.0, _sc.position.maxScrollExtent)
        : (_sc.offset - step).clamp(0.0, _sc.position.maxScrollExtent);
    _sc.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl  = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(builder: (context, constraints) {
      // Use the REAL widget width (not full screen) so 5 cards fit exactly
      final w       = constraints.maxWidth;
      final isSmallScreen = w < 800;
      final sidePad = widget.horizontalPadding ?? 16.0; // matches section title left/right padding if default
      final count   = isSmallScreen ? 2 : 7;
      final gaps    = (count - 1) * 12.0;
      final cardW   = ((w - sidePad * 2 - gaps) / (isSmallScreen ? 2.2 : 7)).clamp(100.0, 260.0);
      // One ratio for every platform and width. This used to be 0.50 on mobile
      // web / 0.54 native / 0.62 desktop, which is why the same rail cropped
      // the image differently on each.
      final rowH    = cardW / kProductCardAspectRatio;

    // ── Arrow button builder ──────────────────────────────────────────────────
    // With Stack + Positioned(left/right), slots are PHYSICALLY pinned:
    //   leftSlot  = always on screen LEFT  (both LTR & RTL)
    //   rightSlot = always on screen RIGHT (both LTR & RTL)
    //
    // In LTR: left=BACK,    right=FORWARD  → start: only right arrow visible
    // In RTL: left=FORWARD, right=BACK     → start: only left arrow visible
    //
    // Icons always point outward:
    //   leftSlot  → ‹ chevron_left   (points LEFT, away from content)
    //   rightSlot → › chevron_right  (points RIGHT, away from content)

    Widget arrowBtn({required bool isLeftSlot}) {
      final isForward = isRtl ? isLeftSlot : !isLeftSlot;
      final show      = (isForward ? _canScrollForward : _canScrollBack) && kIsWeb;

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: show ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !show,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _scroll(cardW, forward: isForward),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Directionality(
                // Force LTR so Flutter doesn't auto-mirror the chevron icons in RTL
                textDirection: TextDirection.ltr,
                child: Icon(
                  isLeftSlot ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: const Color(0xFF0D8D63),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: rowH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Scrollable cards — full width, padding matches section title
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.products.length, (i) {
                    final p    = widget.products[i];
                    final card = SizedBox(
                      width: cardW,
                      child: ProductCard(
                        productId: p.id,
                        name: p.localizedName(locale),
                        imageUrl: p.imageUrl,
                        price: p.price,
                        originalPrice: p.originalPrice,
                        rating: p.rating,
                        reviewCount: p.reviewCount,
                        isNew: p.isNew,
                        isAvailable: p.isAvailable,
                        isExpressEligible: p.isExpressEligible,
                        isFeatured: p.isFeatured,
                        stockWarning: p.stockWarning,
                        pointsToEarn: p.pointsToEarn,
                        brandName: p.localizedBrandName(context.locale.languageCode),
                        onTap: widget.onTap != null
                            ? () => widget.onTap!(p.localizedName(locale), p.id)
                            : null,
                      ),
                    );

                    if (i == widget.products.length - 1) return card;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [card, const SizedBox(width: 12)],
                    );
                  }),
                ),
              ),
            ),
          ),

          // Left arrow — OUTSIDE the widget area (negative offset)
          Positioned(
            left: -16,
            child: arrowBtn(isLeftSlot: true),
          ),

          // Right arrow — OUTSIDE the widget area (negative offset)
          Positioned(
            right: -16,
            child: arrowBtn(isLeftSlot: false),
          ),
        ],
      ),
    ); // end SizedBox
    }); // end LayoutBuilder
  }
}