// lib/features/legal/contact_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/features/legal/warehouse_cubit.dart';
import 'package:fastway/features/legal/warehouse_entity.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Contact Us Screen — dynamic warehouse data from /api/v1/warehouses
// ─────────────────────────────────────────────────────────────────────────────

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WarehouseCubit>(
      create: (_) => sl<WarehouseCubit>()..load(),
      child: const _ContactView(),
    );
  }
}

class _ContactView extends StatelessWidget {
  const _ContactView();

  @override
  Widget build(BuildContext context) {
    final isAr  = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const isWeb  = kIsWeb;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final content = SingleChildScrollView(
      child: Column(
        children: [
          _ContactHero(isDark: isDark, isAr: isAr),
          const SizedBox(height: 48),

          // ── Fixed contact channels ────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? MediaQuery.sizeOf(context).width * 0.65 : double.infinity),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                child: isWide
                    ? _WebChannels(isDark: isDark, isAr: isAr)
                    : _MobileChannels(isDark: isDark, isAr: isAr),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ── Dynamic warehouse locations ───────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? MediaQuery.sizeOf(context).width * 0.65 : double.infinity),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                child: BlocBuilder<WarehouseCubit, WarehouseState>(
                  builder: (context, state) {
                    if (state is WarehouseLoading || state is WarehouseInitial) {
                      return _WarehousesSkeleton(isDark: isDark);
                    }
                    if (state is WarehouseError) {
                      return _WarehousesError(
                        isDark: isDark,
                        isAr: isAr,
                        onRetry: () => context.read<WarehouseCubit>().load(),
                      );
                    }
                    if (state is WarehouseLoaded) {
                      return _WarehousesList(
                        warehouses: state.warehouses,
                        isDark: isDark,
                        isAr: isAr,
                        isWeb: isWide,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );

    if (isWeb) {
      return SimpleWebShell(content: content);
    }
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'legal.contact.title'.tr(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────
class _ContactHero extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _ContactHero({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1A2740)]
              : [
                  ColorsManager.primaryColor.withValues(alpha: 0.07),
                  ColorsManager.primaryColor.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : ColorsManager.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded,
                size: 38, color: ColorsManager.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'legal.contact.title'.tr(),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'legal.contact.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixed contact channels (phone, WhatsApp, email, hours) — not from warehouses
// ─────────────────────────────────────────────────────────────────────────────
class _WebChannels extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _WebChannels({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PhoneCard(isDark: isDark, isAr: isAr)),
        const SizedBox(width: 20),
        Expanded(child: _WhatsAppCard(isDark: isDark, isAr: isAr)),
        const SizedBox(width: 20),
        Expanded(child: _EmailCard(isDark: isDark, isAr: isAr)),
        const SizedBox(width: 20),
        Expanded(child: _HoursCard(isDark: isDark, isAr: isAr)),
      ],
    );
  }
}

class _MobileChannels extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _MobileChannels({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _PhoneCard(isDark: isDark, isAr: isAr)),
            const SizedBox(width: 14),
            Expanded(child: _WhatsAppCard(isDark: isDark, isAr: isAr)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _EmailCard(isDark: isDark, isAr: isAr)),
            const SizedBox(width: 14),
            Expanded(child: _HoursCard(isDark: isDark, isAr: isAr)),
          ],
        ),
      ],
    );
  }
}

class _PhoneCard extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _PhoneCard({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _ContactCard(
      icon: Icons.phone_rounded,
      color: const Color(0xFF2196F3),
      title: 'legal.contact.phone'.tr(),
      lines: const ['01002418441'],    // TODO: pull from settings API
      actionLabel: 'legal.contact.call_now'.tr(),
      onAction: () => launchUrl(Uri.parse('tel:01002418441')),
      isDark: isDark,
    );
  }
}

class _WhatsAppCard extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _WhatsAppCard({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _ContactCard(
      icon: Icons.chat_rounded,
      color: const Color(0xFF25D366),
      title: 'legal.contact.whatsapp'.tr(),
      lines: const ['01002418441'],    // TODO: pull from settings API
      actionLabel: 'legal.contact.start_chat'.tr(),
      onAction: () => launchUrl(Uri.parse('https://wa.me/201002418441')),
      isDark: isDark,
    );
  }
}

class _EmailCard extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _EmailCard({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _ContactCard(
      icon: Icons.email_outlined,
      color: const Color(0xFFFF6B35),
      title: 'legal.contact.email'.tr(),
      lines: const ['support@fastway.app'],    // TODO: pull from settings API
      actionLabel: 'legal.contact.send_email'.tr(),
      onAction: () => launchUrl(Uri.parse('mailto:support@fastway.app')),
      isDark: isDark,
    );
  }
}

class _HoursCard extends StatelessWidget {
  final bool isDark;
  final bool isAr;

