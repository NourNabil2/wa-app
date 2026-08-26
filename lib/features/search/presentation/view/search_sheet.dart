import 'package:fastway/core/utils/slug_utils.dart';
// lib/features/search/presentation/view/search_sheet.dart
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/app_text_feild.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/search/presentation/cubit/search_cubit.dart';
import 'package:fastway/features/search/presentation/cubit/search_state.dart';
import 'package:fastway/features/search/presentation/widgets/animated_search_hint.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchSheet extends StatefulWidget {
  final bool isWebDropdown;
  final Function(String)? onSearchSelect;

  const SearchSheet({
    super.key,
    this.isWebDropdown = false,
    this.onSearchSelect,
  });

  static void show(BuildContext context) {
    final homeCubit = context.read<HomeCubit?>();

    Widget buildSheet(BuildContext ctx) {
      if (homeCubit != null) {
        return BlocProvider.value(
          value: homeCubit,
          child: const SearchSheet(),
        );
      }
      return const SearchSheet();
    }

    if (isWebLayout(context)) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(top: 80.h, left: 16.w, right: 16.w, bottom: 16.h),
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: buildSheet(ctx),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => buildSheet(ctx),
      );
    }
  }

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late SearchCubit _searchCubit;
  bool _isFocused = false;
  List<String> _recentSearches = [];

  final List<String> _searchHints = [
    'search.hints.whey_protein'.tr(),
    'search.hints.creatine'.tr(),
    'search.hints.bcaa'.tr(),
    'search.hints.energy_bar'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    try {
      _searchCubit = BlocProvider.of<SearchCubit>(context, listen: false);
    } catch (_) {
      _searchCubit = sl<SearchCubit>();
    }

    _loadRecentSearches();

    if (!widget.isWebDropdown) {
      _focusNode.addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });

      _controller.addListener(() {
        setState(() {});
      });
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _searchCubit.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    if (!widget.isWebDropdown) {
      _searchCubit.close();
    }
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchCubit.search(query);
  }

  void _onSearchSubmit(String query) async {
    if (query.trim().isNotEmpty) {
      if (!_recentSearches.contains(query.trim())) {
        setState(() {
          _recentSearches.insert(0, query.trim());
          if (_recentSearches.length > 6) _recentSearches.removeLast();
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('recent_searches', _recentSearches);
      }
      
      if (!widget.isWebDropdown) {
        Navigator.of(context).pop();
        AppNavigator.pushNamed(
          context,
          Routes.products,
          arguments: {
            'searchQuery': query.trim(),
          },
        );
        return;
      }
    }
    _searchCubit.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    if (widget.isWebDropdown) return _buildContent(isDark, isWeb, _scrollController);
    // Always wrap in Material so TextField has a valid Material ancestor,
    // whether shown as a web dialog, mobile bottom-sheet, or full-screen page.
    if (isWeb) {
      return Material(
        color: Colors.transparent,
        child: _buildContent(isDark, isWeb, _scrollController),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: SafeArea(
        child: _buildContent(isDark, isWeb, _scrollController),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isWeb, ScrollController scrollController) {
    return BlocProvider<SearchCubit>.value(
      value: _searchCubit,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: (isWeb || widget.isWebDropdown)
              ? BorderRadius.zero
              : const BorderRadius.vertical(top: Radius.zero),
          boxShadow: widget.isWebDropdown
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isWebDropdown) ...[
              if (!isWeb)
                Padding(
                  padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  child: Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: isWeb ? 24.h : 8.h),
                child: Row(
                  children: [
                    if (!isWeb)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(child: _buildSearchBar(isDark)),
                    if (isWeb)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                bloc: _searchCubit,
                builder: (context, state) {
                  return CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (state is SearchInitial)
                        SliverToBoxAdapter(
                            child: _buildInitialState(context, isDark)),
                      if (state is SearchLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: SearchResultsSkeleton(isMobile: true),
                          ),
                        ),
                      if (state is SearchError)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                    color: ColorsManager.errorText),
                              ),
                            ),
                          ),
                        ),
                      if (state is SearchLoaded && state.products.isEmpty)
                        SliverToBoxAdapter(
                            child: _buildEmptyResults(context, isDark)),
                      if (state is SearchLoaded && state.products.isNotEmpty)
                        SliverPadding(
                          padding: EdgeInsets.all(16.w),
                          sliver: _buildMobileResults(context, state.products),
                        ),
                      if (state is SearchLoaded && state.hasMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: SearchResultsSkeleton(isMobile: true),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
          borderRadius: isWebLayout(context) ? BorderRadius.zero : BorderRadius.circular(12.r),
        ),
        child: AppTextFieldFactory.search(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          hintText: 'search.hints.whey_protein'.tr(),
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmit,
          fillColor: Colors.transparent,
          focusedFillColor: Colors.transparent,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused ? ColorsManager.primaryColor : Colors.grey[400],
            size: 20.r,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, size: 18.r),
                  color: Colors.grey[400],
                  onPressed: () {
                    _controller.clear();
                    _searchCubit.search('');
                    _focusNode.requestFocus();
                  },
                )
              : null,
        ),
      ),
    );
  }

  List<String> get _popularSearches => [
        'search.suggestions.whey_protein'.tr(),
        'search.suggestions.creatine'.tr(),
        'search.suggestions.bcaa'.tr(),
        'search.suggestions.energy_bar'.tr(),
        'search.suggestions.vitamins'.tr(),
        'search.suggestions.omega3'.tr(),
        'search.suggestions.glutamine'.tr(),
        'search.suggestions.pre_workout'.tr(),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // Initial state — clean dropdown list, no icons, no chips
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInitialState(BuildContext context, bool isDark) {
    final homeCubit = context.read<HomeCubit?>();
    List<ProductEntity> trending = [];
    if (homeCubit?.state is HomeLoaded) {
      trending = (homeCubit!.state as HomeLoaded).trendingProducts;
    }

    final textColor = isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1A1A1A);
    final subColor  = isDark ? Colors.white38 : Colors.black38;
    final divColor  = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
    final bgColor   = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    void onTap(String query) {
      if (widget.isWebDropdown && widget.onSearchSelect != null) {
        widget.onSearchSelect!(query);
      } else {
        _controller.text = query;
        _onSearchChanged(query);
      }
    }

    final rows = <Widget>[];

    // ── Recent searches ──────────────────────────────────────────────────
    if (_recentSearches.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search.recentSearches'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  setState(() => _recentSearches.clear());
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('recent_searches');
                },
                child: Text(
                  'search.actions.clear'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColorsManager.errorFill,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      for (final q in _recentSearches) {
        rows.add(_DropdownRow(
          text: q,
          textColor: textColor,
          dividerColor: divColor,
          bgColor: bgColor,
          onTap: () => onTap(q),
        ));
      }
      rows.add(Divider(height: 1, thickness: 1, color: divColor));
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildEmptyResults(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64.r, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'search.noResults'.tr(namedArgs: {
              'query': widget.isWebDropdown ? '' : _controller.text
            }),
            style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWebResults(List<ProductEntity> products) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.crossAxisExtent;
        // Use actual browser window width to determine columns:
        // 4 columns on wide screens (≥900px), 2 columns on small screens
        final screenWidth = MediaQuery.sizeOf(context).width;
        final cols = screenWidth >= 900 ? 3 : 2;
        // Calculate exact cell width based on available grid width and spacing
        final cardW = (gridWidth - (cols - 1) * 16.0) / cols;
        // Use 0.65 aspect ratio to match standard product cards and prevent tall stretched cards
        final cardH = cardW / kProductCardAspectRatio;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cardW / cardH,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return HoverableCard(
                onTap: () {
                  if (!widget.isWebDropdown && isWebLayout(context)) {
                    Navigator.pop(context);
                  }
                  AppNavigator.pushNamed(context,
                      '${Routes.productDetails}/${SlugUtils.slugify(product.name, product.id)}');
                },
                child: _productCard(context, product, isCompact: false),
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }


  Widget _buildMobileResults(
      BuildContext context, List<ProductEntity> products) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _productCard(context, product, isCompact: true),
          );
        },
        childCount: products.length,
      ),
    );
  }

  ProductCard _productCard(BuildContext context, ProductEntity product, {bool isCompact = false}) {
    final locale = Localizations.localeOf(context).languageCode;
    return ProductCard(
      compact: isCompact,
      hideCartButton: true,
      hideFavoriteButton: true,
      productId: product.id,
      name: product.localizedName(locale),
      imageUrl: product.imageUrl,
      price: product.price,
      originalPrice: product.originalPrice,
      rating: null,
      reviewCount: null,
      isNew: product.isNew,
      titleFontSize: 14,
      priceFontSize: 13,
      priceFontWeight: FontWeight.bold,
      isAvailable: product.isAvailable,
      isExpressEligible: product.isExpressEligible,
      isFeatured: product.isFeatured,
      stockWarning: product.stockWarning,
      pointsToEarn: product.pointsToEarn,
      brandName: product.localizedBrandName(context.locale.languageCode),
      onTap: () {
        if (!widget.isWebDropdown && isWebLayout(context)) Navigator.pop(context);
        AppNavigator.pushNamed(context,
            '${Routes.productDetails}/${SlugUtils.slugify(product.name, product.id)}');
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Row — plain text, hover highlight, thin bottom divider
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownRow extends StatefulWidget {
  final String text;
  final Color textColor;
  final Color dividerColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _DropdownRow({
    required this.text,
    required this.textColor,
    required this.dividerColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_DropdownRow> createState() => _DropdownRowState();
}

class _DropdownRowState extends State<_DropdownRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SafeMouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? ColorsManager.primaryColor.withValues(alpha: 0.06)
              : widget.bgColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: widget.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
            ],
          ),
        ),
      ),
    );
  }
}