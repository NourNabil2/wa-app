import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastway/core/widgets/safe_mouse_region.dart';
// lib/features/profile/presentation/view/profile_screen.dart
//
// CHANGES vs original:
//   • Removed the `if (isWeb) return WebShell(...)` wrapper.
//     The Dashboard's IndexedStack now provides the shell; nesting a second
//     WebShell caused a duplicate sidebar + header bug.
//   • _WebProfileLayout now accepts an `onPointsNavTap` callback so the
//     "reward points" stat card uses the SPA IndexedStack (index 1) instead
//     of Navigator.pushNamed(Routes.points).
//   • _ProfileBody accepts and forwards the same callback.

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/platform_reload.dart';

import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/view/addresses_screen.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_state.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_theme_tile.dart';
import '../widgets/profile_logout_button.dart';
import 'edit_profile_sheet.dart';
import 'change_password_sheet.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../../../core/widgets/web_breadcrumb.dart';

class ProfileScreen extends StatefulWidget {
  /// true  → inside Dashboard IndexedStack  (WebShell owns the Scaffold)
  /// false → standalone route               (SimpleWebShell owns the Scaffold)
  final bool isTab;

  /// Called when the user taps "reward points" on web.
  final VoidCallback? onPointsNavTap;

  const ProfileScreen({super.key, this.isTab = false, this.onPointsNavTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Only load profile for authenticated users.
    // Calling this as a guest always produces a 401, which cascades into
    // widget-tree assertion failures in the BlocListener.
    if (context.read<UserCubit>().isLoggedIn) {
      context.read<ProfileCubit>().loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profileBody = _ProfileBody(
      onLogout: () => _showLogoutDialog(context),
      onDeleteAccount: () => _showDeleteAccountDialog(context),
      onPointsNavTap: widget.onPointsNavTap,
    );

    // Standalone web route → SimpleWebShell owns the Scaffold; we pass body only
    if (kIsWeb && !widget.isTab) {
      return SimpleWebShell(content: profileBody);
    }

    // Dashboard tab OR mobile → own the Scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: profileBody,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialog.warning(
      context: context,
      title: 'profile.logout'.tr(),
      message: 'profile.logoutConfirm'.tr(),
      confirmText: 'profile.logoutConfirmBtn'.tr(),
      onConfirm: () => context.read<ProfileCubit>().logout(),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    AppDialog.warning(
      context: context,
      title: 'profile.deleteAccount'.tr(),
      message: 'profile.deleteAccountConfirm'.tr(),
      confirmText: 'profile.delete'.tr(),
      onConfirm: () => context.read<ProfileCubit>().deleteAccount(),
    );
  }
}

// ── Shared body ───────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onPointsNavTap;

  const _ProfileBody({required this.onLogout, required this.onDeleteAccount, this.onPointsNavTap});

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;

    // Capture at build time — safe to use inside the async BlocListener
    // callback without touching context again (avoids deactivated-ancestor crash).
    final userCubit = context.read<UserCubit>();

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (ctx, state) {
        if (state is ProfileLoggedOut) {
          Navigator.of(ctx).pushNamedAndRemoveUntil(Routes.auth, (_) => false);
        }
        if (state is ProfileError) {
          // Use the pre-captured cubit — never touches ctx after async gap.
          if (userCubit.isLoggedIn && ctx.mounted) {
            CustomSnackBar.show(
              ctx,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        }
      },
      builder: (context, state) {
        final isLoggedIn = userCubit.isLoggedIn;

        // For guests, we don't have profile data, but we can still access settings via SettingsCubit.
        final settings = state is ProfileLoaded
            ? state.settings
            : context.read<SettingsCubit>().state;

        if (isLoggedIn &&
            (state is ProfileLoading || state is ProfileInitial)) {
          return const Center(child: ProfileSkeleton());
        }

        final profile = state is ProfileLoaded ? state.profile : null;

        pointsTap() => AppNavigator.pushNamed(context, Routes.points);

        if (isWeb) {
          return _WebProfileLayout(
            profile: profile,
            settings: settings,
            onLogout: onLogout,
            onDeleteAccount: onDeleteAccount,
            onPointsTap: pointsTap,
            isGuest: !isLoggedIn,
          );
        }

        return _MobileProfileLayout(
          profile: profile,
          settings: settings,
          onLogout: onLogout,
          onDeleteAccount: onDeleteAccount,
          isGuest: !isLoggedIn,
        );
      },
    );
  }
}

// ── Web Layout ────────────────────────────────────────────────────────────────

class _WebProfileLayout extends StatelessWidget {
  final dynamic profile;
  final dynamic settings;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onPointsTap;
  final bool isGuest;

