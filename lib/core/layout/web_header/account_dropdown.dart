import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountDropdown extends StatefulWidget {
  final bool isLoggedIn;
  final String userName;
  final bool isDark;

  const AccountDropdown({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.isDark,
  });

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _navigateToTab(int tabIndex) {
    _closeDropdown();
    try {
      final ctrl = context.read<WebNavController>();
      ctrl.navigateTo(tabIndex);
    } catch (_) {
      final route = switch (tabIndex) {
        3 => Routes.profile,
        4 => Routes.orders,
        _ => null,
      };
      if (route != null) Navigator.pushNamed(context, route);
    }
  }

  void _toggleDropdown() {
    if (!widget.isLoggedIn) {
      AppNavigator.pushNamed(context, Routes.login);
      return;
    }

    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    setState(() => _isOpen = true);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() => _isOpen = false);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size buttonSize = renderBox.size;
    final Offset buttonOffset = renderBox.localToGlobal(Offset.zero);

    const double dropdownWidth = 280;
    const double dropdownMargin = 8;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;

    final double top = buttonOffset.dy + buttonSize.height;
    double left = buttonOffset.dx + buttonSize.width - dropdownWidth;

    if (left < dropdownMargin) left = dropdownMargin;
    if (left + dropdownWidth > screenWidth - dropdownMargin) {
      left = screenWidth - dropdownWidth - dropdownMargin;
    }

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight - top - dropdownMargin,
                ),
                child: Container(
                  width: dropdownWidth,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? ColorsManager.surfaceDarkHeader
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildDropdownContent(),
                ),
              ),
            ),
          ),
          // Bridge to hide the border under the button
          Positioned(
            left: buttonOffset.dx + 1,
            top: top,
            width: buttonSize.width - 2,
            height: 2,
            child: Container(
              color: widget.isDark ? ColorsManager.surfaceDarkHeader : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ??
                  (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ??
                      (widget.isDark ? Colors.white70 : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildDropdownContent() {
    if (!widget.isLoggedIn) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownActionButton(
              icon: Icons.login_rounded,
              label: 'auth.login'.tr(),
              accent: true,
              onTap: () {
                _closeDropdown();
                AppNavigator.pushNamed(context, Routes.login);
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildThemeToggle(),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.settings,
          label: 'profile.settings'.tr(),
          onTap: () => _navigateToTab(3),
        ),
        _buildMenuItem(
          icon: Icons.stars_rounded,
          label: 'dashboard.points'.tr(),
          onTap: () {
            _closeDropdown();
            AppNavigator.pushNamed(context, Routes.points);
          },
        ),
        _buildMenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'dashboard.orders'.tr(),
          onTap: () => _navigateToTab(4),
        ),
        const Divider(height: 1, thickness: 1),
        _buildThemeToggle(),
        const Divider(height: 1, thickness: 1),
        _buildMenuItem(
          icon: Icons.logout_rounded,
          label: 'profile.logout'.tr(),
          color: Colors.red[400],
          onTap: () {
            _closeDropdown();
            context.read<ProfileCubit>().logout();
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeToggle() {
    // Theme toggle (temporarily disabled)
    return const SizedBox.shrink();
    /*
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ThemeBtn(
              label: 'profile.theme.light'.tr(),
              icon: Icons.wb_sunny_outlined,
              active: !isDark,
              onTap: () {
                context.read<SettingsCubit>().setTheme('light');
              },
            ),
            ThemeBtn(
              label: 'profile.theme.dark'.tr(),
              icon: Icons.nightlight_outlined,
              active: isDark,
              onTap: () {
                context.read<SettingsCubit>().setTheme('dark');
              },
            ),
          ],
        ),
      ),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(24),
        hoverColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        highlightColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        splashColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isOpen
                ? (widget.isDark ? ColorsManager.surfaceDarkHeader : Colors.white)
                : Colors.transparent,
            borderRadius: _isOpen
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )
                : BorderRadius.circular(24),
            border: _isOpen
                ? Border(
                    top: BorderSide(color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                    left: BorderSide(color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                    right: BorderSide(color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                    bottom: BorderSide.none,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/profile.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(widget.isDark ? Colors.white : Colors.black, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isLoggedIn
                    ? (widget.userName.isNotEmpty
                        ? widget.userName.split(' ').first
                        : 'User')
                    : 'auth.login'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const ThemeBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: SafeMouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 28,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? const Color(0xFF2A2A2C) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: active
                      ? (isDark ? Colors.white70 : const Color(0xFF444444))
                      : (isDark
                          ? const Color(0xFF555555)
                          : const Color(0xFFAAAAAA)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? (isDark ? Colors.white70 : const Color(0xFF444444))
                        : (isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFAAAAAA)),
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

class DropdownActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool accent;
  final VoidCallback onTap;

  const DropdownActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.accent = false,
    required this.onTap,
  });

  @override
  State<DropdownActionButton> createState() => _DropdownActionButtonState();
}

class _DropdownActionButtonState extends State<DropdownActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = ColorsManager.primaryColor;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: widget.accent
                ? (_hovered ? accent.withValues(alpha: 0.9) : accent)
                : (_hovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(50),
            border: widget.accent
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.accent
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.accent
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
