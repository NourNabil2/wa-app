import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/layout/simple_web_shell.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../features/user_data/auth_guard.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  final bool asBottomSheet;
  const NotificationsScreen({super.key, this.asBottomSheet = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Always (re)load on open for authenticated users. Use a post-frame callback
    // so the cubit lookup resolves against the fully-built provider tree — on web
    // this screen can be reached via a direct URL / deep link where reading the
    // cubit synchronously in initState was unreliable, leaving the page empty even
    // though the same global cubit populates the header dropdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AuthGuard.isGuest(context)) {
        context.read<NotificationsCubit>().loadNotifications(refresh: true);
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!AuthGuard.isGuest(context)) {
          context.read<NotificationsCubit>().loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildHeader() {
      if (widget.asBottomSheet) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profile.notifications'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      if (state is NotificationsLoaded && state.unreadCount > 0) {
                        return TextButton(
                          onPressed: () =>
                              context.read<NotificationsCubit>().markAsRead([]),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'notifications.mark_all_read'.tr(),
                            style: TextStyle(
                              color: ColorsManager.primaryColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          ],
        );
      }

      return CustomAppBar(
        title: 'profile.notifications'.tr(),
        showBackIcon: true,
        action: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoaded && state.unreadCount > 0) {
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAsRead([]),
                child: Text(
                  'notifications.mark_all_read'.tr(),
                  style: TextStyle(
                    color: ColorsManager.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    Widget bodyContent = BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return _wrapInWebShell(
              isWeb,
              const NotificationsSkeleton(),
            );
          }

          if (state is NotificationsError) {
            return _wrapInWebShell(
              isWeb,
              Center(child: Text(state.message)),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _wrapInWebShell(
                isWeb,
                EmptyStateWidget(
                  icon: Icons.notifications_off_outlined,
                  title: 'notifications.empty_title'.tr(),
                  subtitle: 'notifications.empty_subtitle'.tr(),
                ),
              );
            }

            final list = ListView.separated(
              // On web the list lives inside SimpleWebShell's SingleChildScrollView,
              // so it must shrink-wrap and NOT scroll itself — otherwise a nested
              // unbounded-height viewport throws ("Vertical viewport was given
              // unbounded height"), which rendered as the corrupted page. On mobile
              // it's the primary scrollable, so keep the controller + normal physics.
              controller: isWeb ? null : _scrollController,
              shrinkWrap: isWeb,
              physics: isWeb ? const NeverScrollableScrollPhysics() : null,
              padding: EdgeInsets.all(16.w),
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (index == state.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: NotificationsSkeleton(),
                  );
                }

                final notification = state.notifications[index];
                final isRead = notification.isRead;
                final lang = context.locale.languageCode;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        context
                            .read<NotificationsCubit>()
                            .markAsRead([notification.id]);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Theme.of(context).cardColor
                            : ColorsManager.primaryColor.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead
                              ? Theme.of(context).dividerColor.withValues(alpha: 0.08)
                              : ColorsManager.primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isRead
                                    ? Theme.of(context).dividerColor.withValues(alpha: 0.1)
                                    : ColorsManager.primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              color: isRead
                                  ? Theme.of(context).cardColor
                                  : ColorsManager.primaryColor.withValues(alpha: 0.05),
                            ),
                            child: Center(
                              child: Icon(
                                isRead
                                    ? Icons.notifications_outlined
                                    : Icons.notifications_active_rounded,
                                color: isRead
                                    ? Theme.of(context).iconTheme.color?.withValues(alpha: 0.4)
                                    : ColorsManager.primaryColor,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.localizedTitle(lang),
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
                                          fontSize: 15.sp,
                                          letterSpacing: -0.2,
                                          color: isRead
                                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      _formatTime(notification.createdAt),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  notification.localizedBody(lang),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: isRead ? 0.6 : 0.8),
                                    fontSize: 13.sp,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Unread Indicator
                          if (!isRead) ...[
                            SizedBox(width: 16.w),
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: ColorsManager.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorsManager.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

            final w = MediaQuery.sizeOf(context).width;
            return _wrapInWebShell(
              isWeb,
              (isWeb && w > 800)
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * 0.55),
                      child: list,
                    )
                  : list,
            );
          }

          return const SizedBox.shrink();
        },
      );

    if (widget.asBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            buildHeader(),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    if (isWeb) {
      return bodyContent; // SimpleWebShell provides the layout
    }

    return Scaffold(
      backgroundColor: ColorsManager.backgroundSurface,
      appBar: buildHeader() as PreferredSizeWidget,
      body: bodyContent,
    );
  }

  Widget _wrapInWebShell(bool isWeb, Widget child) {
    if (isWeb) {
      return SimpleWebShell(content: Center(child: child));
    }
    return child;
  }
}


