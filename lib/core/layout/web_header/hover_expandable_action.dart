import 'package:flutter/material.dart';

class HoverExpandableAction extends StatefulWidget {
  final Widget icon;
  final String label;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  const HoverExpandableAction({
    super.key,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<HoverExpandableAction> createState() => _HoverExpandableActionState();
}

class _HoverExpandableActionState extends State<HoverExpandableAction> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onTap,
      tooltip: widget.label,
      hoverColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
      highlightColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(8),
      icon: IconTheme(
        data: IconThemeData(color: widget.textColor),
        child: widget.icon,
      ),
    );
  }
}
