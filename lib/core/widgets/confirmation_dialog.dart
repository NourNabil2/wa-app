// ==================== confirmation_dialog.dart ====================
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_size.dart';
import 'app_buton.dart';

class _ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;

   const _ConfirmationDialog({
     this.title, this.message, this.confirmText, this.cancelText, this.icon, this.iconColor, this.onConfirm, this.onCancel, required this.isDangerous});

  @override
  Widget build(BuildContext context) {
    final hSize = AppSizeHorizontal.instance;
    final vSize = AppSizeVertical.instance;
    final color = iconColor ??
        (isDangerous ? Colors.red : Theme.of(context).primaryColor);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.all(hSize.s24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null)
              Container(
                padding: EdgeInsets.all(hSize.s16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48.r,
                  color: color,
                ),
              ),

            if (icon != null) SizedBox(height: vSize.s16),

            // Title
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null) SizedBox(height: vSize.s12),

            // Message
            if (message != null)
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),

            SizedBox(height: vSize.s24),

            // Confirm Button
            AppButton(
              text: confirmText ?? 'core.dialog.confirm'.tr(),
              horizontalPadding: 0,
              verticalPadding: 0,
              onPressed: () {
                Navigator.pop(context, true);
                onConfirm?.call();
              },
            ),

            SizedBox(height: vSize.s12),

            // Cancel Button
            AppOutlinedButton(
              text: cancelText ?? 'core.dialog.cancel'.tr(),
              horizontalPadding: 0,
              verticalPadding: 0,
              onPressed: () {
                Navigator.pop(context, false);
                onCancel?.call();
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ==================== Helper Function ====================
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
  IconData? icon,
  Color? iconColor,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isDangerous = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      iconColor: iconColor,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDangerous: isDangerous,
    ),
  );
}

class AppDialog {
  // --- Success Dialog ---
  static Future<bool?> success({
    required BuildContext context,
    required String message,
    String? title,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    return showConfirmationDialog(
      context: context,
      title: title ?? 'core.dialog.success_title'.tr(),
      message: message,
      confirmText: confirmText ?? 'core.dialog.ok'.tr(),
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      onConfirm: onConfirm,
    );
  }

  // --- Error Dialog ---
  static Future<bool?> error({
    required BuildContext context,
    required String message,
    String? title,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    return showConfirmationDialog(
      context: context,
      title: title ?? 'core.dialog.error_title'.tr(),
      message: message,
      confirmText: confirmText ?? 'core.dialog.try_again'.tr(),
      icon: Icons.error_outline,
      iconColor: Colors.red,
      onConfirm: onConfirm,
      isDangerous: true,
    );
  }

  // --- Warning / Delete Dialog ---
  static Future<bool?> warning({
    required BuildContext context,
    required String message,
    String? title,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    return showConfirmationDialog(
      context: context,
      title: title ?? 'core.dialog.warning_title'.tr(),
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }
}
