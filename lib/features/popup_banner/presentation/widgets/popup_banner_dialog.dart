import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/popup_banner/domain/entities/popup_banner_entity.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showPopupBannerDialog(BuildContext context, PopupBannerEntity banner) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'popup_ad',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (context, animation, _, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, _, __) => _PopupBannerDialog(banner: banner),
  );
}

class _PopupBannerDialog extends StatelessWidget {
  final PopupBannerEntity banner;
  const _PopupBannerDialog({required this.banner});

  Future<void> _openLink() async {
    if (banner.link == null || banner.link!.isEmpty) return;
    final uri = Uri.tryParse(banner.link!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr     = context.locale.languageCode == 'ar';
    final title    = isAr ? (banner.titleAr ?? banner.title) : banner.title;
    final hasLink  = banner.link != null && banner.link!.isNotEmpty;
    final hasTitle = title != null && title.isNotEmpty;

    final maxWidth = MediaQuery.sizeOf(context).width * 0.85;
    final dialogWidth = maxWidth.clamp(260.0, 420.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main card ─────────────────────────────────────
            Container(
              width: dialogWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Image ──────────────────────────────────
                  GestureDetector(
                    onTap: hasLink ? _openLink : null,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorsManager.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),

            // ── Close button ───────────────────────────────────
            Positioned(
              top: -14,
              right: -14,
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF333333)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
