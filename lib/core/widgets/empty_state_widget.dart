import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_layout.dart';
import 'app_buton.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final bool enableBackButton;
  final VoidCallback? onBackPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconSize = 80,
    this.onActionPressed,
    this.actionLabel,
    this.enableBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    // Web: no Scaffold wrapping, just the centered content
    if (isWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _Body(
            icon: icon,
            title: title,
            subtitle: subtitle,
            iconSize: iconSize,
            onActionPressed: onActionPressed,
            actionLabel: actionLabel,
          ),
        ),
      );
    }

    // Mobile: full Scaffold with optional back button
    return PopScope(
      canPop: enableBackButton && onBackPressed == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (enableBackButton && onBackPressed != null) {
          onBackPressed!();
        }
      },
      child: Scaffold(
        appBar: enableBackButton
            ? AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppBarButton(
            icon: Icons.arrow_back,
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            isTransparent: false,
          ),
        )
            : null,
        body: Center(
          child: _Body(
            icon: icon,
            title: title,
            subtitle: subtitle,
            iconSize: iconSize,
            onActionPressed: onActionPressed,
            actionLabel: actionLabel,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const _Body({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconSize,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (onActionPressed != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            AppButton(
              text: actionLabel!,
              onPressed: onActionPressed,
              horizontalPadding: 40,
              verticalPadding: 0,
            ),
          ],
        ],
      ),
    );
  }
}