  const _HoursCard({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _ContactCard(
      icon: Icons.access_time_rounded,
      color: const Color(0xFF9C27B0),
      title: 'legal.contact.working_hours'.tr(),
      lines: [
        'legal.contact.hours_1'.tr(),
        'legal.contact.hours_2'.tr(),
        'legal.contact.hours_3'.tr(),
      ],
      isDark: isDark,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic warehouse list
// ─────────────────────────────────────────────────────────────────────────────
class _WarehousesList extends StatelessWidget {
  final List<WarehouseEntity> warehouses;
  final bool isDark;
  final bool isAr;
  final bool isWeb;

  const _WarehousesList({
    required this.warehouses,
    required this.isDark,
    required this.isAr,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  color: ColorsManager.primaryColor,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'legal.contact.locations_title'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                ),
              ),
            ],
          ),
        ),

        // Grid: 2 columns on web, 1 column on mobile
        if (isWeb)
          _buildGrid(context)
        else
          ...warehouses.map((wh) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WarehouseCard(
                    warehouse: wh, isDark: isDark, isAr: isAr),
              )),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < warehouses.length; i += 2) {
      final left = warehouses[i];
      final right = i + 1 < warehouses.length ? warehouses[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _WarehouseCard(
                      warehouse: left, isDark: isDark, isAr: isAr)),
              const SizedBox(width: 20),
              Expanded(
                child: right != null
                    ? _WarehouseCard(
                        warehouse: right, isDark: isDark, isAr: isAr)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual warehouse card
// ─────────────────────────────────────────────────────────────────────────────
class _WarehouseCard extends StatefulWidget {
  final WarehouseEntity warehouse;
  final bool isDark;
  final bool isAr;

  const _WarehouseCard({
    required this.warehouse,
    required this.isDark,
    required this.isAr,
  });

  @override
  State<_WarehouseCard> createState() => _WarehouseCardState();
}

class _WarehouseCardState extends State<_WarehouseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wh = widget.warehouse;
    final name = widget.isAr ? wh.nameAr : wh.name;

    return SafeMouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: _hovered
                  ? ColorsManager.primaryColor.withValues(alpha: 0.4)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? ColorsManager.primaryColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Map visual area ──────────────────────────────────────────
              if (wh.hasLocation)
                _WarehouseMapPreview(wh: wh, isDark: widget.isDark, isAr: widget.isAr),

              // ── Info ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? Colors.white
                                  : ColorsManager.surfaceDarkElevated,
                            ),
                          ),
                        ),
                        if (wh.isDefault)
                          _Badge(
                            label: 'legal.contact.main_badge'.tr(),
                            color: ColorsManager.primaryColor,
                          ),
                        if (wh.isExpress) ...[
                          const SizedBox(width: 6),
                          _Badge(
                            label: 'legal.contact.express_badge'.tr(),
                            color: const Color(0xFF2196F3),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15,
                            color: widget.isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Selectable(
                            child: Text(
                              wh.fullAddressEn,
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Phone
                    if (wh.hasPhone) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 15,
                              color: widget.isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                launchUrl(Uri.parse('tel:${wh.phone}')),
                            child: Text(
                              wh.phone!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ColorsManager.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Directions button
                    if (wh.hasLocation) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${wh.lat},${wh.lng}')),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: ColorsManager.primaryColor
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                                color: ColorsManager.primaryColor
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_rounded,
                                  size: 14,
                                  color: ColorsManager.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'legal.contact.get_directions'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map preview click-area for warehouse card
// ─────────────────────────────────────────────────────────────────────────────
class _WarehouseMapPreview extends StatelessWidget {
  final WarehouseEntity wh;
  final bool isDark;
  final bool isAr;

  const _WarehouseMapPreview(
      {required this.wh, required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${wh.lat},${wh.lng}')),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.zero, topRight: Radius.zero),
        child: Container(
          height: 130,
          width: double.infinity,
          color: isDark ? const Color(0xFF0F1923) : const Color(0xFFE8F4FD),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 130),
                painter: _MapGridPainter(isDark: isDark),
              ),
              // Pin
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.primaryColor
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: const Icon(Icons.warehouse_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: ColorsManager.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 11, color: ColorsManager.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'legal.contact.maps'.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge chip
// ─────────────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loader
// ─────────────────────────────────────────────────────────────────────────────
class _WarehousesSkeleton extends StatelessWidget {
  final bool isDark;

  const _WarehousesSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _WarehousesError extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  final VoidCallback onRetry;

  const _WarehousesError(
      {required this.isDark, required this.isAr, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'legal.contact.error_loading'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('legal.contact.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact info card (generic)
// ─────────────────────────────────────────────────────────────────────────────
class _ContactCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
    this.actionLabel,
    this.onAction,
    required this.isDark,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SafeMouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(widget.icon, size: 24, color: widget.color),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      widget.isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.lines.map((line) => GestureDetector(
                    onLongPress: () =>
                        Clipboard.setData(ClipboardData(text: line)),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  )),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: widget.onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: widget.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: widget.color),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative grid map painter
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  final bool isDark;

  const _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
          : const Color(0xFF90CAF9).withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final roadPaint = Paint()
      ..color = isDark
          ? const Color(0xFF2196F3).withValues(alpha: 0.25)
          : const Color(0xFFBBDEFB).withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.45, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
