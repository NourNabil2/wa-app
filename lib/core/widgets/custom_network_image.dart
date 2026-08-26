import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholder;
  final String? errorImage;
  final Color? backgroundColor;
  final Widget? customPlaceholder;
  final Widget? customErrorWidget;
  final Duration? fadeInDuration;
  final Duration? placeholderFadeInDuration;
  final bool showLoadingIndicator;
  final Color? loadingIndicatorColor;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorImage,
    this.backgroundColor,
    this.customPlaceholder,
    this.customErrorWidget,
    this.fadeInDuration,
    this.placeholderFadeInDuration,
    this.showLoadingIndicator = true,
    this.loadingIndicatorColor,
  });

  /// ✅ Factory constructor for circular avatar
  factory CustomNetworkImage.avatar({
    required String imageUrl,
    required double size,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  /// ✅ Factory constructor for rounded rectangle
  factory CustomNetworkImage.rounded({
    required String imageUrl,
    required double width,
    required double height,
    double borderRadius = 8.0,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.zero,
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  /// ✅ Factory constructor for square image
  factory CustomNetworkImage.square({
    required String imageUrl,
    required double size,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0.0,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: borderRadius > 0 ? BorderRadius.zero : null,
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  /// Local fallback asset shown when the URL is empty or the network image
  /// fails to load. Using a bundled asset (not a remote placeholder) keeps it
  /// CORS-safe on Flutter Web — the /images/Logo.png placeholder is served
  /// without CORS headers and renders as a blank box on the web build.
  static const String _fallbackAsset = 'assets/images/fallback_1_1.png';

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    Widget imageWidget;
    if (url.isEmpty) {
      imageWidget = _buildPlaceholder(context);
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,

                // Duration.zero: the placeholder is shown during load, so
                // no fade animation is needed. 20 concurrent 300ms Opacity
                // animations across a product grid cause GPU layer thrashing.
                fadeInDuration: fadeInDuration ?? Duration.zero,
                placeholderFadeInDuration: placeholderFadeInDuration ?? Duration.zero,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => _buildPlaceholder(context),
                // Decode images at display size (2x for retina) instead of
                // full-res. Reduces GPU texture memory for product grids.
                memCacheWidth: (width != null && width!.isFinite) ? (width! * 2).toInt() : null,
                memCacheHeight: (height != null && height!.isFinite) ? (height! * 2).toInt() : null,
              );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (customPlaceholder != null) return customPlaceholder!;
    return Image.asset(
      placeholder ?? _fallbackAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (customErrorWidget != null) return customErrorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (width != null && height != null && width!.isFinite && height!.isFinite)
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 32,
        color: Colors.grey[400],
      ),
    );
  }
}
