// lib/features/home/presentation/view/products_list_screen.dart
//
// PRODUCTS PAGE — Sidebar Filter Layout (NiceOne/Noon inspired)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/layout/web_footer.dart';
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/core/widgets/empty_state_widget.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/core/widgets/shared_bottom_nav_bar.dart';
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/features/search/presentation/view/search_sheet.dart';
import 'package:fastway/features/home/data/model/filter_brand_model.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter/cupertino.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/cubit/delivery_location/delivery_location_state.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/brand/domain/entities/brand_entity.dart';
import 'package:fastway/features/brand/presentation/widgets/brand_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────────────────────────────────────
enum _SortOption { popular, priceLow, priceHigh, newest, rating }

extension _SortLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.popular:   return 'products.sort.popular'.tr();
      case _SortOption.priceLow:  return 'products.sort.price_low'.tr();
      case _SortOption.priceHigh: return 'products.sort.price_high'.tr();
      case _SortOption.newest:    return 'products.sort.newest'.tr();
      case _SortOption.rating:    return 'products.sort.rating'.tr();
    }
  }

  String get apiValue {
    switch (this) {
      case _SortOption.popular:   return 'popular';
      case _SortOption.priceLow:  return 'price_asc';
      case _SortOption.priceHigh: return 'price_desc';
      case _SortOption.newest:    return 'newest';
      case _SortOption.rating:    return 'rating';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProductsListScreen extends StatefulWidget {
  final CategoryEntity? category;
  final String? title;
  /// Pre-set type: 'bestSeller' | 'trending' | 'newArrivals' | 'buyAgain' | null
  final String? productType;
  final BrandEntity? brand;
  final String? searchQuery;

  const ProductsListScreen({super.key, this.category, this.title, this.productType, this.brand, this.searchQuery});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  // ── Products ──
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;
  int _total = 0;

  // ── Filters ──
  _SortOption _sort = _SortOption.popular;
  List<String> _selectedBrandIds = [];
  List<String> _selectedCategoryIds = [];
  List<String> _selectedGenders = [];
  bool _inStockOnly = false;
  bool _isFeatured = false;
  bool _isBundle = false;
  bool _isDiscounted = false;
  bool _boughtBefore = false;

  // ── Filter data (brands & categories for sidebar) ──
  List<FilterBrandModel> _brands = [];
  List<CategoryEntity> _categories = [];
  bool _filtersLoaded = false;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  double _lastScrollOffset = 0.0;
  late final BaseApiServices _api;

  @override
  void initState() {
    super.initState();
    if (widget.productType == 'bestSeller' || widget.productType == 'featured') {
      _isFeatured = true;
    }
    if (widget.productType == 'bundle') {
      _isBundle = true;
    }
    if (widget.productType == 'buyAgain') {
      _boughtBefore = true;
    }
    if (widget.brand != null) {
      _selectedBrandIds = [widget.brand!.id];
    }
    _api = GetIt.instance<BaseApiServices>();
    _scrollController.addListener(_onScroll);
    _loadProducts();
    _loadFilterData();
  }

  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    
    // FAB visibility logic
    if (currentScroll > 100 && currentScroll > _lastScrollOffset) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (currentScroll < _lastScrollOffset - 10) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
    _lastScrollOffset = currentScroll;

    // Load more logic
    if (currentScroll >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && !_isLoadingMore && _currentPage < _lastPage) {
        _loadProducts(page: _currentPage + 1, isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build query params from current filter state ──
  Map<String, dynamic> _buildQueryParams(int page) {
    final Map<String, dynamic> params = {
      'page': page,
      'per_page': 20,
      if (widget.category != null && _selectedCategoryIds.isEmpty)
        'category_id': widget.category!.id,
      if (_selectedCategoryIds.isNotEmpty) 'category_id': _selectedCategoryIds.join(','),
      if (_selectedBrandIds.isNotEmpty) 'brand_id': _selectedBrandIds.join(','),
      if (_selectedGenders.isNotEmpty) 'gender': _selectedGenders.join(','),
      if (_inStockOnly) 'in_stock': true,
      if (_isFeatured) 'is_featured': true,
      if (_isBundle) 'is_bundle': true,
      if (_isDiscounted) 'is_discounted': true,
      if (_boughtBefore) 'bought_before': true,
      if (_sort != _SortOption.popular) 'sort_by': _sort.apiValue,
      if (widget.productType == 'newArrivals') 'is_new': true,
      if (widget.productType == 'bestSeller') 'sort_by': 'popular',
      if (widget.productType == 'trending') 'sort_by': 'rating',
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) 'q': widget.searchQuery,
    };

    final locState = context.read<DeliveryLocationCubit>().state;
    if (locState is DeliveryLocationResolved) {
      if (locState.selectedAddress != null) {
        params['address_id'] = locState.selectedAddress!.id;
      } else if (locState.lat != null && locState.lng != null) {
        params['lat'] = locState.lat;
        params['lng'] = locState.lng;
      }
    }

    return params;
  }

  Future<void> _loadProducts({int page = 1, bool isLoadMore = false}) async {
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: widget.searchQuery != null && widget.searchQuery!.isNotEmpty ? Endpoints.search : Endpoints.products,
        queryParams: _buildQueryParams(page),
      );
      if (!mounted) return;

      final data = res['data'] as Map?;
      final rawList = (data?['products'] ?? data?['data'] ?? []) as List;
      final items = rawList
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .toList();

      final total   = (data?['total']     as num?)?.toInt() ?? items.length;
      final lastPg  = (data?['last_page'] as num?)?.toInt() ?? 1;

      setState(() {
        if (isLoadMore) {
          _products.addAll(items);
          _isLoadingMore = false;
        } else {
          _products = items;
          _isLoading = false;
        }
        _currentPage = page;
        _lastPage    = lastPg;
        _total       = total;
      });

      // Scroll to top when changing pages (not when loading more)
      if (!isLoadMore && _scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e.toString();
        if (isLoadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _loadFilterData() async {
    List<FilterBrandModel> brands = [];

    try {
      // Build query params — scope filters to the current category when available
      final Map<String, dynamic> params = {};
      if (widget.category != null) {
        params['category_id'] = widget.category!.id;
      }
      if (widget.brand != null) {
        params['brand_id'] = widget.brand!.id;
      }

      final filtersRes = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.productFilters,
        queryParams: params.isNotEmpty ? params : null,
      );

      final data = filtersRes['data'];

      // Parse brands from response
      final rawBrands = (data?['brands'] ?? []) as List;
      brands = rawBrands
          .map((b) => FilterBrandModel.fromJson(b as Map<String, dynamic>))
          .toList();

      // Optionally update gender options based on server response
      // (kept in Flutter state for now — server returns what's available)
    } catch (_) {
      // Fallback: pull from the home state brands (already loaded)
      if (mounted) {
        final homeState = context.read<HomeCubit>().state;
        if (homeState is HomeLoaded && homeState.brands.isNotEmpty) {
          brands = homeState.brands.map((b) => FilterBrandModel(
            id: b.id,
            name: b.name,
            nameAr: b.nameAr,
            logoUrl: b.logoUrl,
          )).toList();
        }
      }
    }

    if (mounted) {
      setState(() {
        _brands = brands;
        _filtersLoaded = true;
      });
    }
  }

  void _applyFilter() => _loadProducts(page: 1);

  void _clearFilters() {
    setState(() {
      _selectedBrandIds.clear();
      _selectedCategoryIds.clear();
      _selectedGenders.clear();
      _inStockOnly = false;
      _isFeatured = false;
      _isBundle = false;
      _isDiscounted = false;
      _boughtBefore = false;
      _sort = _SortOption.popular;
    });
    _loadProducts(page: 1);
  }

  int get _activeFilterCount {
    int count = 0;
    count += _selectedBrandIds.length;
    count += _selectedCategoryIds.length;
    count += _selectedGenders.length;
    if (_inStockOnly) count++;
    if (_isFeatured) count++;
    if (_isBundle) count++;
    if (_isDiscounted) count++;
    if (_boughtBefore) count++;
    if (_sort != _SortOption.popular) count++;
    return count;
  }

  String get _screenTitle {
    final locale = Localizations.localeOf(context).languageCode;
    
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return 'products.searchResultsFor'.tr(namedArgs: {'value': widget.searchQuery!});
    }

    if (widget.title != null) {
      final title = widget.title!;
      for (var c in _categories) {
        if (c.id == title) return c.localizedName(locale);
        for (var sub in c.children) {
          if (sub.id == title) return sub.localizedName(locale);
        }
      }
      for (var b in _brands) {
        if (b.id == title) return locale == 'ar' ? (b.nameAr ?? b.name) : b.name;
      }
      return title;
    }
    
    if (widget.category != null) {
      final cat = widget.category!;
      if (cat.name == cat.id) {
         for (var c in _categories) {
           if (c.id == cat.id) return c.localizedName(locale);
           for (var sub in c.children) {
             if (sub.id == cat.id) return sub.localizedName(locale);
           }
         }
      }
      return cat.localizedName(locale);
    }
    
    if (widget.productType == 'bestSeller') return 'home.bestSellers'.tr();
    if (widget.productType == 'trending') return 'home.trendingNow'.tr();
    if (widget.productType == 'newArrivals') return 'home.newArrivals'.tr();
    if (widget.productType == 'buyAgain') return 'home.buyAgain'.tr();

    return 'home.allProducts'.tr();
  }

  @override
  Widget build(BuildContext context) {
    // Pull categories from the home cubit (already loaded by the shell)
    final homeState = context.watch<HomeCubit>().state;
    if (homeState is HomeLoaded && _categories.isEmpty) {
      if (widget.category != null) {
        CategoryEntity? matchedCategory;
        for (var c in homeState.categories) {
          if (c.id == widget.category!.id) {
            matchedCategory = c;
            break;
          }
          for (var sub in c.children) {
            if (sub.id == widget.category!.id) {
              matchedCategory = sub;
              break;
            }
          }
          if (matchedCategory != null) break;
        }
        _categories = matchedCategory != null ? [matchedCategory] : [widget.category!];
      } else {
        _categories = homeState.categories;
      }
    }

    if (isWebLayout(context)) {
      return SimpleWebShell(
        showFooter: false,
        scrollController: _scrollController,
        content: _WebProductsPage(
          brand: widget.brand,
          screenTitle: _screenTitle,
          products: _products,
          total: _total,
          isLoading: _isLoading,
          isLoadingMore: _isLoadingMore,
          error: _error,
          onRetry: () => _loadProducts(page: 1),
          // Filter state
          brands: _brands,
          categories: _categories,
          filtersLoaded: _filtersLoaded,
          activeFilterCount: _activeFilterCount,
          sort: _sort,
          selectedBrandIds: _selectedBrandIds,
          selectedCategoryIds: _selectedCategoryIds,
          selectedGenders: _selectedGenders,
          inStockOnly: _inStockOnly,
          isFeatured: _isFeatured,
          isBundle: _isBundle,
          isDiscounted: _isDiscounted,
          boughtBefore: _boughtBefore,
          onSortChanged: (s) { setState(() => _sort = s); _applyFilter(); },
          onBrandChanged: (id) {
            setState(() {
              if (_selectedBrandIds.contains(id)) {
                _selectedBrandIds.remove(id);
              } else {
                _selectedBrandIds.add(id);
              }
            });
            _applyFilter();
          },
          onGenderChanged: (gender) {
            setState(() {
              if (_selectedGenders.contains(gender)) {
                _selectedGenders.remove(gender);
              } else {
                _selectedGenders.add(gender);
              }
            });
            _applyFilter();
          },
          onCategoryChanged: (id) {
            setState(() {
              // Find the category to determine children
              CategoryEntity? targetCat;
              for (var c in _categories) {
                if (c.id == id) { targetCat = c; break; }
                for (var sub in c.children) {
                   if (sub.id == id) { targetCat = sub; break; }
                }
                if (targetCat != null) break;
              }

              if (_selectedCategoryIds.contains(id)) {
                _selectedCategoryIds.remove(id);
                if (targetCat != null && targetCat.children.isNotEmpty) {
                  for (var sub in targetCat.children) {
                    _selectedCategoryIds.remove(sub.id);
                  }
                }
              } else {
                _selectedCategoryIds.add(id);
                if (targetCat != null && targetCat.children.isNotEmpty) {
                  for (var sub in targetCat.children) {
                    if (!_selectedCategoryIds.contains(sub.id)) _selectedCategoryIds.add(sub.id);
                  }
                }
              }
            });
            _applyFilter();
          },
          onInStockChanged: (v) { setState(() => _inStockOnly = v); _applyFilter(); },
          onFeaturedChanged: (v) { setState(() => _isFeatured = v); _applyFilter(); },
          onBundleChanged: (v) { setState(() => _isBundle = v); _applyFilter(); },
          onDiscountedChanged: (v) { setState(() => _isDiscounted = v); _applyFilter(); },
          onBoughtBeforeChanged: (v) { setState(() => _boughtBefore = v); _applyFilter(); },
          onClearFilters: _clearFilters,
          onShowMobileFilter: () => _showMobileFilterSheet(context),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF5F6FA),
      appBar: CustomAppBar(
        title: _screenTitle,
        action: IconButton(
          icon: Icon(Icons.search_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => SearchSheet.show(context),
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _isFabVisible ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 250),
        child: _FilterFab(
          activeFilterCount: _activeFilterCount,
          onTap: () => _showMobileFilterSheet(context),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildMobileBody(context),
      bottomNavigationBar: SharedBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          try {
            context.read<WebNavController>().navigateTo(index);
            Navigator.of(context).popUntil((route) => route.isFirst);
          } catch (_) {
            WebNavController.instance.navigateTo(index);
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        isDark: isDark,
      ),
    );
  }

  void _showMobileFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MobileFilterSheet(
        brand: widget.brand,
        brands: _brands,
        categories: _categories,
        sort: _sort,
        selectedBrandIds: _selectedBrandIds,
        selectedCategoryIds: _selectedCategoryIds,
        selectedGenders: _selectedGenders,
        inStockOnly: _inStockOnly,
        isFeatured: _isFeatured,
        isBundle: _isBundle,
        isDiscounted: _isDiscounted,
        boughtBefore: _boughtBefore,
        onApply: ({required sort, required brandIds, required categoryIds, required genders, required inStock, required isFeatured, required isBundle, required isDiscounted, required boughtBefore}) {
          setState(() {
            _sort = sort;
            _selectedBrandIds = brandIds;
            _selectedCategoryIds = categoryIds;
            _selectedGenders = genders;
            _inStockOnly = inStock;
            _isFeatured = isFeatured;
            _isBundle = isBundle;
            _isDiscounted = isDiscounted;
            _boughtBefore = boughtBefore;
          });
          _applyFilter();
        },
        onClear: _clearFilters,
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: kProductCardAspectRatio,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
    }

    if (_error != null && _products.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'errors.server.title'.tr(),
        subtitle: _error!,
        actionLabel: 'common.retry'.tr(),
        onActionPressed: () => _loadProducts(page: 1),
        enableBackButton: false,
      );
    }

    if (_products.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'products.empty'.tr(),
        subtitle: 'products.empty_sub'.tr(),
        enableBackButton: false,
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (widget.brand != null)
          SliverToBoxAdapter(
            child: BrandHeroHeader(
              brandName: locale == 'ar' ? (widget.brand!.nameAr ?? widget.brand!.name) : widget.brand!.name,
              logoUrl: widget.brand!.logoUrl,
              country: widget.brand!.country,
              total: widget.brand!.total,
              isDark: isDark,
              isAr: locale == 'ar',
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: _MobileSortButton(
                sort: _sort,
                onChanged: (s) { setState(() => _sort = s); _applyFilter(); },
                isDark: isDark,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: kProductCardAspectRatio,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final p = _products[i];
                return ProductCard(
                  productId: p.id, name: p.localizedName(locale), imageUrl: p.imageUrl,
                  price: p.price, originalPrice: p.originalPrice,
                  rating: p.rating, reviewCount: p.reviewCount,
                  isNew: p.isNew, isAvailable: p.isAvailable,
                  isExpressEligible: p.isExpressEligible,
                  isFeatured: p.isFeatured, stockWarning: p.stockWarning,
                  pointsToEarn: p.pointsToEarn,
                  brandName: p.localizedBrandName(context.locale.languageCode),
                  onTap: () => AppNavigator.pushNamed(context,
                      '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
                );
              },
              childCount: _products.length,
            ),
          ),
        ),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP PRODUCTS PAGE — Sidebar + Grid
// ═══════════════════════════════════════════════════════════════════════════════

class _WebProductsPage extends StatelessWidget {
  final BrandEntity? brand;
  final String screenTitle;
  final List<ProductModel> products;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final VoidCallback onRetry;

  // Filter state
  final List<FilterBrandModel> brands;
  final List<CategoryEntity> categories;
  final bool filtersLoaded;
  final int activeFilterCount;
  final _SortOption sort;
  final List<String> selectedBrandIds;
  final List<String> selectedCategoryIds;
  final List<String> selectedGenders;
  final bool inStockOnly;
  final bool isFeatured;
  final bool isBundle;
  final bool isDiscounted;
  final bool boughtBefore;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<bool> onInStockChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onBundleChanged;
  final ValueChanged<bool> onDiscountedChanged;
  final ValueChanged<bool> onBoughtBeforeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onShowMobileFilter;

  const _WebProductsPage({
    super.key,
    this.brand,
    required this.screenTitle,
    required this.products,
    required this.total,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.onRetry,
    required this.brands,
    required this.categories,
    required this.filtersLoaded,
    required this.activeFilterCount,
    required this.sort,
    required this.selectedBrandIds,
    required this.selectedCategoryIds,
    required this.selectedGenders,
    required this.inStockOnly,
    required this.isFeatured,
    required this.isBundle,
    required this.isDiscounted,
    required this.boughtBefore,
    required this.onSortChanged,
    required this.onBrandChanged,
    required this.onCategoryChanged,
    required this.onGenderChanged,
    required this.onInStockChanged,
    required this.onFeaturedChanged,
    required this.onBundleChanged,
    required this.onDiscountedChanged,
    required this.onBoughtBeforeChanged,
    required this.onClearFilters,
    required this.onShowMobileFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isSmallScreen = screenWidth < 800;
      final hPad = isSmallScreen ? screenWidth * 0.04 : screenWidth < 1600 ? 32.0 : screenWidth * 0.12;

      return Column(
          children: [
            if (brand != null)
              BrandHeroHeader(
                brandName: Localizations.localeOf(context).languageCode == 'ar' ? (brand!.nameAr ?? brand!.name) : brand!.name,
                logoUrl: brand!.logoUrl,
                country: brand!.country,
                total: brand!.total,
                isDark: isDark,
                isAr: Localizations.localeOf(context).languageCode == 'ar',
              ),
            // ── Top bar: breadcrumb + sort ──────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: isSmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Breadcrumb(categoryName: screenTitle, isDark: isDark),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: onShowMobileFilter,
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune_rounded, size: 16, color: isDark ? Colors.white : Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(
                                      'products.filter_title'.tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (activeFilterCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: ColorsManager.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$activeFilterCount',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            _SortDropdown(
                              sort: sort,
                              onChanged: onSortChanged,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _Breadcrumb(categoryName: screenTitle, isDark: isDark),
                        const Spacer(),
                        _SortDropdown(
                          sort: sort,
                          onChanged: onSortChanged,
                          isDark: isDark,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // ── Sidebar + grid ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Sidebar
                  if (!isSmallScreen) ...[
                    SizedBox(
                      width: 220,
                      child: _FilterSidebar(
                        brand: brand,
                        brands: brands,
                        categories: categories,
                        filtersLoaded: filtersLoaded,
                        activeFilterCount: activeFilterCount,
                        selectedBrandIds: selectedBrandIds,
                        selectedCategoryIds: selectedCategoryIds,
                        selectedGenders: selectedGenders,
                        inStockOnly: inStockOnly,
                        isFeatured: isFeatured,
                        isBundle: isBundle,
                        isDiscounted: isDiscounted,
                        boughtBefore: boughtBefore,
                        isDark: isDark,
                        onBrandChanged: onBrandChanged,
                        onCategoryChanged: onCategoryChanged,
                        onGenderChanged: onGenderChanged,
                        onInStockChanged: onInStockChanged,
                        onFeaturedChanged: onFeaturedChanged,
                        onBundleChanged: onBundleChanged,
                        onDiscountedChanged: onDiscountedChanged,
                        onBoughtBeforeChanged: onBoughtBeforeChanged,
                        onClearFilters: onClearFilters,
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],

                  // Products Grid
                  Expanded(
                    child: _buildProductArea(context, isDark),
                  ),
                ],
              ),
            ),

            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),

            const WebFooter(),
          ],
        );
    });
  }

  Widget _buildProductArea(BuildContext context, bool isDark) {
    if (isLoading) return _buildSkeleton();

    if (error != null && products.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'errors.server.title'.tr(),
        subtitle: error!,
        actionLabel: 'common.retry'.tr(),
        onActionPressed: onRetry,
        enableBackButton: false,
      );
    }

    if (products.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'products.empty'.tr(),
        subtitle: 'products.empty_sub'.tr(),
        enableBackButton: false,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductGrid(context),
      ],
    );
  }

  Widget _buildSkeleton() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 500 ? 6 : 2;
      const ratio = kProductCardAspectRatio;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: ratio,
          crossAxisSpacing: constraints.maxWidth > 500 ? 16 : 10,
          mainAxisSpacing: constraints.maxWidth > 500 ? 20 : 10,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
    });
  }

  Widget _buildProductGrid(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // Desktop (with sidebar ~248px) gets ~664px → show 6 cols
      // Mobile web gets ~400px → show 2 cols
      final cols = constraints.maxWidth > 500 ? 6 : 2;
      const ratio = kProductCardAspectRatio;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: ratio,
          crossAxisSpacing: constraints.maxWidth > 500 ? 16 : 10,
          mainAxisSpacing: constraints.maxWidth > 500 ? 20 : 10,
        ),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          final locale = Localizations.localeOf(context).languageCode;
          return HoverableCard(
            onTap: () => AppNavigator.pushNamed(context,
                '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
            child: ProductCard(
              productId: p.id, name: p.localizedName(locale), imageUrl: p.imageUrl,
              price: p.price, originalPrice: p.originalPrice,
              rating: p.rating, reviewCount: p.reviewCount,
              isNew: p.isNew, isAvailable: p.isAvailable,
              isExpressEligible: p.isExpressEligible,
              isFeatured: p.isFeatured, stockWarning: p.stockWarning,
              pointsToEarn: p.pointsToEarn,
              brandName: p.localizedBrandName(context.locale.languageCode),
              onTap: () => AppNavigator.pushNamed(context,
                  '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 200.ms);
        },
      );
    });
  }
}



// ═══════════════════════════════════════════════════════════════════════════════
// FILTER SIDEBAR — Collapsible accordion sections
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterSidebar extends StatefulWidget {
  final BrandEntity? brand;
  final List<FilterBrandModel> brands;
  final List<CategoryEntity> categories;
  final bool filtersLoaded;
  final int activeFilterCount;
  final List<String> selectedBrandIds;
  final List<String> selectedCategoryIds;
  final List<String> selectedGenders;
  final bool inStockOnly;
  final bool isFeatured;
  final bool isBundle;
  final bool isDiscounted;
  final bool boughtBefore;
  final bool isDark;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<bool> onInStockChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onBundleChanged;
  final ValueChanged<bool> onDiscountedChanged;
  final ValueChanged<bool> onBoughtBeforeChanged;
  final VoidCallback onClearFilters;

  const _FilterSidebar({
    required this.brands,
    required this.categories,
    required this.filtersLoaded,
    required this.activeFilterCount,
    required this.selectedBrandIds,
    required this.selectedCategoryIds,
    required this.selectedGenders,
    required this.inStockOnly,
    required this.isFeatured,
    required this.isBundle,
    required this.isDiscounted,
    required this.boughtBefore,
    required this.isDark,
    required this.onBrandChanged,
    required this.onCategoryChanged,
    required this.onGenderChanged,
    required this.onInStockChanged,
    required this.onFeaturedChanged,
    required this.onBundleChanged,
    required this.onDiscountedChanged,
    required this.onBoughtBeforeChanged,
    required this.onClearFilters,
    this.brand,
  });

  @override
  State<_FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<_FilterSidebar> {
  bool _brandsExpanded = false;
  bool _categoriesExpanded = false;
  bool _gendersExpanded = false;
  bool _availabilityExpanded = false;
  bool _quickFiltersExpanded = false;
  String _brandQuery = '';
  String _categoryQuery = '';

  @override
  Widget build(BuildContext context) {
    final sidebarBg = widget.isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        color: sidebarBg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.05),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'products.filter_by'.tr(),
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                if (widget.activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${widget.activeFilterCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
                const Spacer(),
                if (widget.activeFilterCount > 0)
                  GestureDetector(
                    onTap: widget.onClearFilters,
                    child: Text(
                      'products.filter_clear'.tr(),
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Categories Section ────────────────────────────────────────
          if (widget.categories.isNotEmpty) ...[
            _AccordionSection(
              title: 'dashboard.categories'.tr(),
              isExpanded: _categoriesExpanded,
              isDark: widget.isDark,
              onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
              child: !widget.filtersLoaded
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                  : widget.categories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text('—', style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38)))
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: SizedBox(
                                height: 36,
                                child: CupertinoSearchTextField(
                                  placeholder: 'products.search'.tr(),
                                  style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontSize: 13),
                                  onChanged: (v) => setState(() => _categoryQuery = v),
                                ),
                              ),
                            ),
                            ...widget.categories.where((c) {
                              if (_categoryQuery.isEmpty) return true;
                              final q = _categoryQuery.toLowerCase();
                              return c.name.toLowerCase().contains(q) || c.nameAr.toLowerCase().contains(q);
                            }).map((cat) {
                              final isAr = Localizations.localeOf(context).languageCode == 'ar';
                              final name = isAr ? cat.nameAr : cat.name;
                              final isSelected = widget.selectedCategoryIds.contains(cat.id);
                              return _FilterOptionTile(
                                label: name,
                                isSelected: isSelected,
                                isDark: widget.isDark,
                                onTap: () => widget.onCategoryChanged(cat.id),
                              );
                            }),
                          ],
                        ),
            ),
            Divider(height: 1, color: borderColor),
          ],

          // ── Brands Section ────────────────────────────────────────────
          if (widget.brand == null) ...[
          _AccordionSection(
            title: 'products.filter.brands'.tr(),
            isExpanded: _brandsExpanded,
            isDark: widget.isDark,
            onToggle: () => setState(() => _brandsExpanded = !_brandsExpanded),
            child: !widget.filtersLoaded
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
                : widget.brands.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text('—', style: TextStyle(
                            color: widget.isDark ? Colors.white38 : Colors.black38)))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: SizedBox(
                              height: 36,
                              child: CupertinoSearchTextField(
                                placeholder: 'products.search'.tr(),
                                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontSize: 13),
                                onChanged: (v) => setState(() => _brandQuery = v),
                              ),
                            ),
                          ),
                          ...widget.brands.where((b) {
                            if (_brandQuery.isEmpty) return true;
                            final q = _brandQuery.toLowerCase();
                            return b.localizedName('en').toLowerCase().contains(q) || b.localizedName('ar').toLowerCase().contains(q);
                          }).map((brand) {
                            final isAr = Localizations.localeOf(context).languageCode == 'ar';
                            final name = brand.localizedName(isAr ? 'ar' : 'en');
                            final isSelected = widget.selectedBrandIds.contains(brand.id);
                            return _FilterOptionTile(
                              label: name,
                              isSelected: isSelected,
                              isDark: widget.isDark,
                              onTap: () => widget.onBrandChanged(brand.id),
                            );
                          }),
                        ],
                      ),
          ),

          Divider(height: 1, color: borderColor),
          ],

          // ── Genders Section ───────────────────────────────────────────
          _AccordionSection(
            title: 'products.filter.gender'.tr(),
            isExpanded: _gendersExpanded,
            isDark: widget.isDark,
            onToggle: () => setState(() => _gendersExpanded = !_gendersExpanded),
            child: Column(
              children: ['male', 'female', 'unisex'].map((g) => _FilterOptionTile(
                label: 'products.filter.$g'.tr(),
                isSelected: widget.selectedGenders.contains(g),
                isDark: widget.isDark,
                onTap: () => widget.onGenderChanged(g),
              )).toList(),
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Availability Section ──────────────────────────────────────
          _AccordionSection(
            title: 'products.filter.availability'.tr(),
            isExpanded: _availabilityExpanded,
            isDark: widget.isDark,
            onToggle: () => setState(() => _availabilityExpanded = !_availabilityExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onInStockChanged(!widget.inStockOnly),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: widget.inStockOnly
                                ? ColorsManager.primary2Color
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: widget.inStockOnly
                                  ? ColorsManager.primary2Color
                                  : (widget.isDark ? Colors.white38 : Colors.black26),
                              width: 2,
                            ),
                          ),
                          child: widget.inStockOnly
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'products.filter.in_stock'.tr(),
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: widget.isDark ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Quick Filters ──────────────────────────────────────────
          _AccordionSection(
            title: 'products.filter.quick_filters'.tr(),
            isExpanded: _quickFiltersExpanded,
            isDark: widget.isDark,
            onToggle: () => setState(() => _quickFiltersExpanded = !_quickFiltersExpanded),
            child: Column(
              children: [
                _FilterOptionTile(
                  label: 'products.filter.featured'.tr(),
                  isSelected: widget.isFeatured,
                  isDark: widget.isDark,
                  onTap: () => widget.onFeaturedChanged(!widget.isFeatured),
                ),
                _FilterOptionTile(
                  label: 'products.filter.bundle'.tr(),
                  isSelected: widget.isBundle,
                  isDark: widget.isDark,
                  onTap: () => widget.onBundleChanged(!widget.isBundle),
                ),
                _FilterOptionTile(
                  label: 'products.filter.discounted'.tr(),
                  isSelected: widget.isDiscounted,
                  isDark: widget.isDark,
                  onTap: () => widget.onDiscountedChanged(!widget.isDiscounted),
                ),
                if (context.watch<AuthCubit>().state is AuthAuthenticated)
                  _FilterOptionTile(
                    label: 'products.filter.bought_before'.tr(),
                    isSelected: widget.boughtBefore,
                    isDark: widget.isDark,
                    onTap: () => widget.onBoughtBeforeChanged(!widget.boughtBefore),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCORDION SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AccordionSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;
  final Widget child;

  const _AccordionSection({
    required this.title,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 20,
                        color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: isExpanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER OPTION TILE — Radio-style checkmark row
// ─────────────────────────────────────────────────────────────────────────────
class _FilterOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterOptionTile({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? ColorsManager.primary2Color : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? ColorsManager.primary2Color
                        : (isDark ? Colors.white38 : Colors.black26),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? ColorsManager.primary2Color
                        : (isDark ? Colors.white70 : const Color(0xFF333333)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SORT DROPDOWN — Desktop top-right
// ═══════════════════════════════════════════════════════════════════════════════
class _SortDropdown extends StatelessWidget {
  final _SortOption sort;
  final ValueChanged<_SortOption> onChanged;
  final bool isDark;

  const _SortDropdown({required this.sort, required this.onChanged, required this.isDark});

  void _openMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<_SortOption>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      items: _SortOption.values.map((s) => PopupMenuItem<_SortOption>(
        value: s,
        height: 44,
        child: Row(
          children: [
            if (sort == s) ...[
              const Icon(Icons.check_rounded, size: 16, color: ColorsManager.primaryColor),
              const SizedBox(width: 8),
            ] else
              const SizedBox(width: 24),
            Flexible(
              child: Text(s.label, style: TextStyle(
                fontSize: 14,
                fontWeight: sort == s ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      )).toList(),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openMenu(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sort.label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                  color: isDark ? Colors.white54 : Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE FILTER SHEET
// ═══════════════════════════════════════════════════════════════════════════════
class _MobileFilterSheet extends StatefulWidget {
  final List<FilterBrandModel> brands;
  final List<CategoryEntity> categories;
  final _SortOption sort;
  final List<String> selectedBrandIds;
  final List<String> selectedCategoryIds;
  final List<String> selectedGenders;
  final bool inStockOnly;
  final void Function({
    required _SortOption sort,
    required List<String> brandIds,
    required List<String> categoryIds,
    required List<String> genders,
    required bool inStock,
    required bool isFeatured,
    required bool isBundle,
    required bool isDiscounted,
    required bool boughtBefore,
  }) onApply;
  final VoidCallback onClear;

  final bool isFeatured;
  final bool isBundle;
  final bool isDiscounted;
  final bool boughtBefore;
  final BrandEntity? brand;

  const _MobileFilterSheet({
    this.brand,
    required this.brands,
    required this.categories,
    required this.sort,
    required this.selectedBrandIds,
    required this.selectedCategoryIds,
    required this.selectedGenders,
    required this.inStockOnly,
    required this.isFeatured,
    required this.isBundle,
    required this.isDiscounted,
    required this.boughtBefore,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<_MobileFilterSheet> {
  late _SortOption _sort;
  late List<String> _brandIds;
  late List<String> _categoryIds;
  late List<String> _genders;
  late bool _inStock;
  late bool _isFeatured;
  late bool _isBundle;
  late bool _isDiscounted;
  late bool _boughtBefore;
  String _brandQuery = '';
  String _categoryQuery = '';

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _brandIds = List.from(widget.selectedBrandIds);
    _categoryIds = List.from(widget.selectedCategoryIds);
    _genders = List.from(widget.selectedGenders);
    _inStock = widget.inStockOnly;
    _isFeatured = widget.isFeatured;
    _isBundle = widget.isBundle;
    _isDiscounted = widget.isDiscounted;
    _boughtBefore = widget.boughtBefore;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.zero,
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
              child: Row(
                children: [
                  Text('products.filter_title'.tr(),
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      )),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text('products.filter_clear'.tr(),
                        style: const TextStyle(color: ColorsManager.primaryColor)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),
                  // Sort
                  Text('products.sort_by'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._SortOption.values.map((s) {
                    final isSelected = _sort == s;
                    return _FilterOptionTile(
                      label: s.label,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => setState(() => _sort = s),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Categories
                  if (widget.categories.isNotEmpty) ...[
                    Text('dashboard.categories'.tr(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: CupertinoSearchTextField(
                        placeholder: 'products.search'.tr(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                        onChanged: (v) => setState(() => _categoryQuery = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.categories.where((c) {
                      if (_categoryQuery.isEmpty) return true;
                      final q = _categoryQuery.toLowerCase();
                      return c.name.toLowerCase().contains(q) || c.nameAr.toLowerCase().contains(q);
                    }).map((c) {
                      final name = isAr ? c.nameAr : c.name;
                      final sel = _categoryIds.contains(c.id);
                      return _FilterOptionTile(
                          label: name, isSelected: sel, isDark: isDark,
                          onTap: () => setState(() {
                                if (sel) {
                                  _categoryIds.remove(c.id);
                                } else {
                                  _categoryIds.add(c.id);
                                }
                              }));
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Brands
                  if (widget.brand == null && widget.brands.isNotEmpty) ...[
                    Text('products.filter.brands'.tr(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: CupertinoSearchTextField(
                        placeholder: 'products.search'.tr(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                        onChanged: (v) => setState(() => _brandQuery = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.brands.where((b) {
                      if (_brandQuery.isEmpty) return true;
                      final q = _brandQuery.toLowerCase();
                      return b.localizedName('en').toLowerCase().contains(q) || b.localizedName('ar').toLowerCase().contains(q);
                    }).map((b) {
                      final name = b.localizedName(isAr ? 'ar' : 'en');
                      final sel = _brandIds.contains(b.id);
                      return _FilterOptionTile(
                          label: name, isSelected: sel, isDark: isDark,
                          onTap: () => setState(() {
                                if (sel) {
                                  _brandIds.remove(b.id);
                                } else {
                                  _brandIds.add(b.id);
                                }
                              }));
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Gender
                  Text('products.filter.gender'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...['male', 'female', 'unisex'].map((g) {
                    final sel = _genders.contains(g);
                    return _FilterOptionTile(
                        label: 'products.filter.$g'.tr(),
                        isSelected: sel,
                        isDark: isDark,
                        onTap: () => setState(() {
                              if (sel) {
                                _genders.remove(g);
                              } else {
                                _genders.add(g);
                              }
                            }));
                  }),
                  const SizedBox(height: 16),
                  // Availability
                  Text('products.filter.availability'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _FilterOptionTile(
                    label: 'products.filter.in_stock'.tr(),
                    isSelected: _inStock,
                    isDark: isDark,
                    onTap: () => setState(() => _inStock = !_inStock),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Filters
                  Text('products.filter.quick_filters'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _FilterOptionTile(
                    label: 'products.filter.featured'.tr(),
                    isSelected: _isFeatured,
                    isDark: isDark,
                    onTap: () => setState(() => _isFeatured = !_isFeatured),
                  ),
                  _FilterOptionTile(
                    label: 'products.filter.bundle'.tr(),
                    isSelected: _isBundle,
                    isDark: isDark,
                    onTap: () => setState(() => _isBundle = !_isBundle),
                  ),
                  _FilterOptionTile(
                    label: 'products.filter.discounted'.tr(),
                    isSelected: _isDiscounted,
                    isDark: isDark,
                    onTap: () => setState(() => _isDiscounted = !_isDiscounted),
                  ),
                  if (context.watch<AuthCubit>().state is AuthAuthenticated)
                    _FilterOptionTile(
                      label: 'products.filter.bought_before'.tr(),
                      isSelected: _boughtBefore,
                      isDark: isDark,
                      onTap: () => setState(() => _boughtBefore = !_boughtBefore),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Apply button
            AppButton(
              horizontalPadding: 20,
              verticalPadding: 20 + MediaQuery.viewInsetsOf(context).bottom,
              text: 'products.filter_apply'.tr(),
              backgroundColor: ColorsManager.primaryColor,
              onPressed: () {
                widget.onApply(
                  sort: _sort,
                  brandIds: _brandIds,
                  categoryIds: _categoryIds,
                  genders: _genders,
                  inStock: _inStock,
                  isFeatured: _isFeatured,
                  isBundle: _isBundle,
                  isDiscounted: _isDiscounted,
                  boughtBefore: _boughtBefore,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER FAB — Mobile floating button
// ─────────────────────────────────────────────────────────────────────────────
class _FilterFab extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onTap;
  const _FilterFab({required this.activeFilterCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: ColorsManager.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        label: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 16),
            const SizedBox(width: 4),
            Text('products.filter_by'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.zero),
                child: Text('$activeFilterCount',
                    style: const TextStyle(
                        color: ColorsManager.primaryColor, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE SORT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _MobileSortButton extends StatelessWidget {
  final _SortOption sort;
  final ValueChanged<_SortOption> onChanged;
  final bool isDark;

  const _MobileSortButton({required this.sort, required this.onChanged, required this.isDark});

  void _openMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<_SortOption>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      items: _SortOption.values
          .map((s) => PopupMenuItem<_SortOption>(
            value: s,
            height: 44,
            child: Text(s.label, style: TextStyle(
              fontSize: 14,
              fontWeight: sort == s ? FontWeight.w600 : FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ), overflow: TextOverflow.ellipsis),
          ))
          .toList(),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMenu(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16,
                color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(sort.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BREADCRUMB
// ─────────────────────────────────────────────────────────────────────────────
class _Breadcrumb extends StatelessWidget {
  final String categoryName;
  final bool isDark;
  const _Breadcrumb({required this.categoryName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dimColor = isDark ? Colors.white38 : Colors.black38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => AppNavigator.pushNamed(context, Routes.dashBoard),
            behavior: HitTestBehavior.opaque,
            child: Text('dashboard.home'.tr(), style: const TextStyle(
              fontSize: 13, color: ColorsManager.primaryColor, fontWeight: FontWeight.w600,
            )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: dimColor),
        ),
        Flexible(
          child: Text(categoryName, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
