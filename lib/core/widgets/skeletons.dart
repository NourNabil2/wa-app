import 'package:flutter/material.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart' show kProductCardAspectRatio;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BaseShimmer extends StatelessWidget {
  final Widget child;
  const BaseShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF3D3D3F) : Colors.grey.shade50,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({super.key, this.width, this.height, this.radius = 8.0, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer requires an opaque color to work
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double diameter;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({super.key, required this.diameter, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerLine({super.key, required this.width, this.height = 12.0, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}

// ── Composed Skeletons ───────────────────────────────────────────────────────

class CategoryRowSkeleton extends StatelessWidget {
  const CategoryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: SizedBox(
        height: 100.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: 5,
          separatorBuilder: (_, __) => SizedBox(width: 16.w),
          itemBuilder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerCircle(diameter: 64.w),
              SizedBox(height: 8.h),
              ShimmerLine(width: 50.w),
            ],
          ),
        ),
      ),
    );
  }
}

class PromoBannerSkeleton extends StatelessWidget {
  const PromoBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: ShimmerBox(
        width: double.infinity,
        height: 150.h,
        radius: 12.r,
        margin: EdgeInsets.symmetric(horizontal: 16.w),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  final bool isList;
  const ProductCardSkeleton({super.key, this.isList = false});

  @override
  Widget build(BuildContext context) {
    if (isList) {
      return BaseShimmer(
        child: Row(
          children: [
            ShimmerBox(width: 100.w, height: 100.w, radius: 12.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShimmerLine(width: double.infinity),
                  SizedBox(height: 8.h),
                  ShimmerLine(width: 150.w),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLine(width: 60.w, height: 16.h),
                      ShimmerBox(width: 32.w, height: 32.w, radius: 8.r),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return BaseShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ShimmerBox(width: double.infinity, radius: 12.r),
          ),
          SizedBox(height: 8.h),
          const ShimmerLine(width: double.infinity),
          SizedBox(height: 4.h),
          ShimmerLine(width: 100.w),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLine(width: 60.w, height: 16.h),
              ShimmerBox(width: 32.w, height: 32.w, radius: 8.r),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductDetailSkeleton extends StatelessWidget {
  final bool isWeb;
  const ProductDetailSkeleton({super.key, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerLine(width: 100.w, height: 14.h), // category
        SizedBox(height: 12.h),
        ShimmerLine(width: double.infinity, height: 24.h), // title
        SizedBox(height: 8.h),
        ShimmerLine(width: 200.w, height: 24.h), // title 2
        SizedBox(height: 24.h),
        ShimmerLine(width: 120.w, height: 32.h), // price
        SizedBox(height: 32.h),
        const ShimmerLine(width: double.infinity),
        SizedBox(height: 8.h),
        const ShimmerLine(width: double.infinity),
        SizedBox(height: 8.h),
        const ShimmerLine(width: double.infinity),
        SizedBox(height: 8.h),
        ShimmerLine(width: 150.w),
      ],
    );

    return BaseShimmer(
      child: isWeb
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ShimmerBox(height: 500.h, radius: 16.r)),
                SizedBox(width: 40.w),
                Expanded(child: body),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 350.h, radius: 0),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: body,
                ),
              ],
            ),
    );
  }
}

class BlogCardSkeleton extends StatelessWidget {
  const BlogCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ShimmerBox(width: double.infinity, radius: 16.r),
          ),
          SizedBox(height: 16.h),
          ShimmerLine(width: 80.w, height: 20.h),
          SizedBox(height: 12.h),
          ShimmerLine(width: double.infinity, height: 18.h),
          SizedBox(height: 8.h),
          ShimmerLine(width: 200.w, height: 18.h),
          SizedBox(height: 16.h),
          ShimmerLine(width: 150.w),
        ],
      ),
    );
  }
}

