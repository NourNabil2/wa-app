import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareProductButton extends StatelessWidget {
  final String productId;
  final String productName;
  final bool isDark;
  final bool noBackground;
  final double? iconSize;

  const ShareProductButton({
    super.key,
    required this.productId,
    required this.productName,
    this.isDark = false,
    this.noBackground = false,
    this.iconSize,
  });

  void _shareProduct(BuildContext context) {
    // Generate the frontend URL for the product
    final String url = 'https://fastwayprotein.com/product/$productId'; 
    final String textToShare = '$productName\n$url';
    
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      Share.share(
        textToShare,
        subject: productName,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      Share.share(
        textToShare,
        subject: productName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : Colors.black87;

    final actualIconSize = iconSize ?? 20.0;
    Widget icon = Icon(Icons.share_outlined, color: color, size: actualIconSize);

    if (noBackground) {
      return IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        iconSize: actualIconSize,
        hoverColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        icon: icon,
        onPressed: () => _shareProduct(context),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: IconButton(
          icon: icon,
          onPressed: () => _shareProduct(context),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