  const _WebProfileLayout({
    required this.profile,
    required this.settings,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onPointsTap,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final hPad = isNarrow ? 16.0 : 48.0;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(hPad, isNarrow ? 24 : 100, hPad, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WebBreadcrumb(
                      isDark: isDark,
                      labels: ['dashboard.home'.tr(), 'footer.account'.tr()],
                      onTaps: [
                        () => AppNavigator.pushNamed(context, Routes.dashBoard),
                        null,
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Page title ────────────────────────────────────────────
                    Text(
                      'profile.personalData'.tr(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (isNarrow)
                      // ── Narrow: centered single column ────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isGuest) ...[
                            Center(
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 480),
                                    child: _buildGuestHeader(context))),
                            const SizedBox(height: 24),
                          ] else ...[
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: _WebProfileCard(
                                    profile: profile, isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: _WebStatsCard(
                                  totalOrders: profile.totalOrders,
                                  rewardPoints: profile.rewardPoints,
                                  isDark: isDark,
                                  onPointsTap: onPointsTap,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          ..._menuSections(context, isDark, isGuest),
                        ],
                      )
                    else
                      // ── Wide: two-column layout ───────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 260,
                            child: Column(
                              children: [
                                if (isGuest)
                                  _buildGuestHeader(context)
                                else ...[
                                  _WebProfileCard(
                                      profile: profile, isDark: isDark),
                                  const SizedBox(height: 16),
                                  _WebStatsCard(
                                    totalOrders: profile.totalOrders,
                                    rewardPoints: profile.rewardPoints,
                                    isDark: isDark,
                                    onPointsTap: onPointsTap,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: _menuSections(context, isDark, isGuest),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_circle, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('auth.guard.title'.tr(),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => AppNavigator.pushNamed(context, Routes.login),
              child: Text('auth.guard.login'.tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _menuSections(BuildContext context, bool isDark, bool isGuest) {
    return [
      if (!isGuest) ...[
        _WebMenuCard(
          title: 'profile.account'.tr(),
          isDark: isDark,
          items: [
            _WebMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'profile.personalData'.tr(),
              isDark: isDark,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                          value: context.read<ProfileCubit>(),
                          child: EditProfileScreen(profile: profile)))),
            ),
            _WebMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'profile.changePassword'.tr(),
              isDark: isDark,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                          value: context.read<ProfileCubit>(),
                          child: const ChangePasswordScreen()))),
            ),
            _WebMenuItem(
              icon: Icons.location_on_outlined,
              label: 'profile.savedAddresses'.tr(),
              isDark: isDark,
              onTap: () => AppNavigator.pushNamed(context, Routes.addresses),
            ),
            _WebMenuItem(
              icon: Icons.monetization_on_outlined,
              label: 'dashboard.points'.tr(),
              isDark: isDark,
              onTap: () => AppNavigator.pushNamed(context, Routes.points),
            ),
            _WebMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'wallet.title'.tr(),
              isDark: isDark,
              onTap: () => AppNavigator.pushNamed(context, Routes.wallet),
            ),
            _WebMenuItem(
              icon: Icons.star_border_rounded,
              label: 'profile.favorites'.tr(),
              isDark: isDark,
              onTap: () => AppNavigator.pushNamed(context, Routes.wishlist),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      _WebMenuCard(
        title: 'profile.settings'.tr(),
        isDark: isDark,
        items: [
          _WebMenuItem(
            icon: Icons.article_outlined,
            label: 'blog.title'.tr(),
            isDark: isDark,
            onTap: () => AppNavigator.pushNamed(context, Routes.blog),
          ),
          if (!isGuest)
            _WebMenuItem(
              icon: Icons.notifications_none_rounded,
              label: 'profile.notifications'.tr(),
              isDark: isDark,
              onTap: () =>
                  AppNavigator.pushNamed(context, Routes.notifications),
            ),
          /*
          _WebMenuItem(
            icon: Icons.brightness_6_outlined,
            label: 'profile.theme.label'.tr(),
            isDark: isDark,
            trailing: Text(
              _themeLabel(settings.themeMode.toString().split('.').last, context),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            onTap: () =>
                _showWebThemeSheet(context, settings),
          ),
          */
          _WebMenuItem(
            icon: Icons.language_rounded,
            label: 'profile.language'.tr(),
            isDark: isDark,
            trailing: Text(
              context.locale.languageCode == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _showLanguageSheet(context, settings),
          ),

        ],
      ),
      const SizedBox(height: 12),
      _WebMenuCard(
        title: 'profile.support'.tr(),
        isDark: isDark,
        items: [
          _WebMenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'profile.privacyPolicy'.tr(),
            isDark: isDark,
            onTap: () => launchUrl(Uri.parse('https://web.fastwayprotein.com/privacy')),
          ),
          _WebMenuItem(
            icon: Icons.description_outlined,
            label: 'profile.termsAndConditions'.tr(),
            isDark: isDark,
            onTap: () => launchUrl(Uri.parse('https://web.fastwayprotein.com/terms')),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (!isGuest) ...[
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: ColorsManager.errorSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: ColorsManager.errorFill, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'profile.logout'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.errorFill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onDeleteAccount,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: ColorsManager.errorFill),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline_rounded,
                      color: ColorsManager.errorFill, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'profile.deleteAccount'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.errorFill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }
} // end _WebProfileLayout

// ── Theme helpers (used by both web and mobile layouts) ───────────────────────

String _themeLabel(String themeMode, BuildContext context) {
  switch (themeMode) {
    case 'dark':
      return 'profile.theme.dark'.tr();
    case 'light':
      return 'profile.theme.light'.tr();
    default:
      return 'profile.theme.system'.tr();
  }
}

/// Shows a bottom-sheet theme picker that drives [SettingsCubit] (MaterialApp)
/// AND [ProfileCubit] (backend persistence) in sync.
void _showWebThemeSheet(BuildContext context, dynamic settings) {
  final settingsCubit = context.read<SettingsCubit>();
  final profileCubit = context.read<ProfileCubit>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.zero),
    ),
    builder: (ctx) {
      final options = [
        ('profile.theme.light'.tr(), Icons.wb_sunny_outlined, 'light'),
        ('profile.theme.dark'.tr(), Icons.nightlight_round, 'dark'),
        ('profile.theme.system'.tr(), Icons.brightness_auto_outlined, 'system'),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Text(
              'profile.theme.choose'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) {
              final selected = settings.themeMode == o.$3;
              return ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  // ✅ SettingsCubit drives MaterialApp ThemeMode immediately
                  settingsCubit.setTheme(o.$3);
                  // ✅ ProfileCubit persists to backend/prefs
                  profileCubit.updateTheme(o.$3);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Icon(o.$2,
                    color: selected
                        ? ColorsManager.primaryColor
                        : Theme.of(ctx).colorScheme.onSurfaceVariant),
                title: Text(o.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? ColorsManager.primaryColor
                          : Theme.of(ctx).colorScheme.onSurface,
                    )),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded,
                        color: ColorsManager.primaryColor, size: 20)
                    : null,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void _showLanguageSheet(BuildContext context, dynamic settings) {
  showModalBottomSheet(
    context: context,
    backgroundColor:
        Theme.of(context).cardColor, // 👈 إضافة خلفية تتجاوب مع الثيم
    shape: const RoundedRectangleBorder(
      // 👈 تحسين الحواف
      borderRadius: BorderRadius.vertical(top: Radius.zero),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangOption(
            label: 'العربية',
            code: 'ar',
            selected: context.locale.languageCode == 'ar',
            onTap: () {
              Navigator.pop(ctx);
              _applyLang(context, 'ar');
            },
          ),
          _LangOption(
            label: 'English',
            code: 'en',
            selected: context.locale.languageCode == 'en',
            onTap: () {
              Navigator.pop(ctx);
              _applyLang(context, 'en');
            },
          ),
        ],
      ),
    ),
  );
}

void _applyLang(BuildContext context, String code) async {
  await context.setLocale(Locale(code));
  if (!context.mounted) return;
  await context.read<SettingsCubit>().setLanguage(code);
  context.read<ProfileCubit>().updateLanguage(code);

  await Future.delayed(const Duration(milliseconds: 150));
  reloadApp();
}

// ── Mobile Layout ─────────────────────────────────────────────────────────────

class _MobileProfileLayout extends StatelessWidget {
  final dynamic profile;
  final dynamic settings;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final bool isGuest;

  const _MobileProfileLayout({
    required this.profile,
    required this.settings,
    required this.onLogout,
    required this.onDeleteAccount,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (isGuest) ...[
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.account_circle,
                      size: 80.r, color: Colors.grey.shade400),
                  SizedBox(height: 16.h),
                  Text('auth.guard.title'.tr(),
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () =>
                          AppNavigator.pushNamed(context, Routes.login),
                      child: Text('auth.guard.login'.tr(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        ] else ...[
          SliverToBoxAdapter(child: ProfileHeader(profile: profile)),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: ProfileStatsRow(
              totalOrders: profile.totalOrders,
              rewardPoints: profile.rewardPoints,
              onPointsTap: () => AppNavigator.pushNamed(context, Routes.points),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
        /*
        SliverToBoxAdapter(
          child: ProfileThemeTile(
            currentTheme: settings.themeMode.toString().split('.').last,
            onChanged: (theme) =>
                context.read<ProfileCubit>().updateTheme(theme),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        */
        if (!isGuest)
          SliverToBoxAdapter(
            child: ProfileMenuSection(
              title: 'profile.account'.tr(),
              items: [
                ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'profile.personalData'.tr(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ProfileCubit>(),
                        child: EditProfileScreen(profile: profile),
                      ),
                    ),
                  ),
                ),
                ProfileMenuItem(
                  icon: Icons.list_alt,
                  label: 'dashboard.orders'.tr(),
                  onTap: () => AppNavigator.pushNamed(context, Routes.orders),
                ),
                ProfileMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'profile.changePassword'.tr(),
                  onTap: () => ChangePasswordSheet.show(context),
                ),
                ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'profile.savedAddresses'.tr(),
                  onTap: () => AddressesScreen.show(context),
                ),
                ProfileMenuItem(
                  icon: Icons.monetization_on_outlined,
                  label: 'dashboard.points'.tr(),
                  onTap: () => AppNavigator.pushNamed(context, Routes.points),
                ),
                ProfileMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'wallet.title'.tr(),
                  onTap: () => AppNavigator.pushNamed(context, Routes.wallet),
                ),
                ProfileMenuItem(
                  icon: Icons.star_border_rounded,
                  label: 'profile.favorites'.tr(),
                  onTap: () => AppNavigator.pushNamed(context, Routes.wishlist),
                ),
              ],
            ),
          ),
        if (!isGuest) SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        SliverToBoxAdapter(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return ProfileMenuSection(
                title: 'profile.settings'.tr(),
                items: [
                  ProfileMenuItem(
                    icon: Icons.article_outlined,
                    label: 'blog.title'.tr(),
                    onTap: () => AppNavigator.pushNamed(context, Routes.blog),
                  ),
                  if (!isGuest)
                    ProfileMenuItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'profile.notifications'.tr(),
                      onTap: () =>
                          AppNavigator.pushNamed(context, Routes.notifications),
                    ),
                  ProfileMenuItem(
                    icon: Icons.language_rounded,
                    label: 'profile.language'.tr(),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.locale.languageCode == 'ar'
                              ? 'العربية'
                              : 'English',
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.grey.shade500),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_left,
                            size: 20.r, color: Colors.grey.shade400),
                      ],
                    ),
                    onTap: () => _showLanguageSheet(context, settings),
                  ),
                  if (!isGuest)

                  if (!kIsWeb && !isGuest) ...[
                    ProfileMenuItem(
                      icon: Icons.fingerprint,
                      label: 'biometric.enable'.tr(),
                      subtitle: 'biometric.auth_reason'.tr(),
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: settingsState.isBiometricLockEnabled,
                          activeColor: ColorsManager.primary2Color,
                          onChanged: (val) {
                            context
                                .read<SettingsCubit>()
                                .setBiometricLockEnabled(val);
                          },
                        ),
                      ),
                      onTap: () {
                        context.read<SettingsCubit>().setBiometricLockEnabled(
                            !settingsState.isBiometricLockEnabled);
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.fingerprint,
                      label: 'biometric.login_enable'.tr(),
                      subtitle: 'biometric.login_auth_reason'.tr(),
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: settingsState.isBiometricLoginEnabled,
                          activeColor: ColorsManager.primary2Color,
                          onChanged: (val) {
                            context
                                .read<SettingsCubit>()
                                .setBiometricLoginEnabled(val);
                          },
                        ),
                      ),
                      onTap: () {
                        context.read<SettingsCubit>().setBiometricLoginEnabled(
                            !settingsState.isBiometricLoginEnabled);
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileMenuSection(
            title: 'profile.support'.tr(),
            items: [
              ProfileMenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'profile.privacyPolicy'.tr(),
                onTap: () =>
                    launchUrl(Uri.parse('https://web.fastwayprotein.com/privacy')),
              ),
              ProfileMenuItem(
                icon: Icons.description_outlined,
                label: 'profile.termsAndConditions'.tr(),
                onTap: () => launchUrl(Uri.parse('https://web.fastwayprotein.com/terms')),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        if (!isGuest) ...[
          SliverToBoxAdapter(
            child: ProfileLogoutButton(isLoading: false, onTap: onLogout),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: onDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.errorSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'profile.deleteAccount'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorsManager.errorFill,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.delete_outline_rounded,
                          color: ColorsManager.errorFill,
                          size: 20.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }
}

// ── Web sub-widgets ───────────────────────────────────────────────────────────

class _WebProfileCard extends StatelessWidget {
  final dynamic profile;
  final bool isDark;
  const _WebProfileCard({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaceColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor:
                    ColorsManager.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  profile.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ColorsManager.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.name ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email ?? '',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          // Loyalty tier badge — only when the customer actually has a tier and
          // the store has tiers switched on (the API sends null otherwise).
          Builder(builder: (context) {
            final label = profile.tierLabel(context.locale.languageCode == 'ar');
            if (label == null || label.isEmpty) return const SizedBox.shrink();

            final accent = _hexColor(profile.tierColor) ?? cs.primary;
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 14, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WebStatsCard extends StatelessWidget {
  final int totalOrders;
  final int rewardPoints;
  final bool isDark;
  final VoidCallback onPointsTap;

  const _WebStatsCard({
    required this.totalOrders,
    required this.rewardPoints,
    required this.isDark,
    required this.onPointsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaceColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'profile.total_orders'.tr(),
              value: '$totalOrders',
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: SafeMouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onPointsTap, // 👈 SPA-aware
                child: _StatItem(
                  label: 'profile.reward_points'.tr(),
                  value: '$rewardPoints',
                  isDark: isDark,
                  accent: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool accent;

  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accent
                ? ColorsManager.primaryColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WebMenuCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;

  const _WebMenuCard(
      {required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _WebMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback onTap;

  const _WebMenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.trailing,
    required this.onTap,
  });

  @override
  State<_WebMenuItem> createState() => _WebMenuItemState();
}

class _WebMenuItemState extends State<_WebMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? cs.onSurface.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon,
                    size: 16, color: ColorsManager.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              widget.trailing ??
                  Icon(Icons.chevron_right,
                      size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label, code;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected
              ? ColorsManager.primaryColor
              : Theme.of(context)
                  .colorScheme
                  .onSurface, // 👈 تغيير اللون الثابت
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded,
              color: ColorsManager.primaryColor, size: 18)
          : null,
    );
  }
}

class _BiometricToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _BiometricToggleCard({
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeDark = ColorsManager.primaryColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: InkWell(
          onTap: () => onChanged(!isEnabled),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: isEnabled,
                    onChanged: onChanged,
                    activeColor: themeDark,
                    activeTrackColor: themeDark.withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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

/// Parse an admin-configured tier colour ("#C0A062") into a Color.
/// Returns null on anything unparseable so callers fall back to the theme.
Color? _hexColor(String? value) {
  if (value == null) return null;
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}
