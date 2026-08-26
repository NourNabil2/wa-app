import 'package:flutter/material.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/theme/colors.dart';

class WebBreadcrumb extends StatelessWidget {
  final List<String> labels;
  final List<VoidCallback?> onTaps;
  final bool isDark;

  const WebBreadcrumb({
    super.key,
    required this.labels,
    required this.onTaps,
    required this.isDark,
  }) : assert(labels.length == onTaps.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isLast = i == labels.length - 1;
          final label = labels[i];
          final onTap = onTaps[i];

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onTap != null && !isLast)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                    color: isLast
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
