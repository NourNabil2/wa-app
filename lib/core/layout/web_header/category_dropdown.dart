import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/theme/text_theme.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';

class InTreeCategoryDropdown extends StatelessWidget {
  final dynamic category;
  final bool isDark;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final void Function(dynamic cat) onNavigate;

  const InTreeCategoryDropdown({
    super.key,
    required this.category,
    required this.isDark,
    required this.onEnter,
    required this.onExit,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final locale      = Localizations.localeOf(context).languageCode;
    final bgColor     = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final radius      = const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));

    List items = [];
    bool isLeaf = false;
    if (category == 'all') {
      final s = context.read<HomeCubit>().state;
      if (s is HomeLoaded) items = s.categories;
    } else {
      items = category.children as List? ?? [];
      isLeaf = items.isEmpty;
    }

    if (isLeaf) return const SizedBox.shrink();

    return Container(
      width: 240,
      constraints: const BoxConstraints(maxHeight: 460),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border(
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          // No top border so it connects seamlessly to the tab
        ),
        boxShadow: [
          // Only cast shadow downward + sides, never upward
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: AccordionList(
            items:      items,
            isDark:     isDark,
            locale:     locale,
            withSubs:   category == 'all',
            onNavigate: onNavigate,
          ),
      ),
    );
  }
}

class AccordionList extends StatefulWidget {
  final List items;
  final bool isDark;
  final String locale;
  final bool withSubs;
  final void Function(dynamic) onNavigate;

  const AccordionList({
    super.key,
    required this.items,
    required this.isDark,
    required this.locale,
    required this.withSubs,
    required this.onNavigate,
  });

  @override
  State<AccordionList> createState() => _AccordionListState();
}

class _AccordionListState extends State<AccordionList> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics:    const ClampingScrollPhysics(),
      padding:    const EdgeInsets.symmetric(vertical: 6),
      itemCount:  widget.items.length,
      itemBuilder: (_, i) {
        final item     = widget.items[i];
        final subs     = widget.withSubs ? (item.children as List? ?? []) : <dynamic>[];
        final hasSubs  = subs.isNotEmpty;
        final isOpen   = _open == i;
        final name     = widget.locale == 'ar' ? item.nameAr : item.name;
        const primary  = ColorsManager.primaryColor;
        final textCol  = isDark ? Colors.white : Colors.black87;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ParentRow(
              name: name,
              isOpen: isOpen,
              hasSubs: hasSubs,
              isDark: isDark,
              primary: primary,
              textCol: textCol,
              onTap: () {
                if (!hasSubs) { widget.onNavigate(item); return; }
                setState(() => _open = isOpen ? null : i);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve:    Curves.easeInOut,
              child: isOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: subs.map<Widget>((sub) {
                        final subName = widget.locale == 'ar' ? sub.nameAr : sub.name;
                        return SubRow(
                          name:    subName,
                          isDark:  isDark,
                          onTap:   () => widget.onNavigate(sub),
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  bool get isDark => widget.isDark;
}

class ParentRow extends StatefulWidget {
  final String name;
  final bool isOpen;
  final bool hasSubs;
  final bool isDark;
  final Color primary;
  final Color textCol;
  final VoidCallback onTap;

  const ParentRow({
    super.key,
    required this.name,
    required this.isOpen,
    required this.hasSubs,
    required this.isDark,
    required this.primary,
    required this.textCol,
    required this.onTap,
  });

  @override
  State<ParentRow> createState() => _ParentRowState();
}

class _ParentRowState extends State<ParentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isOpen || _hovered;
    return Material(
      color: Colors.transparent,
      child: SafeMouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hovered 
                ? (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)) 
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          color: isHighlighted ? widget.primary : widget.textCol,
                          fontFamily: AppTextTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.hasSubs)
                      AnimatedRotation(
                        turns: widget.isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isHighlighted
                              ? widget.primary
                              : (widget.isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubRow extends StatefulWidget {
  final String name;
  final bool isDark;
  final VoidCallback onTap;
  const SubRow({super.key, required this.name, required this.isDark, required this.onTap});
  @override
  State<SubRow> createState() => _SubRowState();
}

class _SubRowState extends State<SubRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const primary = ColorsManager.primaryColor;
    return SafeMouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered 
              ? (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)) 
              : Colors.transparent,
          padding: const EdgeInsetsDirectional.fromSTEB(28, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: _hovered ? FontWeight.w700 : FontWeight.w400,
                  color: _hovered ? primary : (widget.isDark ? Colors.white70 : Colors.black54),
                  fontFamily: AppTextTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
