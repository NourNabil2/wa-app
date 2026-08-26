// lib/features/settings/presentation/widgets/settings_header.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SettingsHeader extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final String? location;
  final VoidCallback? onEditPressed;
  final VoidCallback? onLocationPressed;

  const SettingsHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.location,
    this.onEditPressed,
    this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: ColorsManager.primaryColor,
      expandedHeight: SizeApp.expandedHeight,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxHeight > 120.h;
          final scrollProgress = ((constraints.maxHeight - kToolbarHeight) / (220.h - kToolbarHeight)).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildBackground(),

              if (isExpanded)
                _buildExpandedContent(context, scrollProgress)
              else
                _buildCollapsedContent(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.appBarBg),
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.none,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, double scrollProgress) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Profile Image (Half in, Half out)
        Positioned(
          top: 60.h + (30.h * (1 - scrollProgress)),
          left: 0,
          right: 0,
          child: Opacity(
            opacity: scrollProgress,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    width: AppSizeHorizontal.instance.s100,
                    height: AppSizeHorizontal.instance.s100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: userPhotoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          size: 50.sp,
                          color: ColorsManager.primaryColor,
                        ),
                      )
                          : Icon(
                        Icons.person,
                        size: 50.sp,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                  ),
                  // Edit Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPressed,
                      child: Container(
                        padding: EdgeInsets.all(AppSizeHorizontal.instance.s8),
                        decoration: BoxDecoration(
                          color: ColorsManager.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Name & Email & Location
        Positioned(
          bottom: AppSizeVertical.instance.s16,
          left: AppSizeHorizontal.instance.s20,
          right: AppSizeHorizontal.instance.s20,
          child: Opacity(
            opacity: scrollProgress,
            child: Column(
              children: [
                Text(
                  userName ?? "auth.user".tr(),
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSizeVertical.instance.s4),
                Text(
                  userEmail ?? "",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location != null && location!.isNotEmpty) ...[
                  SizedBox(height: AppSizeVertical.instance.s8),
                  GestureDetector(
                    onTap: onLocationPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizeHorizontal.instance.s12,
                        vertical: AppSizeVertical.instance.s6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: AppSizeHorizontal.instance.s4),
                          Flexible(
                            child: Text(
                              location!,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ),
      ],
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Positioned(
      top: 15,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizeHorizontal.instance.s16,
            vertical: AppSizeVertical.instance.s8,
          ),
          child: Row(
            children: [
              // Small Profile Image
              Container(
                width: AppSizeHorizontal.instance.s50,
                height: AppSizeHorizontal.instance.s50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: userPhotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.person,
                      size: 24.sp,
                      color: ColorsManager.primaryColor,
                    ),
                  )
                      : Icon(
                    Icons.person,
                    size: 24.sp,
                    color: ColorsManager.primaryColor,
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