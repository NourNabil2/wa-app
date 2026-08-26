import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/widgets/fastway_logo_fallback.dart' as fastway_logo;

class BrandHeroHeader extends StatelessWidget {
  final String brandName;
  final String? logoUrl;
  final String? country;
  final int total;
  final bool isDark;
  final bool isAr;

  const BrandHeroHeader({
    super.key,
    required this.brandName,
    this.logoUrl,
    this.country,
    required this.total,
    required this.isDark,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40), // space for app bar

            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252540) : Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: logoUrl != null && logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logoUrl!,
                        fit: BoxFit.contain,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => _LogoFallback(name: brandName),
                      )
                    : _LogoFallback(name: brandName),
              ),
            ),

            const SizedBox(height: 14),

            // Brand name
            Text(
              brandName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 6),

            // Badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeaderBadge(
                  icon: Icons.verified_rounded,
                  label: 'brand.original_badge'.tr(),
                  color: const Color(0xFF00BFA5),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _HeaderBadge({required this.icon, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, height: 1.2)),
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String name;
  const _LogoFallback({required this.name});
  @override
  Widget build(BuildContext context) {
    return const fastway_logo.FastwayLogoFallback(
      ratio: fastway_logo.FallbackRatio.square,
    );
  }
}
