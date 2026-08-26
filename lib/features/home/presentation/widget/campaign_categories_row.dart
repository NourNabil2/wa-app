import 'package:fastway/core/theme/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/widgets/fastway_logo_fallback.dart' as fastway_logo;

// ─────────────────────────────────────────────────────────────────────────────
// Layout rule (same on every screen size — shape follows the crop, not the
// viewport):
//   - Every category has a WIDE image (10:3, desktop admin field) and a
//     SQUARE image (1:1, mobile admin field).
//   - If ALL categories have a square image: an odd total leads with one
//     full-width WIDE tile, then the rest are laid out as SQUARE pairs
//     (2 per row). An even total is all SQUARE pairs, no lead tile.
//   - If ANY category is missing its square image, we don't guess — every
//     category renders as a full-width WIDE tile, stacked.
// This keeps each tile's aspect ratio identical to the image it displays,
// so BoxFit.cover never has to crop or letterbox to make it fit.
// ─────────────────────────────────────────────────────────────────────────────
class CampaignCategoriesRow extends StatelessWidget {
  final List<CategoryEntity> categories;
  final void Function(CategoryEntity) onTap;
  final double? horizontalPadding;

  const CampaignCategoriesRow({
    super.key,
    required this.categories,
    required this.onTap,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final crossSpacing = 10.w;
    final runSpacing = 10.w;

    final bool allHaveSquare = categories.every(
      (c) => c.imageMobile != null && c.imageMobile!.isNotEmpty,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double fullWidth = constraints.maxWidth;
          if (fullWidth > 1200) fullWidth = 1200; // sane cap on ultra-wide desktops

          final List<Widget> rows = [];

          if (!allHaveSquare) {
            for (final cat in categories) {
              rows.add(_WideTile(
                cat: cat,
                locale: locale,
                isDark: isDark,
                width: fullWidth,
                onTap: () => onTap(cat),
              ));
            }
          } else {
            final bool hasLeadWide = categories.length.isOdd;
            final lead = hasLeadWide ? categories.first : null;
            final paired = hasLeadWide ? categories.skip(1).toList() : categories;

            if (lead != null) {
              rows.add(_WideTile(
                cat: lead,
                locale: locale,
                isDark: isDark,
                width: fullWidth,
                onTap: () => onTap(lead),
              ));
            }

            final squareSize = (fullWidth - crossSpacing) / 2;
            for (int i = 0; i < paired.length; i += 2) {
              final rowItems = paired.skip(i).take(2).toList();
              rows.add(Row(
                children: [
                  for (int j = 0; j < rowItems.length; j++) ...[
                    if (j > 0) SizedBox(width: crossSpacing),
                    _SquareTile(
                      cat: rowItems[j],
                      locale: locale,
                      isDark: isDark,
                      size: squareSize,
                      onTap: () => onTap(rowItems[j]),
                    ),
                  ],
                ],
              ));
            }
          }

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: fullWidth,
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    if (i > 0) SizedBox(height: runSpacing),
                    rows[i],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-width wide tile — 10:3, shows the desktop admin image.
// ─────────────────────────────────────────────────────────────────────────────
class _WideTile extends StatelessWidget {
  final CategoryEntity cat;
  final String locale;
  final bool isDark;
  final double width;
  final VoidCallback onTap;

  const _WideTile({
    required this.cat,
    required this.locale,
    required this.isDark,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (cat.image != null && cat.image!.isNotEmpty) ? cat.image! : cat.iconUrl;
    return SizedBox(
      width: width,
      height: width * 0.3, // 10:3
      child: _CampaignTile(
        cat: cat,
        locale: locale,
        isDark: isDark,
        imageUrl: imageUrl,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Square tile — 1:1, shows the mobile admin image.
// ─────────────────────────────────────────────────────────────────────────────
class _SquareTile extends StatelessWidget {
  final CategoryEntity cat;
  final String locale;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  const _SquareTile({
    required this.cat,
    required this.locale,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = cat.imageMobile!;
    return SizedBox(
      width: size,
      height: size,
      child: _CampaignTile(
        cat: cat,
        locale: locale,
        isDark: isDark,
        imageUrl: imageUrl,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared tile chrome — border, press state, image. The box's aspect ratio
// always matches the image passed in, so this is a plain BoxFit.cover with
// no letterboxing/blur fallback needed.
// ─────────────────────────────────────────────────────────────────────────────
class _CampaignTile extends StatefulWidget {
  final CategoryEntity cat;
  final String locale;
  final bool isDark;
  final String imageUrl;
  final VoidCallback onTap;

  const _CampaignTile({
    required this.cat,
    required this.locale,
    required this.isDark,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_CampaignTile> createState() => _CampaignTileState();
}

class _CampaignTileState extends State<_CampaignTile> {
  bool _pressed = false;

  Color _resolveAccent() {
    if (widget.cat.color != null && widget.cat.color!.isNotEmpty) {
      try {
        final hex = widget.cat.color!.replaceAll('#', '');
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return ColorsManager.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resolveAccent();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isDark ? ColorsManager.surfaceDarkCard : Colors.white,
          border: Border.all(
            color: _pressed
                ? accent.withValues(alpha: 0.4)
                : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => _GradientFill(accent: accent),
                errorWidget: (_, __, ___) => _GradientFill(accent: accent),
              )
            : _GradientFill(accent: accent),
      ),
    );
  }
}

// Simple gradient fill used as fallback / when no image
class _GradientFill extends StatelessWidget {
  final Color accent;
  const _GradientFill({required this.accent});

  @override
  Widget build(BuildContext context) => const fastway_logo.FastwayLogoFallback(
    ratio: fastway_logo.FallbackRatio.square,
  );
}
