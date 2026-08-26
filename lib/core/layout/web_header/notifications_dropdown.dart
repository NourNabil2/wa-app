import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../routes/app_navigator.dart';
import '../../routes/routes.dart';
import '../../theme/colors.dart';
import '../../../features/notifications/domain/entities/notification_entity.dart';
import '../../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../../features/notifications/presentation/cubit/notifications_state.dart';

/// Web notifications dropdown — anchored below the header bell, it shows the
/// latest notifications inline in a scrollable list (no navigation to a
/// separate page just to read them). A "view all" footer still links to the
/// full screen, and "mark all read" clears the unread badge.
///
/// Mirrors EmptyModal.showDropdown's Overlay + dismiss-backdrop + animation
/// pattern so it looks consistent with the rest of the header dropdowns.
class NotificationsDropdown {
  static OverlayEntry? _active;

  /// How many of the latest notifications to show inline before "view all".
  static const int previewLimit = 6;

  static void show(
    BuildContext context, {
    required GlobalKey anchorKey,
    required NotificationsCubit cubit,
  }) {
    dismiss();

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entry = OverlayEntry(
      builder: (_) => _NotificationsDropdownView(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        isDark: isDark,
        cubit: cubit,
        onDismiss: dismiss,
      ),
    );

    _active = entry;
    Overlay.of(context).insert(entry);
  }

  static void dismiss() {
    _active?.remove();
    _active = null;
  }
}

class _NotificationsDropdownView extends StatefulWidget {
  final double left;
  final double top;
  final bool isDark;
  final NotificationsCubit cubit;
  final VoidCallback onDismiss;

  const _NotificationsDropdownView({
    required this.left,
    required this.top,
    required this.isDark,
    required this.cubit,
    required this.onDismiss,
  });

  @override
  State<_NotificationsDropdownView> createState() =>
      _NotificationsDropdownViewState();
}

class _NotificationsDropdownViewState extends State<_NotificationsDropdownView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    // Refresh the latest notifications when the dropdown opens.
    widget.cubit.loadNotifications(refresh: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openItem(NotificationEntity n) {
    if (!n.isRead) widget.cubit.markAsRead([n.id]);
    widget.onDismiss();
    AppNavigator.pushNamed(context, Routes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final lang = context.locale.languageCode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    const cardWidth = 360.0;
    final clampedLeft = (widget.left + cardWidth > screenWidth - 8)
        ? screenWidth - cardWidth - 8
        : widget.left;
    // Cap the list height so it scrolls instead of overflowing the viewport.
    final maxListHeight = (screenHeight - widget.top - 80).clamp(160.0, 420.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: clampedLeft,
          top: widget.top,
          width: cardWidth,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: widget.isDark ? 0.5 : 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(),
                      Flexible(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxHeight: maxListHeight),
                          child: BlocBuilder<NotificationsCubit,
                              NotificationsState>(
                            bloc: widget.cubit,
                            builder: (context, state) => _body(state, lang),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    final textColor =
        widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          Text(
            'profile.notifications'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => widget.cubit.markAsRead(const []),
            style: TextButton.styleFrom(
              foregroundColor: ColorsManager.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'notifications.mark_all_read'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(NotificationsState state, String lang) {
    if (state is NotificationsLoading || state is NotificationsInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (state is NotificationsError) {
      return _emptyOrError('notifications.empty_subtitle'.tr());
    }

    if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return _emptyOrError('notifications.empty_subtitle'.tr());
      }
      final items =
          state.notifications.take(NotificationsDropdown.previewLimit).toList();
      return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        itemBuilder: (_, i) => _tile(items[i], lang),
      );
    }

    return const SizedBox(height: 0);
  }

  Widget _emptyOrError(String message) {
    final subtitleColor =
        widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 32, color: subtitleColor),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _tile(NotificationEntity n, String lang) {
    final titleColor =
        widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    final bodyColor = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return InkWell(
      onTap: () => _openItem(n),
      child: Container(
        color: n.isRead
            ? Colors.transparent
            : ColorsManager.primaryColor.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  size: 18, color: ColorsManager.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.localizedTitle(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.localizedBody(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: bodyColor, height: 1.35),
                  ),
                ],
              ),
            ),
            if (!n.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: ColorsManager.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
