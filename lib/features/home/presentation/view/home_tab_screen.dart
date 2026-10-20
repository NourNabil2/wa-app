import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fastway/features/home/presentation/widget/mobile_web_drawer.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/utils/slug_utils.dart';
// lib/features/home/presentation/view/home_tab_screen.dart
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fastway/core/layout/web_footer.dart';
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/core/responsive/max_width_container.dart';
import 'package:fastway/core/responsive/responsive_grid.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/home/presentation/widget/card/products_row.dart';
import 'package:fastway/features/home/presentation/widget/promo_banner.dart';
import 'package:fastway/features/home/domain/entities/mid_banner_entity.dart';
import 'package:fastway/features/home/presentation/widget/campaign_categories_row.dart';
import 'package:fastway/features/home/presentation/widget/categories_row.dart';
import 'package:fastway/features/user_data/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:fastway/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import '../../../../core/routes/routes.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/cubit/delivery_location/delivery_location_state.dart';
import '../widget/location_picker_sheet.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_state.dart';

class HomeTabScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  static bool isFirstAppLaunch = true;
  
  const HomeTabScreen({super.key, this.onSearchTap});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  int? _selectedCategoryIndex;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });

    final locState = context.read<DeliveryLocationCubit>().state;
    if (locState is DeliveryLocationResolved || locState is DeliveryLocationDenied) {
      context.read<HomeCubit>().loadHome();
    }
    // Refresh the unread count so the bell's red dot is accurate.
    // Guarded — the endpoint is auth-only (a guest call would 401).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.read<UserCubit>().isLoggedIn) {
          context.read<NotificationsCubit>().fetchUnreadCount();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isWeb => isWebLayout(context);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reload products whenever the selected delivery address changes.
    // This ensures express badges reflect the new location immediately.
    return BlocListener<DeliveryLocationCubit, DeliveryLocationState>(
      listenWhen: (prev, curr) {
        // Trigger load if location just finished resolving for the first time
        if ((prev is DeliveryLocationInitial || prev is DeliveryLocationLoading) && 
            (curr is DeliveryLocationResolved || curr is DeliveryLocationDenied)) {
          return true;
        }

        // Only reload if selectedAddress.id changed (not just label/zone updates)
        final prevAddr = (prev is DeliveryLocationResolved) ? prev.selectedAddress?.id : null;
        final currAddr = (curr is DeliveryLocationResolved) ? curr.selectedAddress?.id : null;
        return prevAddr != currAddr;
      },
      listener: (context, _) => context.read<HomeCubit>().loadHome(),
      child: Builder(builder: (context) {
        if (_isWeb) {
          return _DesktopHomeContent(
            selectedCategoryIndex: _selectedCategoryIndex,
            onCategoryTap: (cat, index) {
              setState(() => _selectedCategoryIndex = index);
              AppNavigator.pushNamed(context, '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}', arguments: cat);
            },
          );
        }
        return BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state is HomeLoaded || state is HomeError) {
              HomeTabScreen.isFirstAppLaunch = false;
            }
          },
          builder: (context, state) {
            final isLoading = state is HomeLoading || state is HomeInitial;

            if (isLoading && HomeTabScreen.isFirstAppLaunch) {
              return Scaffold(
                backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                body: Center(
                  child: Image.asset(
                    isDark ? Assets.logoHeader : Assets.logoApp,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
              ),
              child: Scaffold(
                backgroundColor:
                    isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
                endDrawer: kIsWeb ? const MobileWebDrawer() : null,
                extendBodyBehindAppBar: false,
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(130.h),
                  child: _MobileGlassHeader(scrollOffset: _scrollOffset),
                ),
                body: MediaQuery.removePadding(
                  context: context,
                  removeTop: false,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                            child: PromoBanner(
                              banners: state is HomeLoaded ? state.banners : const [],
                              onTap: () => AppNavigator.pushNamed(context, Routes.products),
                            ),
                          ),
                        ),
                        if (state is HomeLoaded && state.categories.isNotEmpty)
                          _sectionLabel('categories.title'.tr(), isDark: isDark),
                        SliverToBoxAdapter(
                          child: Builder(
                            builder: (context) {
                              final List<CategoryEntity> rawCategories = state is HomeLoaded ? state.categories : const [];
                              final List<CategoryEntity> flattenedCategories = rawCategories.expand((cat) {
                                if (cat.children.isNotEmpty) {
                                  return cat.children;
                                }
                                return [cat];
                              }).toList();

                              return CategoriesRow(
                                categories: flattenedCategories,
                                onTap: (cat) {
                                  if (cat.hasChildren) {
                                    AppNavigator.pushNamed(context, '${Routes.subCategories}/${cat.id}/sub', arguments: cat);
                                  } else {
                                    AppNavigator.pushNamed(context, '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}', arguments: cat);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        ..._buildContentSlivers(context, state),
                      ],
                    ),
                  ),
                ),
              ),
            );  // Scaffold
          },
        );      // BlocBuilder
      }),   // Builder
    );      // BlocListener
  }

  List<Widget> _buildContentSlivers(BuildContext context, HomeState state) {
    if (state is HomeLoading || state is HomeInitial) {
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              const PromoBannerSkeleton(),
              SizedBox(height: 24.h),
              SizedBox(
                height: 260.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      const Expanded(child: ProductCardSkeleton()),
                      SizedBox(width: 16.w),
                      const Expanded(child: ProductCardSkeleton()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ];
    }
    if (state is HomeError) {
      return [
        SliverToBoxAdapter(
            child: SizedBox(
                height: 300.h,
                child: _ErrorState(
                    message: state.message,
                    onRetry: () => context.read<HomeCubit>().loadHome())))
      ];
    }
    if (state is! HomeLoaded) return const [];

    void goProduct(String name, String id) =>
        AppNavigator.pushNamed(context, '${Routes.productDetails}/${SlugUtils.slugify(name, id)}');
    void goCategory(cat) {
      if (cat.hasChildren) {
        AppNavigator.pushNamed(context, '${Routes.subCategories}/${cat.id}/sub', arguments: cat);
      } else {
        AppNavigator.pushNamed(context, '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}', arguments: cat);
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      // 1 + 6. Interleaved Best Sellers & Campaign Categories
      // Pattern: product row → campaign pair → product row → …
      if (state.bestSellers.isNotEmpty) ...[
        _sectionLabel('home.bestSellers'.tr(),
          isDark: isDark,
          seeAllLabel: 'home.seeAll'.tr(),
          seeAll: () => AppNavigator.pushNamed(context, Routes.products, arguments: 'featured')),
        SliverToBoxAdapter(
          child: ProductsRow(
            products: state.bestSellers,
            onTap: goProduct,
            onShowAll: () => AppNavigator.pushNamed(context, Routes.products, arguments: 'featured'),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      if (state.campaignCategories.isNotEmpty) ...[
        _sectionLabel('home.campaigns'.tr(),
            isDark: isDark,
            seeAllLabel: 'home.seeAll'.tr(),
            seeAll: () => AppNavigator.pushNamed(context, Routes.products)),
        SliverToBoxAdapter(
          child: CampaignCategoriesRow(
            categories: state.campaignCategories,
            onTap: goCategory,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 3. Mid-banner ad (first banner) — prefer mobile-specific image, fall back to desktop
      if ((state.midBannersMobile.isNotEmpty && state.midBannersMobile[0] != null) ||
          (state.midBanners.isNotEmpty && state.midBanners[0] != null)) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _MidBanner(banner: state.midBannersMobile[0] ?? state.midBanners[0]!),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 4. Trending Now
      if (state.trendingProducts.isNotEmpty) ...[
        _sectionLabel('home.trendingNow'.tr(),
            isDark: isDark,
            seeAllLabel: 'home.seeAll'.tr(),
            seeAll: () => AppNavigator.pushNamed(context, Routes.products,
                arguments: 'trending')),
        SliverToBoxAdapter(
            child: ProductsRow(
                products: state.trendingProducts, onTap: goProduct)),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 5. Top Brands rail
      // Hidden per user request
      /*
      if (state.brands.isNotEmpty) ...[
        _sectionLabel('home.topBrands'.tr(), isDark: isDark),
        SliverToBoxAdapter(
          child: BrandsRail(
            brands: state.brands,
            onTap: (brand) => AppNavigator.pushNamed(
              context,
              '${Routes.brand}/${brand.id}',
              arguments: {
                'brandName': brand.name,
                'brandLogoUrl': brand.logoUrl,
              },
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],
      */

      if (state.newArrivals.isNotEmpty) ...[
        _sectionLabel('home.newArrivals'.tr(),
            isDark: isDark,
            seeAllLabel: 'home.seeAll'.tr(),
            seeAll: () => AppNavigator.pushNamed(context, Routes.products,
                arguments: 'newArrivals')),
        SliverToBoxAdapter(
            child: ProductsRow(products: state.newArrivals, onTap: goProduct)),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 8. Promo divider (mid banner 2) — prefer mobile-specific image
      if ((state.midBannersMobile.length > 1 && state.midBannersMobile[1] != null) ||
          (state.midBanners.length > 1 && state.midBanners[1] != null)) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _MidBanner(banner:
              (state.midBannersMobile.length > 1 ? state.midBannersMobile[1] : null) ??
              (state.midBanners.length > 1 ? state.midBanners[1] : null)!),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],
      SliverToBoxAdapter(child: SizedBox(height: 28.h)),

      // 9. Bundle Deals
      if (state.bundleProducts.isNotEmpty) ...[
        _sectionLabel('home.bundles'.tr(),
            isDark: isDark,
            seeAllLabel: 'home.seeAll'.tr(),
            seeAll: () => AppNavigator.pushNamed(context, Routes.products,
                arguments: 'bundle')),
        SliverToBoxAdapter(
            child:
                ProductsRow(products: state.bundleProducts, onTap: goProduct)),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 10. Third banner — prefer mobile-specific image
      if ((state.midBannersMobile.length > 2 && state.midBannersMobile[2] != null) ||
          (state.midBanners.length > 2 && state.midBanners[2] != null)) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _MidBanner(banner:
              (state.midBannersMobile.length > 2 ? state.midBannersMobile[2] : null) ??
              (state.midBanners.length > 2 ? state.midBanners[2] : null)!),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 28.h)),
      ],

      // 11. Buy Again
      if (state.buyAgain.isNotEmpty) ...[
        _sectionLabel('home.buyAgain'.tr(),
            isDark: isDark,
            seeAllLabel: 'home.seeAll'.tr(),
            seeAll: () => AppNavigator.pushNamed(context, Routes.products,
                arguments: 'buyAgain')),
        SliverToBoxAdapter(
            child: ProductsRow(products: state.buyAgain, onTap: goProduct)),
        SliverToBoxAdapter(child: SizedBox(height: 40.h)),
      ],

      // 12. Blog Section (fitway)
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _BlogSection(isDark: isDark),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 40.h)),

      SliverToBoxAdapter(child: SizedBox(height: 120.h)),
    ];
  }


  SliverToBoxAdapter _sectionLabel(String title,
      {required bool isDark, VoidCallback? seeAll, String? seeAllLabel}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (seeAll != null)
              GestureDetector(
                onTap: seeAll,
                child: Text(
                  seeAllLabel ?? 'common.seeAll'.tr(),
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: ColorsManager.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MID-PAGE ADVERTISEMENT BANNER  (single wide image OR 2-column grid)
// ═════════════════════════════════════════════════════════════════════════════
class _MidBanner extends StatelessWidget {
  final MidBannerEntity banner;
  const _MidBanner({required this.banner});

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _image(String url, {BoxFit fit = BoxFit.cover}) {
    return url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            memCacheWidth: 800,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorsManager.primaryColor, ColorsManager.primaryColor.withValues(alpha: 0.6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (banner.isGrid) {
      // Mobile: two 1:1 images side-by-side = 2:1 outer ratio
      return AspectRatio(
        aspectRatio: 2.0,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _launch(banner.linkUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(banner.imageUrl),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _launch(banner.linkUrl2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(banner.imageUrl2!),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile single: 16:9
    return GestureDetector(
      onTap: () => _launch(banner.linkUrl),
      child: AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _image(banner.imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROMO DIVIDER CARD
// ══════════════════════════════════════════════════════════════════════════════
class _PromoDividerCard extends StatelessWidget {
  final bool isDark;

  const _PromoDividerCard({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDark
                ? [
              const Color(0xFF1E3A5F),
              const Color(0xFF0D2137),
            ]
                : [
              const Color(0xFF10B981),
              const Color(0xFF059669),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Row(
          children: [
            const SizedBox(width: 20),

            const CustomIcon(
              assetPath: Assets.coinsIcon,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn Points on Every Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Redeem for exclusive discounts',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () {
                if (AuthGuard.check(context)) {
                  AppNavigator.pushNamed(context, Routes.points);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  !AuthGuard.isGuest(context)
                      ? 'common.details'.tr()
                      : 'errors.auth.action'.tr(),

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED HELPER — Web interleaved products + campaign pairs
// Accessible from both _HomeTabScreenState and _DesktopHomeContent.
// ═════════════════════════════════════════════════════════════════════════════


// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP HOME CONTENT — Rich Interleaved Layout
// ═════════════════════════════════════════════════════════════════════════════
class _DesktopHomeContent extends StatelessWidget {
  final int? selectedCategoryIndex;
  final void Function(dynamic category, int index) onCategoryTap;
  const _DesktopHomeContent(
      {this.selectedCategoryIndex, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        void goProduct(String name, String id) =>
            AppNavigator.pushNamed(context, '${Routes.productDetails}/${SlugUtils.slugify(name, id)}');
        void goCategory(cat) {
          if (cat.hasChildren) {
            AppNavigator.pushNamed(context, '${Routes.subCategories}/${cat.id}/sub', arguments: cat);
          } else {
            AppNavigator.pushNamed(context, '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}', arguments: cat);
          }
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isSmallScreen = screenWidth < 800;
        // 12% ratio padding — matches the navbar logo start/end point exactly on desktop.
        // 4% padding for small web screens.
        final homePad = isSmallScreen ? screenWidth * 0.04 : screenWidth < 1600 ? 32.0 : screenWidth * 0.12;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: CustomScrollView(
            primary: true,
            physics: const ClampingScrollPhysics(),
          slivers: [
            // Hero banner
            if (state is HomeLoaded)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isSmallScreen ? 0 : homePad, isSmallScreen ? 0 : 24, isSmallScreen ? 0 : homePad, 0),
                    child: PromoBanner(banners: state.banners),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isSmallScreen ? 0 : homePad, isSmallScreen ? 0 : 24, isSmallScreen ? 0 : homePad, 0),
                    child: const PromoBannerSkeleton(),
                  ),
                ),
              ),

            if (state is HomeLoading || state is HomeInitial)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: homePad),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        SizedBox(
                          height: 350,
                          child: Row(
                            children: [
                              Expanded(child: ProductCardSkeleton()),
                              SizedBox(width: 24),
                              Expanded(child: ProductCardSkeleton()),
                              SizedBox(width: 24),
                              Expanded(child: ProductCardSkeleton()),
                              SizedBox(width: 24),
                              Expanded(child: ProductCardSkeleton()),
                            ],
                          ),
                        ),
                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),

            if (state is HomeLoaded) ...[
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: homePad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // 1 + 6. Interleaved Best Sellers & Campaign Categories
                        if (state.bestSellers.isNotEmpty) ...[
                          _WebLabel('home.bestSellers'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(context, Routes.products, arguments: 'featured')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ProductsRow(
                              horizontalPadding: 0,
                              products: state.bestSellers,
                              onTap: goProduct,
                              onShowAll: () => Navigator.pushNamed(context, Routes.products, arguments: 'featured'),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                        
                        if (state.campaignCategories.isNotEmpty) ...[
                          _WebLabel('home.campaigns'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(context, Routes.products)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CampaignCategoriesRow(
                              horizontalPadding: 0,
                              categories: state.campaignCategories,
                              onTap: goCategory,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 3. Mid-banner ad — small browser windows prefer the
                        // uploaded mobile banner and ignore the desktop one.
                        if ((state.midBannersMobile.isNotEmpty && state.midBannersMobile[0] != null) ||
                            (state.midBanners.isNotEmpty && state.midBanners[0] != null)) ...[
                          _WebMidBanner(
                            banner: state.midBanners.isNotEmpty ? state.midBanners[0] ?? state.midBannersMobile[0]! : state.midBannersMobile[0]!,
                            mobileBanner: state.midBannersMobile.isNotEmpty ? state.midBannersMobile[0] : null,
                            isSmallScreen: isSmallScreen,
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 4. Trending Now
                        if (state.trendingProducts.isNotEmpty) ...[
                          _WebLabel('home.trendingNow'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(
                                  context, Routes.products,
                                  arguments: 'trending')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ProductsRow(
                              horizontalPadding: 0,
                              products: state.trendingProducts,
                              onTap: goProduct,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 5. Top Brands rail — no See All
                        // Hidden per user request
                        /*
                        if (state.brands.isNotEmpty) ...[
                          _WebLabel('home.topBrands'.tr(), isDark: isDark),
                          const SizedBox(height: 16),
                          BrandsRail(
                            horizontalPadding: 0,
                            brands: state.brands,
                            onTap: (brand) => AppNavigator.pushNamed(
                              context,
                              '${Routes.brand}/${brand.id}',
                              arguments: {
                                'brandName': brand.name,
                                'brandLogoUrl': brand.logoUrl,
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                        */

                        // 7. New Arrivals — only shown when data exists
                        if (state.newArrivals.isNotEmpty) ...[
                          _WebLabel('home.newArrivals'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(
                                  context, Routes.products,
                                  arguments: 'newArrivals')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ProductsRow(
                              horizontalPadding: 0,
                              products: state.newArrivals,
                              onTap: goProduct,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 8. Points promo divider (mid banner 2)
                        if ((state.midBannersMobile.length > 1 && state.midBannersMobile[1] != null) ||
                            (state.midBanners.length > 1 && state.midBanners[1] != null)) ...[
                          _WebMidBanner(
                            banner: (state.midBanners.length > 1 ? state.midBanners[1] : null) ??
                                state.midBannersMobile[1]!,
                            mobileBanner: state.midBannersMobile.length > 1 ? state.midBannersMobile[1] : null,
                            isSmallScreen: isSmallScreen,
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 9. Bundle Deals
                        if (state.bundleProducts.isNotEmpty) ...[
                          _WebLabel('home.bundles'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(
                                  context, Routes.products,
                                  arguments: 'bundle')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ProductsRow(
                              horizontalPadding: 0,
                              products: state.bundleProducts,
                              onTap: goProduct,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],


                        // 10. Third banner
                        if ((state.midBannersMobile.length > 2 && state.midBannersMobile[2] != null) ||
                            (state.midBanners.length > 2 && state.midBanners[2] != null)) ...[
                          _WebMidBanner(
                            banner: (state.midBanners.length > 2 ? state.midBanners[2] : null) ??
                                state.midBannersMobile[2]!,
                            mobileBanner: state.midBannersMobile.length > 2 ? state.midBannersMobile[2] : null,
                            isSmallScreen: isSmallScreen,
                          ),
                          const SizedBox(height: 40),
                        ],

                        // 11. Buy Again
                        if (state.buyAgain.isNotEmpty) ...[
                          _WebLabel('home.buyAgain'.tr(),
                              isDark: isDark,
                              seeAllLabel: 'home.seeAll'.tr(),
                              seeAll: () => Navigator.pushNamed(
                                  context, Routes.products,
                                  arguments: 'buyAgain')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ProductsRow(
                              horizontalPadding: 0,
                              products: state.buyAgain,
                              onTap: goProduct,
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],

                        // 🆕 Blog Section (fitway)
                        _BlogSection(isDark: isDark),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            if (state is HomeError)
              SliverToBoxAdapter(
                child: SizedBox(
                    height: 400,
                    child: _ErrorState(
                        message: state.message,
                        onRetry: () => context.read<HomeCubit>().loadHome())),
              ),

            const SliverToBoxAdapter(child: WebFooter()),
          ],
        ),
        );
      },
    );
  }
}

// ── Web section label with accent bar ────────────────────────────────────────
class _WebLabel extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback? seeAll;
  final String? seeAllLabel;
  const _WebLabel(this.title, {required this.isDark, this.seeAll, this.seeAllLabel});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A)))),
          if (seeAll != null)
            TextButton(
              onPressed: seeAll,
              child: Text(seeAllLabel ?? 'common.seeAll'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ColorsManager.primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: ColorsManager.primaryColor)),
            ),
        ],
      );
}

// ── Web mid-banner (single wide image OR 2-column grid) ─────────────────────
class _WebMidBanner extends StatelessWidget {
  /// Desktop banner (wide / half-height design).
  final MidBannerEntity banner;

  /// Mobile-specific banner override. When the screen is small and this is
  /// non-null, it is shown INSTEAD of [banner] (the big desktop image is
  /// fully ignored) using the mobile aspect ratios.
  final MidBannerEntity? mobileBanner;

  /// True on phone-sized browser windows (web build only).
  final bool isSmallScreen;

  const _WebMidBanner({
    required this.banner,
    this.mobileBanner,
    this.isSmallScreen = false,
  });

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _image(String url) {
    return url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: 1200,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                ColorsManager.primaryColor,
                ColorsManager.primaryColor.withValues(alpha: 0.6),
              ]),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    // On small browser windows prefer the mobile-specific banner (full-height
    // ratios), falling back to the desktop banner only when no mobile image
    // was uploaded. On wide windows always use the desktop banner.
    final bool useMobile = isSmallScreen && mobileBanner != null;
    final MidBannerEntity active = useMobile ? mobileBanner! : banner;

    if (active.isGrid) {
      // Web wide: each cell 1:1 shown at half height → 4:1 outer ratio.
      // Mobile small: two 1:1 cells side-by-side at full height → 2:1.
      return AspectRatio(
        aspectRatio: useMobile ? 2.0 : 4.0,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _launch(active.linkUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(active.imageUrl),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _launch(active.linkUrl2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(active.imageUrl2!),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Single wide image — half height on web (32:9); 16:9 on small screens.
    return GestureDetector(
      onTap: () => _launch(active.linkUrl),
      child: AspectRatio(
        aspectRatio: useMobile ? 16.0 / 9.0 : 32.0 / 9.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _image(active.imageUrl),
        ),
      ),
    );
  }
}

// ── Web promo divider ────────────────────────────────────────────────────────
class _WebPromoDivider extends StatelessWidget {
  final bool isDark;

  const _WebPromoDivider({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E3A5F),
                    const Color(0xFF0D2137),
                  ]
                : [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 28),
            const Icon(Icons.monetization_on_rounded, size: 64, color: Color(0xFFFCB813)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn Points on Every Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Redeem for exclusive discounts and rewards',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (AuthGuard.check(context)) {
                  AppNavigator.pushNamed(context, Routes.points);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  !AuthGuard.isGuest(context) ? 'common.details'.tr() : 'errors.auth.action'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Web product grid helper ──────────────────────────────────────────────────
class _WebProductGrid extends StatelessWidget {
  final List<dynamic> products;
  final void Function(String name, String id) onTap;

  const _WebProductGrid({required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return ResponsiveGrid(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: kProductCardAspectRatio,
      children: products.asMap().entries.map((entry) {
        final p = entry.value;
        return HoverableCard(
          onTap: () => onTap(p.localizedName(locale), p.id),
          child: ProductCard(
            productId: p.id,
            name: p.localizedName(locale),
            imageUrl: p.imageUrl,
            price: p.price,
            originalPrice: p.originalPrice,
            rating: p.rating,
            reviewCount: p.reviewCount,
            isNew: p.isNew,
            isAvailable: p.isAvailable,
            isExpressEligible: p.isExpressEligible,
            isFeatured: p.isFeatured,
            stockWarning: p.stockWarning,
            pointsToEarn: p.pointsToEarn,
            onTap: () => onTap(p.localizedName(locale), p.id),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mobile Glass Header ──────────────────────────────────────────────────────
class _MobileGlassHeader extends StatelessWidget {
  final double scrollOffset;

  const _MobileGlassHeader({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Opacity increases as user scrolls from 0 to 250 pixels
    final double rawOpacity = (scrollOffset / 250).clamp(0.0, 1.0);
    final double opacity = rawOpacity;

    // Background color: transitions from transparent to scaffold color
    final scaffoldColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA);
    final Color bgColor = Color.lerp(
      scaffoldColor.withValues(alpha: 0.0), 
      scaffoldColor,
      opacity
    )!;
    
    // Icon and text color: permanently dark in light mode, white in dark mode
    final Color contentColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    // Search bar and icons background: transparent white
    final Color elementsBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12 * opacity, sigmaY: 12 * opacity),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8.h, 
            bottom: 12.h,
            left: 16.w,
            right: 16.w
          ),
          color: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Row: Location first (Right in RTL), Icons second (Left in RTL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Location Block
                  BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
                    builder: (context, state) {
                      String displayLabel = 'home.header_status.determining_location'.tr();
                      if (state is DeliveryLocationResolved) {
                        displayLabel = state.displayLabel;
                      } else if (state is DeliveryLocationDenied) {
                        displayLabel = 'home.not_selected'.tr();
                      }

                      return GestureDetector(
                        onTap: () => LocationPickerSheet.show(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 22.r,
                              color: contentColor,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'home.deliver_to'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: contentColor.withValues(alpha: 0.8),
                                height: 1.2,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              displayLabel.length > 15 ? '${displayLabel.substring(0, 15)}...' : displayLabel,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: contentColor,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16.r,
                              color: contentColor,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Icons Block
                  Row(
                    children: [
                      // Notification Bell (with unread red dot)
                      BlocBuilder<NotificationsCubit, NotificationsState>(
                        builder: (context, notifState) {
                          final hasUnread = notifState is NotificationsLoaded &&
                              notifState.unreadCount > 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildCircularIcon(
                                icon: Icons.notifications_none_rounded,
                                color: contentColor,
                                bgColor: elementsBgColor,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const FractionallySizedBox(
                                      heightFactor: 0.9,
                                      child: NotificationsScreen(asBottomSheet: true),
                                    ),
                                  );
                                },
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: elementsBgColor, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(width: 8.w),
                      // Support / WhatsApp
                      _buildCircularIcon(
                        icon: Icons.support_agent_rounded, 
                        color: contentColor, 
                        bgColor: elementsBgColor,
                        onTap: () async {
                          final whatsappUrl = Uri.parse('whatsapp://send?phone=966509926081');
                          final webUrl = Uri.parse('https://wa.me/966509926081');
                          
                          try {
                            bool launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                            if (!launched) {
                              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {
                            await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              
              // 2. Bottom Row: Search Bar
              GestureDetector(
                onTap: () {
                  // Navigate to search
                  AppNavigator.pushNamed(context, Routes.search);
                },
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: elementsBgColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'home.search'.tr(),
                          style: TextStyle(
                            color: contentColor.withValues(alpha: 0.7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.search_rounded, color: contentColor, size: 20.r),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIcon({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 20.r,
          ),
        ),
      ),
    );
  }
}

// ── Icon Button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _IconBtn({required this.icon, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          shape: BoxShape.circle, // حولناه لدائرة عشان يليق مع ال
          // تصميم الجديد
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          ),
          // BoxShadow removed from web nav button
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22.r,
            color: iconColor ?? (isDark ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: ColorsManager.errorFill),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEB BLOG SECTION — Magazine-style featured + grid layout
// ═══════════════════════════════════════════════════════════════════════════

const _kBlogAccents = <Color>[
  Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6),
  Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF06B6D4),
];

class _BlogSection extends StatefulWidget {
  final bool isDark;
  const _BlogSection({required this.isDark});

  @override
  State<_BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<_BlogSection> {
  late final BlogCubit _cubit;
  List<BlogPost> _posts = [];
  bool _loaded = false;
  late final StreamSubscription<BlogState> _sub;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BlogCubit>();

    final s = _cubit.state;
    if (s is BlogLoaded) {
      _posts  = s.posts.take(4).toList();
      _loaded = true;
    } else if (s is BlogError) {
      _loaded = true;
    }

    _sub = _cubit.stream.listen((s) {
      if (!mounted) return;
      if (s is BlogLoaded) {
        setState(() {
          _posts  = s.posts.take(4).toList();
          _loaded = true;
        });
      } else if (s is BlogError) {
        setState(() => _loaded = true);
      }
    });

    if (_cubit.state is BlogInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cubit.loadPosts();
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    final isAr  = Localizations.localeOf(context).languageCode == 'ar';

    if (!_loaded) return _BlogSectionSkeleton(isDark: widget.isDark);
    if (_posts.isEmpty) return const SizedBox.shrink();

    final big  = _posts[0];
    final rest = _posts.length > 1 ? _posts.sublist(1) : <BlogPost>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Expanded(
              child: Text(
                'fitway',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => AppNavigator.pushNamed(context, Routes.blog),
              child: Text(
                'home.view_all_posts'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: amber),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card grid — responsive
        LayoutBuilder(
          builder: (ctx, box) {
            final isNarrow = box.maxWidth < 700;

            if (isNarrow) {
              return Column(
                children: [
                  SizedBox(
                    height: 240,
                    child: _BigBlogCard(post: big, accent: _kBlogAccents[0], isDark: widget.isDark, isAr: isAr),
                  ),
                  ...rest.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 100,
                      child: _SmallBlogCard(
                        post:   e.value,
                        accent: _kBlogAccents[(e.key + 1) % _kBlogAccents.length],
                        isDark: widget.isDark,
                        isAr:   isAr,
                      ),
                    ),
                  )),
                ],
              );
            }

            return SizedBox(
              height: 340,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _BigBlogCard(post: big, accent: _kBlogAccents[0], isDark: widget.isDark, isAr: isAr),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: rest.asMap().entries.map((e) {
                          final isLast = e.key == rest.length - 1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                              child: _SmallBlogCard(
                                post:   e.value,
                                accent: _kBlogAccents[(e.key + 1) % _kBlogAccents.length],
                                isDark: widget.isDark,
                                isAr:   isAr,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Skeleton shown while blog posts are loading ────────────────────────────────
class _BlogSectionSkeleton extends StatelessWidget {
  final bool isDark;
  const _BlogSectionSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 22, width: 160, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero)),
        const SizedBox(height: 20),
        SizedBox(
          height: 340,
          child: Row(
            children: [
              Expanded(flex: 5, child: Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero))),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(children: [
                  Expanded(child: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero))),
                  Expanded(child: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero))),
                  Expanded(child: Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero))),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Big (left) blog card ───────────────────────────────────────────────────────
class _BigBlogCard extends StatefulWidget {
  final BlogPost post;
  final Color    accent;
  final bool     isDark;
  final bool     isAr;
  const _BigBlogCard({required this.post, required this.accent, required this.isDark, required this.isAr});
  @override State<_BigBlogCard> createState() => _BigBlogCardState();
}

class _BigBlogCardState extends State<_BigBlogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p       = widget.post;
    final isAr    = widget.isAr;
    final title   = isAr ? p.titleAr   : p.title;
    final excerpt = isAr ? p.excerptAr : p.excerpt;
    final cat     = isAr ? (p.categoryNameAr ?? p.categoryName ?? '') : (p.categoryName ?? '');

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, '/blog/${p.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // BoxShadow removed from blog card hover
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  // Image or gradient fallback
                  Positioned.fill(
                    child: p.coverImage != null
                        ? CachedNetworkImage(
                              imageUrl:    p.coverImage!,
                              fit:         BoxFit.cover,
                              memCacheWidth: 600,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              errorWidget: (_, __, ___) => _BlogPlaceholder(accent: widget.accent),
                          )
                        : _BlogPlaceholder(accent: widget.accent),
                  ),
                  // Dark gradient overlay
                  Positioned.fill(
                    child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.78), Colors.black.withValues(alpha: 0.08)],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ))),
                  ),
                  // Text content
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (cat.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(8)),
                          child: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      const SizedBox(height: 10),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.3,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
                      const SizedBox(height: 8),
                      Text(excerpt, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small (right) blog cards ───────────────────────────────────────────────────
class _SmallBlogCard extends StatefulWidget {
  final BlogPost post;
  final Color    accent;
  final bool     isDark;
  final bool     isAr;
  const _SmallBlogCard({required this.post, required this.accent, required this.isDark, required this.isAr});
  @override State<_SmallBlogCard> createState() => _SmallBlogCardState();
}

class _SmallBlogCardState extends State<_SmallBlogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p   = widget.post;
    final isAr = widget.isAr;
    final title = isAr ? p.titleAr   : p.title;
    final cat   = isAr ? (p.categoryNameAr ?? p.categoryName ?? '') : (p.categoryName ?? '');

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, '/blog/${p.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isDark ? ColorsManager.surfaceDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? widget.accent.withValues(alpha: 0.4) : Colors.transparent),
            // BoxShadow removed from blog list card hover
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Thumbnail
            ClipRRect(
              borderRadius: isAr ? const BorderRadius.horizontal(right: Radius.circular(16)) : const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                child: p.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl:    p.coverImage!,
                        fit:         BoxFit.cover,
                        memCacheWidth: 180,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        errorWidget: (_, __, ___) => _BlogPlaceholder(accent: widget.accent, mini: true),
                      )
                    : _BlogPlaceholder(accent: widget.accent, mini: true),
              ),
            ),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (cat.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: widget.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.zero),
                      child: Text(cat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: widget.accent)),
                    ),
                  const SizedBox(height: 5),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3,
                          color: _hovered ? widget.accent : (widget.isDark ? Colors.white : const Color(0xFF1A1A1A)))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Gradient placeholder for posts without a cover image ──────────────────────
class _BlogPlaceholder extends StatelessWidget {
  final Color accent;
  final bool  mini;
  const _BlogPlaceholder({required this.accent, this.mini = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.7), accent.withValues(alpha: 0.35)],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_rounded,
          size:  mini ? 28 : 56,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

