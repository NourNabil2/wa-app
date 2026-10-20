// lib/core/layout/web_footer.dart

import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/assets.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final isNarrow = screenW < 900;
        final hPad = isNarrow ? 20.0 : screenW < 1600 ? 32.0 : screenW * 0.12;

        return Column(
          children: [
            // ── Solid primary-color top accent bar ──────────────────────────
            Container(height: 4, color: ColorsManager.primaryColor),

            // ── Main footer body ───────────────────────────────────────────
            Container(
              width: double.infinity,
              color: isDark ? ColorsManager.surfaceDarkElevated : const Color(0xFFF6F6F8),
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: isNarrow ? 20 : 32),
              child: isNarrow
                  ? _buildMobileFooter(context, isDark)
                  : _buildDesktopFooter(context, isDark),
            ),

            // ── Bottom bar (copyright + payment icons) ─────────────────────
            Container(
              width: double.infinity,
              color: isDark ? ColorsManager.surfaceDarkBase : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
              child: isNarrow
                  ? _buildMobileBottomBar(context, isDark)
                  : _buildDesktopBottomBar(context, isDark),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP — 5 columns
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopFooter(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: About Fastway (Logo + Text)
        Expanded(flex: 4, child: _AboutColumn(isDark: isDark)),
        const SizedBox(width: 32),

        // Column 2: Brand links (Fastway / نايس ون)
        Expanded(flex: 2, child: _BrandLinksColumn(isDark: isDark)),
        const SizedBox(width: 32),

        // Column 3: My Account
        Expanded(flex: 2, child: _AccountColumn(isDark: isDark)),
        const SizedBox(width: 32),

        // Column 4: Contact Us + Social
        Expanded(flex: 2, child: _ContactColumn(isDark: isDark)),
        const SizedBox(width: 32),

        // Column 5: Download App
        Expanded(flex: 2, child: _DownloadAppColumn(isDark: isDark)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — stacked layout
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileFooter(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AboutColumn(isDark: isDark),
        const SizedBox(height: 28),
        Divider(color: isDark ? Colors.white12 : Colors.grey.shade300),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _BrandLinksColumn(isDark: isDark)),
            Expanded(child: _AccountColumn(isDark: isDark)),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: isDark ? Colors.white12 : Colors.grey.shade300),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ContactColumn(isDark: isDark)),
            Expanded(child: _DownloadAppColumn(isDark: isDark)),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopBottomBar(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Row(
      children: [
        // Left: copyright + commercial/tax numbers
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'footer.copyright'.tr(namedArgs: {'year': '2026'}),
                style: TextStyle(fontSize: 12, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${('footer.commercial_reg').tr()} — 2102001493 — ${('footer.tax_number').tr()} — 311634949600003',
                style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),

        // Right: payment icons
        _PaymentIcons(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileBottomBar(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Column(
      children: [
        _PaymentIcons(),
        const SizedBox(height: 16),
        Text(
          'footer.copyright'.tr(namedArgs: {'year': '2026'}),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          '${('footer.commercial_reg').tr()} — 2102001493\n${('footer.tax_number').tr()} — 311634949600003',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLUMN 1: About Fastway (Logo + text)
// ═════════════════════════════════════════════════════════════════════════════
class _AboutColumn extends StatelessWidget {
  final bool isDark;
  const _AboutColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          isDark ? Assets.logoHeader : Assets.logoApp,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(
            'FASTWAY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : ColorsManager.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.locale.languageCode == 'ar' 
            ? 'انطلاقًا من إيمانها ودورها في تحسين جودة الحياة، تعمل شركة فاست واي على تقديم منتجات غذائية ومكملات عالية الجودة تدعم الرياضيين ومحبي اللياقة البدنية في تحقيق أهدافهم الصحية والبدنية.'
            : 'Driven by its belief and role in improving the quality of life, Fastway works to provide high-quality food products and supplements that support athletes and fitness enthusiasts in achieving their health and physical goals.',
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: null,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLUMN 2: Brand Links (Fastway info)
// ═════════════════════════════════════════════════════════════════════════════
class _BrandLinksColumn extends StatelessWidget {
  final bool isDark;
  const _BrandLinksColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _FooterLinkColumn(
      title: 'footer.fastway'.tr(),
      isDark: isDark,
      links: [
        _FooterLink(label: 'footer.blog'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.blog)),
        _FooterLink(label: 'footer.terms_and_conditions'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.terms)),
        _FooterLink(label: 'footer.return_policy'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.returnPolicy)),
        _FooterLink(label: 'footer.privacy_policy'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.privacy)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLUMN 3: Account Links
// ═════════════════════════════════════════════════════════════════════════════
class _AccountColumn extends StatelessWidget {
  final bool isDark;
  const _AccountColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _FooterLinkColumn(
      title: 'footer.my_account'.tr(),
      isDark: isDark,
      links: [
        _FooterLink(label: 'footer.account'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.profile)),
        _FooterLink(label: 'footer.orders'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.orders)),
        _FooterLink(label: 'footer.wishlist'.tr(), onTap: () => AppNavigator.pushNamed(context, Routes.wishlist)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLUMN 4: Contact Us + Social Icons
// ═════════════════════════════════════════════════════════════════════════════
class _ContactColumn extends StatelessWidget {
  final bool isDark;
  const _ContactColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'footer.contact_us'.tr(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),
        // Social icons — 2 rows of 4
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SocialIcon(icon: Icons.facebook_rounded, onTap: () => launchUrl(Uri.parse('https://facebook.com/fastway'))),
            _SocialIcon(icon: Icons.camera_alt_outlined, onTap: () => launchUrl(Uri.parse('https://instagram.com/fastway'))),
            _SocialIcon(icon: Icons.video_library_rounded, onTap: () => launchUrl(Uri.parse('https://youtube.com/fastway'))),
            _SocialIcon(icon: Icons.tag_rounded, onTap: () => launchUrl(Uri.parse('https://snapchat.com/add/fastway'))),
            _SocialIcon(icon: Icons.whatshot_rounded, onTap: () => launchUrl(Uri.parse('https://wa.me/966123456789'))),
            _SocialIcon(icon: Icons.music_note_rounded, onTap: () => launchUrl(Uri.parse('https://tiktok.com/@fastway'))),
            _SocialIcon(icon: Icons.link_rounded, onTap: () => launchUrl(Uri.parse('https://linkedin.com/company/fastway'))),
            _SocialIcon(icon: Icons.close_rounded, onTap: () => launchUrl(Uri.parse('https://x.com/fastway'))),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLUMN 5: Download App
// ═════════════════════════════════════════════════════════════════════════════
class _DownloadAppColumn extends StatelessWidget {
  final bool isDark;
  const _DownloadAppColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'footer.download_app'.tr(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final badgeWidth = (constraints.maxWidth * 0.85).clamp(100.0, 150.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.app.wa')),
                  child: SizedBox(
                    width: badgeWidth,
                    height: 42,
                    child: SvgPicture.asset(
                      'assets/icons/footericons/play-store.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://apps.apple.com/app/fastway')),
                  child: SizedBox(
                    width: badgeWidth,
                    height: 42,
                    child: SvgPicture.asset(
                      'assets/icons/footericons/app-store.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED: Footer Link Column
// ═════════════════════════════════════════════════════════════════════════════
class _FooterLink {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});
}

class _FooterLinkColumn extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<_FooterLink> links;

  const _FooterLinkColumn({required this.title, required this.isDark, required this.links});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => _AnimatedFooterLink(label: link.label, onTap: link.onTap, isDark: isDark)),
      ],
    );
  }
}

class _AnimatedFooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _AnimatedFooterLink({required this.label, required this.onTap, required this.isDark});

  @override
  State<_AnimatedFooterLink> createState() => _AnimatedFooterLinkState();
}

class _AnimatedFooterLinkState extends State<_AnimatedFooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeMouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
              color: _hovered
                  ? const Color(0xFF4CAF50)
                  : (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SOCIAL ICON
// ═════════════════════════════════════════════════════════════════════════════
class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeMouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF4CAF50)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF4CAF50)
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 8)]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAYMENT ICONS ROW
// ═════════════════════════════════════════════════════════════════════════════
class _PaymentIcons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SvgPicture.asset('assets/icons/footericons/apple-pay.svg', height: 28, fit: BoxFit.contain),
        SvgPicture.asset('assets/icons/footericons/mada.svg', height: 28, fit: BoxFit.contain),
        SvgPicture.asset('assets/icons/footericons/master-card.svg', height: 28, fit: BoxFit.contain),
        SvgPicture.asset('assets/icons/footericons/visa.svg', height: 28, fit: BoxFit.contain),
        SvgPicture.asset('assets/icons/footericons/tabby.svg', height: 28, fit: BoxFit.contain),
        Image.asset('assets/icons/footericons/tamara.png', height: 28, fit: BoxFit.contain),
        Image.asset('assets/icons/footericons/stc-bank.png', height: 28, fit: BoxFit.contain),
        SvgPicture.asset('assets/icons/footericons/google-pay.svg', height: 28, fit: BoxFit.contain),
      ],
    );
  }
}
