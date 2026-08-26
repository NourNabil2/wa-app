import 'package:flutter/material.dart';
import 'responsive_layout.dart';

/// A reusable product grid that adapts its column count based on screen width.
///
/// | Breakpoint        | Columns |
/// |-------------------|---------|
/// | Mobile (< 600)    | 2       |
/// | Tablet (600–899)  | 3       |
/// | Desktop (900–1399)| 4       |
/// | Wide (1400+)      | 5       |
///
/// Uses [childAspectRatio] (width / height) so product cards scale
/// proportionally across all screen sizes instead of using fixed pixel heights.
///
/// Usage:
/// ```dart
/// ResponsiveGrid(
///   children: products.map((p) => ProductCard(product: p)).toList(),
/// )
/// ```

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  /// Width-to-height ratio for each grid cell.
  /// Default 0.54 gives a tall card (height ≈ 1.85× width).
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final int? crossAxisCount;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 0.72,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics,
    this.controller,
    this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final cols = crossAxisCount ?? responsiveGridColumns(context);

    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// A sliver variant of ResponsiveGrid for use inside CustomScrollView.
class ResponsiveGridSliver extends StatelessWidget {
  final List<Widget> children;

  /// Width-to-height ratio for each grid cell.
  /// See [ResponsiveGrid.childAspectRatio].
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  const ResponsiveGridSliver({
    super.key,
    required this.children,
    this.childAspectRatio = 0.72,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = responsiveGridColumns(context);

    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildListDelegate(children),
      ),
    );
  }
}
