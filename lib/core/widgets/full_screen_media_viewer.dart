import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_size.dart';

class FullScreenMediaViewer extends StatelessWidget {
  final String filePath;
  final Color? accentColor;

  const FullScreenMediaViewer({
    super.key,
    required this.filePath,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: filePath,
                fit: BoxFit.contain,
                errorWidget: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64.sp,
                          color: Colors.white,
                        ),
                        const SizedBox(height: SizeApp.s16),
                        Text(
                          'core.media.cannot_load_image'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Static method لسهولة الاستخدام
  static void show(
      BuildContext context, {
        required String filePath,
        required bool isVideo,
        Color? accentColor,
      }) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: FullScreenMediaViewer(
          filePath: filePath,
          accentColor: accentColor,
        ),
      ),
    );
  }
}