class BlogDetailSkeleton extends StatelessWidget {
  const BlogDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 480, radius: 0),
          Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: double.infinity, height: 20.h),
                SizedBox(height: 16.h),
                ShimmerLine(width: double.infinity, height: 20.h),
                SizedBox(height: 16.h),
                ShimmerLine(width: 200.w, height: 20.h),
                SizedBox(height: 48.h),
                ShimmerLine(width: double.infinity, height: 16.h),
                SizedBox(height: 12.h),
                ShimmerLine(width: double.infinity, height: 16.h),
                SizedBox(height: 12.h),
                ShimmerLine(width: double.infinity, height: 16.h),
                SizedBox(height: 12.h),
                ShimmerLine(width: 250.w, height: 16.h),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 80.w, height: 80.w, radius: 12.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLine(width: double.infinity),
                  SizedBox(height: 8.h),
                  ShimmerLine(width: 100.w),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLine(width: 80.w, height: 18.h),
                      ShimmerBox(width: 90.w, height: 32.h, radius: 16.r),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubCategorySkeleton extends StatelessWidget {
  final bool isDrawer;
  const SubCategorySkeleton({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    if (isDrawer) {
      return BaseShimmer(
        child: Column(
          children: List.generate(
            8,
            (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: Row(
                children: [
                  ShimmerCircle(diameter: 24.w),
                  SizedBox(width: 12.w),
                  const Expanded(child: ShimmerLine(width: double.infinity)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return BaseShimmer(
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: kProductCardAspectRatio,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => ShimmerBox(width: double.infinity, height: double.infinity, radius: 16.r),
      ),
    );
  }
}

class PointsHeaderSkeleton extends StatelessWidget {
  const PointsHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: ShimmerBox(
        width: double.infinity,
        height: 160.h,
        radius: 16.r,
      ),
    );
  }
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: ShimmerBox(
          width: double.infinity,
          height: 120.h,
          radius: 12.r,
        ),
      ),
    );
  }
}

// ── Generic page-level skeletons ─────────────────────────────────────────────

/// A generic full-page skeleton with a header block + lines — used for screens
/// (orders detail, profile, checkout, etc.) that don't have a custom one.
class GenericPageSkeleton extends StatelessWidget {
  const GenericPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: double.infinity, height: 140.h, radius: 16.r),
            SizedBox(height: 24.h),
            ShimmerLine(width: 180.w, height: 18.h),
            SizedBox(height: 16.h),
            const ShimmerLine(width: double.infinity, height: 14),
            SizedBox(height: 10.h),
            const ShimmerLine(width: double.infinity, height: 14),
            SizedBox(height: 10.h),
            ShimmerLine(width: 240.w, height: 14),
            SizedBox(height: 28.h),
            ShimmerBox(width: double.infinity, height: 100.h, radius: 12.r),
            SizedBox(height: 16.h),
            ShimmerBox(width: double.infinity, height: 100.h, radius: 12.r),
            SizedBox(height: 16.h),
            ShimmerBox(width: double.infinity, height: 100.h, radius: 12.r),
          ],
        ),
      ),
    );
  }
}

/// Used for the orders list screen — repeating order card rows.
class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: List.generate(5, (_) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ShimmerBox(width: double.infinity, height: 120.h, radius: 12.r),
          )),
        ),
      ),
    );
  }
}

/// Used for notifications screen — repeating notification rows.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: List.generate(6, (_) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerCircle(diameter: 40.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerLine(width: double.infinity, height: 14),
                      SizedBox(height: 6.h),
                      ShimmerLine(width: 200.w, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}

/// Used for profile screen.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: ShimmerCircle(diameter: 80.w)),
            SizedBox(height: 16.h),
            Center(child: ShimmerLine(width: 160.w, height: 18)),
            SizedBox(height: 8.h),
            Center(child: ShimmerLine(width: 120.w, height: 14)),
            SizedBox(height: 32.h),
            ...List.generate(5, (_) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: ShimmerBox(width: double.infinity, height: 56.h, radius: 12.r),
            )),
          ],
        ),
      ),
    );
  }
}

/// Used for addresses screen.
class AddressesSkeleton extends StatelessWidget {
  const AddressesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: List.generate(4, (_) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              children: [
                ShimmerBox(width: 48.w, height: 48.w, radius: 12.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerLine(width: double.infinity, height: 14),
                      SizedBox(height: 6.h),
                      ShimmerLine(width: 200.w, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}

/// Used for search results.
class SearchResultsSkeleton extends StatelessWidget {
  final bool isMobile;
  const SearchResultsSkeleton({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: isMobile
          ? ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: const ProductCardSkeleton(isList: true),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final cols = screenWidth >= 900 ? 3 : 2;
                
                // Using the same formula from search web results
                final cardW = (screenWidth - (cols - 1) * 16.0 - 32) / cols;
                final cardH = cardW / kProductCardAspectRatio;

                return GridView.builder(
                  padding: EdgeInsets.all(16.w),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: cardW / cardH,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: cols == 3 ? 6 : 6,
                  itemBuilder: (_, __) => ShimmerBox(width: double.infinity, height: double.infinity, radius: 12.r),
                );
              }
            ),
    );
  }
}

/// Used for checkout screen.
class CheckoutSkeleton extends StatelessWidget {
  const CheckoutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: double.infinity, height: 80.h, radius: 12.r),
            SizedBox(height: 16.h),
            ShimmerBox(width: double.infinity, height: 120.h, radius: 12.r),
            SizedBox(height: 16.h),
            ShimmerBox(width: double.infinity, height: 80.h, radius: 12.r),
            SizedBox(height: 24.h),
            ShimmerLine(width: 160.w, height: 16),
            SizedBox(height: 12.h),
            const ShimmerLine(width: double.infinity, height: 14),
            SizedBox(height: 8.h),
            const ShimmerLine(width: double.infinity, height: 14),
            SizedBox(height: 8.h),
            ShimmerLine(width: 200.w, height: 14),
            SizedBox(height: 24.h),
            ShimmerBox(width: double.infinity, height: 56.h, radius: 14.r),
          ],
        ),
      ),
    );
  }
}
