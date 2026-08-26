// lib/core/widgets/static_content_page.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single content section
// ─────────────────────────────────────────────────────────────────────────────
class StaticSection {
  final String heading;
  final String headingAr;
  final String body;
  final String bodyAr;
  final IconData? icon;

  const StaticSection({
    required this.heading,
    required this.headingAr,
    required this.body,
    required this.bodyAr,
    this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main template widget
// ─────────────────────────────────────────────────────────────────────────────
class StaticContentPage extends StatelessWidget {
  final String title;
  final String titleAr;
  final String? subtitle;
  final String? subtitleAr;
  final IconData icon;
  final List<StaticSection> sections;
  final String? lastUpdated;

  const StaticContentPage({
    super.key,
    required this.title,
    required this.titleAr,
    this.subtitle,
    this.subtitleAr,
    required this.icon,
    required this.sections,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = isAr ? titleAr : title;
    final displaySubtitle = isAr ? (subtitleAr ?? subtitle) : subtitle;

    final screenW = MediaQuery.sizeOf(context).width;
    final isMobileWeb = screenW < 900;
    // On narrow screens use full width; on wide screens cap at 55%
    final contentMaxWidth = isMobileWeb ? screenW : screenW * 0.55;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Content ───────────────────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobileWeb ? 16.0 : 24.w,
                  vertical: isMobileWeb ? 24 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              AppNavigator.pushNamed(context, Routes.dashBoard);
                            }
                          },
                          child: Text(
                            'common.home'.tr(),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(color: ColorsManager.primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        Expanded(
                          child: Text(
                            displayTitle,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Selectable(
                      child: Text(
                        displayTitle,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: isMobileWeb ? 28 : 42,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    if (displaySubtitle != null) ...[
                      const SizedBox(height: 16),
                      Selectable(
                        child: Text(
                          displaySubtitle,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: isMobileWeb ? 15 : 18,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    if (lastUpdated != null) ...[
                      Row(
                        children: [
                          Icon(Icons.update_rounded,
                              size: 14,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'common.last_updated_prefix'.tr() + lastUpdated!,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Divider(color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 32),
                    ],

                    // Continuous Paragraph Sections
                    ...sections.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Selectable(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? s.headingAr : s.heading,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: isMobileWeb ? 18 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                                  height: 1.3,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isAr ? s.bodyAr : s.body,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: isMobileWeb ? 14 : 16,
                                  color: isDark ? Colors.white70 : ColorsManager.gray700,
                                  height: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // On web (any width) — wrap in SimpleWebShell (header + footer)
    // On native mobile — bare scaffold with back arrow
    if (kIsWeb) {
      return SimpleWebShell(content: content);
    }
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(displayTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF0A0A0C) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: content,
    );
  }
}
