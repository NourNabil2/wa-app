
import 'package:flutter/material.dart';
import 'package:fastway/core/theme/colors.dart';

import 'loading_widget.dart';


class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool active;
  final Color? backgroundColor;
  final Color? textColor;
// final EdgeInsets padding;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;
  final double? horizontalPadding;
  final double? verticalPadding;

  const AppButton({
    super.key,
    required this.text,
    this.active = true,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
   // this.padding = const EdgeInsets.symmetric(horizontal:  horizontalPadding??80, vertical: 15),
    this.borderRadius = 8.0,
    this.textStyle,
    this.leadingIcon, this.horizontalPadding=0, this.verticalPadding=15,

  });

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 52.0;
    const buttonFontSize = 16.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 80,
        vertical: verticalPadding ?? 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading || !active ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: active
                ? (backgroundColor ?? ColorsManager.primaryColor)
                : ColorsManager.defaultTextSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: isLoading
              ? const LoadingSpinner(size: 25)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: textStyle ??
                          TextStyle(
                            color: textColor ??
                                (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white),
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (leadingIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          leadingIcon,
                          size: 20,
                          color: textColor ?? Colors.white,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}


class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool active;
  final Color? disabledColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double borderWidth;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.active = true,
    required this.onPressed,
    this.isLoading = false,
    this.disabledColor,
    this.borderRadius = 8.0,
    this.textStyle,
    this.leadingIcon,
    this.horizontalPadding = 0,
    this.verticalPadding = 15,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 80,
        vertical: verticalPadding ?? 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading || !active ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: active
                  ? (Theme.of(context).brightness == Brightness.dark )
                  ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
              width: borderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            foregroundColor: active ? (Theme.of(context).brightness == Brightness.dark )
                ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: isLoading
              ? const LoadingSpinner(size: 25)
              : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    leadingIcon,
                    size: 20,
                    color: active ? Theme.of(context).disabledColor : (Theme.of(context).brightness == Brightness.dark )
                        ? ColorsManager.secondaryColor : ColorsManager.primaryColor,
                  ),
                ),
              Text(
                text,
                style: textStyle ??
                    TextStyle(
                      color:  active
                          ? (Theme.of(context).brightness == Brightness.dark )
                          ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isTransparent;

  const AppBarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // If transparent, show a blurred or semi-black background to keep icon visible
        color: isTransparent
            ? Colors.black.withValues(alpha: 0.3)
            : Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: isTransparent
            ? null
            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isTransparent ? Colors.white : Theme.of(context).primaryColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class SecondryAppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SecondryAppButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor, // Button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 8),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium));
  }
}

