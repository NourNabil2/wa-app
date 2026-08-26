import 'package:flutter/material.dart';
import 'package:fastway/core/widgets/loading_widget.dart';

class CustomLoadingDialog extends StatelessWidget {
  final String loadingText;

  const CustomLoadingDialog({super.key, this.loadingText = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0, // No shadow for a cleaner look
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingSpinner(size: 80.0),
          const SizedBox(height: 16),
          // Only show text if it's not the default empty space
          if (loadingText != 'Loading...' && loadingText.isNotEmpty)
            Text(
              loadingText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/*
Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                AssetsManager.logo,
                width: 64,
                height: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.loadingText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
 */