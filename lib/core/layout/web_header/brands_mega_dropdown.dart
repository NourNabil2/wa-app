import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';

class BrandsMegaDropdown extends StatelessWidget {
  final List brands;
  final bool isDark;
  final double megaWidth;
  final void Function(dynamic brand) onNavigate;

  const BrandsMegaDropdown({
    super.key,
    required this.brands,
    required this.isDark,
    required this.megaWidth,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor     = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final clampedWidth = megaWidth.clamp(400.0, 1200.0);

    return Material(
      elevation:    12,
      shadowColor:  Colors.black.withValues(alpha: 0.18),
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      color:        bgColor,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: clampedWidth,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (brands.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.diamond_outlined, size: 48,
                        color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'dashboard.no_categories'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ...brands.map<Widget>((brand) {
                        return BrandMegaCard(
                          brand: brand,
                          isDark: isDark,
                          onTap: () => onNavigate(brand),
                        );
                      }),
                      _ViewMoreBrandsCard(
                        isDark: isDark,
                        onTap: () => onNavigate(null), // null indicates "View More"
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewMoreBrandsCard extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ViewMoreBrandsCard({required this.isDark, required this.onTap});

  @override
  State<_ViewMoreBrandsCard> createState() => _ViewMoreBrandsCardState();
}

class _ViewMoreBrandsCardState extends State<_ViewMoreBrandsCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_hovered ? const Color(0xFF2A2A2C) : const Color(0xFF232325))
                : (_hovered ? Colors.white : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? ColorsManager.primaryColor.withValues(alpha: 0.4)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _hovered
                      ? ColorsManager.primaryColor
                      : (widget.isDark ? Colors.white54 : Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'home.view_more_brands'.tr(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: _hovered
                      ? ColorsManager.primaryColor
                      : (widget.isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandMegaCard extends StatefulWidget {
  final dynamic brand;
  final bool isDark;
  final VoidCallback onTap;

  const BrandMegaCard({
    super.key,
    required this.brand,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<BrandMegaCard> createState() => _BrandMegaCardState();
}

class _BrandMegaCardState extends State<BrandMegaCard> {
  bool _hovered = false;

  String get _initials {
    final parts = (widget.brand.name as String).trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final name = parts[0];
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'ar' ? (widget.brand.nameAr ?? widget.brand.name) : widget.brand.name;
    final logoUrl = widget.brand.logoUrl as String;
    final hasLogo = logoUrl.isNotEmpty;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_hovered ? const Color(0xFF2A2A2C) : const Color(0xFF232325))
                : (_hovered ? Colors.white : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? ColorsManager.primaryColor.withValues(alpha: 0.4)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasLogo
                      ? CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 64,
                          height: 64,
                          memCacheWidth: 128,
                          memCacheHeight: 128,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ColorsManager.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ColorsManager.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ColorsManager.primaryColor,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _hovered ? FontWeight.w700 : FontWeight.w600,
                  color: _hovered
                      ? ColorsManager.primaryColor
                      : (widget.isDark ? Colors.white70 : Colors.black87),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
