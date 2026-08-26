import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/theme/text_theme.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_state.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fastway/core/utils/platform_reload.dart';
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileWebDrawer extends StatelessWidget {
  const MobileWebDrawer({super.key});

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.pop(context); // Close the drawer
    try {
      context.read<WebNavController>().navigateTo(tabIndex);
    } catch (_) {
      // Standalone mode fallback
      final route = switch (tabIndex) {
        0 => Routes.dashBoard,
        3 => Routes.profile,
        4 => Routes.orders,
        _ => null,
      };
      if (route != null) Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn  = context.read<UserCubit>().isLoggedIn;
    final userRepo    = UserRepository();
    final userName    = userRepo.currentUser?.name ?? '';

    final bgColor     = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final divColor    = isDark ? Colors.white10 : Colors.grey.shade200;

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Top branding bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 8),
              child: Row(
                children: [
                  Image.asset(isDark ? Assets.logoHeader : Assets.logoApp, width: 110, height: 40, fit: BoxFit.contain),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                  ),
                ],
              ),
            ),

            // ── Auth section ────────────────────────────────────────────────
            if (isLoggedIn)
              _LoggedInUserRow(userName: userName, isDark: isDark)
            else
              _GuestCtaRow(isDark: isDark),

            Divider(height: 1, color: divColor),

            // ── Nav items (scrollable) ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  _DrawerItem(
                    svgIcon: 'assets/icons/home-icon.svg',
                    title: 'dashboard.home'.tr(),
                    onTap: () => _navigateToTab(context, 0),
                    isDark: isDark,
                  ),


                  _DrawerItem(
                    faIcon: FontAwesomeIcons.solidNewspaper,
                    title: 'blog.title'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigator.pushNamed(context, Routes.blog);
                    },
                    isDark: isDark,
                  ),

                  if (isLoggedIn) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        'profile.account'.tr(),
                        style: TextStyle(
                          fontFamily: AppTextTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    _DrawerItem(
                      svgIcon: 'assets/icons/profile.svg',
                      title: 'dashboard.profile'.tr(),
                      onTap: () => _navigateToTab(context, 3),
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      faIcon: FontAwesomeIcons.solidBell,
                      title: 'profile.notifications'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigator.pushNamed(context, Routes.notifications);
                      },
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      faIcon: FontAwesomeIcons.solidStar,
                      title: 'dashboard.points'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigator.pushNamed(context, Routes.points);
                      },
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      faIcon: FontAwesomeIcons.solidHeart,
                      title: 'profile.favorites'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigator.pushNamed(context, Routes.wishlist);
                      },
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      faIcon: FontAwesomeIcons.bagShopping,
                      title: 'orders.title'.tr(),
                      onTap: () => _navigateToTab(context, 4),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            // ── Bottom — theme & language (non-scrollable, always visible) ──
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222224) : const Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: divColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme toggle (temporarily disabled)
                  /*
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, _) => ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: FaIcon(
                        isDark ? FontAwesomeIcons.solidSun : FontAwesomeIcons.solidMoon,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      title: Text(
                        isDark ? 'profile.theme.light'.tr() : 'profile.theme.dark'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () => context.read<SettingsCubit>().setTheme(isDark ? 'light' : 'dark'),
                    ),
                  ),
                  */
                  // Language toggle
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, settingsState) {
                      final isAr = settingsState.locale.languageCode == 'ar';
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: FaIcon(FontAwesomeIcons.language, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                        title: Text(
                          isAr ? 'English' : 'العربية',
                          style: TextStyle(fontFamily: AppTextTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                        ),
                        onTap: () async {
                          final next = isAr ? 'en' : 'ar';
                          await context.setLocale(Locale(next));
                          if (!context.mounted) return;
                          await context.read<SettingsCubit>().setLanguage(next);
                          await Future.delayed(const Duration(milliseconds: 150));
                          reloadApp();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Logged-in user summary ────────────────────────────────────────────────────
class _LoggedInUserRow extends StatelessWidget {
  final String userName;
  final bool isDark;
  const _LoggedInUserRow({required this.userName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final points = profileState is ProfileLoaded
            ? profileState.profile.rewardPoints.toString()
            : '0';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: ColorsManager.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontFamily: AppTextTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFFCB813)),
                        const SizedBox(width: 4),
                        Text(
                          '$points ${'dashboard.points'.tr()}',
                          style: TextStyle(fontFamily: AppTextTheme.fontFamily, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Guest CTA ─────────────────────────────────────────────────────────────────
class _GuestCtaRow extends StatelessWidget {
  final bool isDark;
  const _GuestCtaRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                AppNavigator.pushNamed(context, Routes.login);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsManager.primaryColor,
                side: const BorderSide(color: ColorsManager.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text('auth.login'.tr(), style: const TextStyle(fontFamily: AppTextTheme.fontFamily, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AppNavigator.pushNamed(context, Routes.signup);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: Text('auth.register'.tr(), style: const TextStyle(fontFamily: AppTextTheme.fontFamily, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer list item ──────────────────────────────────────────────────────────
class _DrawerItem extends StatefulWidget {
  final IconData? faIcon;
  final String? svgIcon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _DrawerItem({
    this.faIcon,
    this.svgIcon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const primary   = ColorsManager.primaryColor;
    final baseColor = widget.isDark ? Colors.white70 : Colors.black54;
    final color     = _hovered ? primary : baseColor;

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row: label ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          fontFamily: AppTextTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                          color: _hovered
                              ? primary
                              : (widget.isDark ? Colors.white : Colors.black87),
                        ),
                        child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.chevron_right_rounded, size: 18, color: primary),
                    ),
                  ],
                ),
              ),
              // ── Gradient underline ──
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 2,
                    width: _hovered ? constraints.maxWidth : 0,
                    decoration: BoxDecoration(
                      gradient: _hovered
                          ? LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.0),
                                primary.withValues(alpha: 0.5),
                                primary.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


