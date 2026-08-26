// lib/features/home/presentation/cubit/home_cubit.dart
import 'package:fastway/core/cubit/delivery_location/delivery_location_cubit.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_state.dart';
import 'package:fastway/core/services/location_service.dart';
import 'package:fastway/features/home/data/datasources/products_remote_datasource.dart';
import 'package:fastway/features/home/data/model/category_model.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/banner_entity.dart';
import 'package:fastway/features/home/domain/entities/mid_banner_entity.dart';
import 'package:fastway/features/home/domain/entities/brand_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';


class HomeCubit extends Cubit<HomeState> {
  final ProductsRemoteDataSource _remote;
  final DeliveryLocationCubit _locationCubit;

  HomeCubit(this._remote, this._locationCubit) : super(HomeInitial());

  Future<void> loadHome() async {
    emit(HomeLoading());
    try {
      // ── Resolve delivery location ────────────────────────────────────────────
      // Priority 1: selected address ID → backend middleware geocodes it precisely
      //             (overrides the default-address fallback on the server side)
      // Priority 2: GPS lat/lng → for guests or when no address is selected
      // Priority 3: nothing sent → backend falls back to the user's DEFAULT address
      //             (logged-in) or returns generic eligibility (guest, no GPS)
      final locState = _locationCubit.state;
      String? selectedAddressId;
      double? lat;
      double? lng;

      if (locState is DeliveryLocationResolved && locState.selectedAddress != null) {
        selectedAddressId = locState.selectedAddress!.id;
      } else {
        // No saved address selected — try GPS (works for guests + first load)
        try {
          final latLng = await LocationService.instance.getLatLng().timeout(const Duration(seconds: 4));
          lat = latLng['lat'];
          lng = latLng['lng'];
        } catch (_) {}
      }

      // Fetch home data and mobile-banners concurrently
      final dataFuture = _remote.getHome(
        addressId: selectedAddressId,
        lat: lat,
        lng: lng,
      ).timeout(const Duration(seconds: 15));
      
      final bannersFuture = _remote.getBanners().timeout(const Duration(seconds: 15));

      final results = await Future.wait([dataFuture, bannersFuture]);
      final data = results[0] as Map<String, dynamic>;
      final banners = results[1] as List<BannerEntity>;

      // We are using `banners` fetched from `/mobile-banners` (with fallback to `/banners`), 
      // ignoring the `banners` inside `/home` payload per user request.

      List<MidBannerEntity?> _parseMidBanners(List? raw) {
        final result = <MidBannerEntity?>[];
        if (raw == null) return result;
        for (var e in raw) {
          if (e != null) {
            result.add(MidBannerEntity(
              layout:    (e['layout'] ?? 'single') as String,
              imageUrl:  (e['image_url'] ?? '') as String,
              linkUrl:   e['link'] as String?,
              imageUrl2: e['image_url_2'] as String?,
              linkUrl2:  e['link_2'] as String?,
            ));
          } else {
            result.add(null);
          }
        }
        return result;
      }

      final midBanners = _parseMidBanners(data['mid_banners'] as List?);
      final midBannersMobile = _parseMidBanners(data['mid_banners_mobile'] as List?);

      final categories = (data['categories'] as List?)?.map((e) => CategoryModel.fromJson(e)).toList() ?? [];
      final campaignCategories = (data['campaign_categories'] as List?)?.map((e) => CategoryModel.fromJson(e)).toList() ?? [];

      final brands = (data['brands'] as List?)?.map((e) => BrandEntity(
        id: e['id'].toString(),
        name: (e['name'] ?? '') as String,
        nameAr: e['name_ar'] as String?,
        logoUrl: (e['logo_url'] ?? '') as String,
        country: e['country'] as String?,
      )).toList() ?? [];

      // API now returns brand_name directly (brand relation eager-loaded on backend)
      final bestSellers     = (data['featured_products']  as List?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final newArrivals     = (data['new_arrivals']        as List?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final trendingProducts= (data['trending_products']  as List?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final buyAgain        = (data['buy_again']           as List?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final bundleProducts  = (data['bundle_products']     as List?)?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];

      // ── Express zone detection ─────────────────────────────────────────────
      final allProducts = [
        ...bestSellers,
        ...newArrivals,
        ...trendingProducts,
        ...buyAgain,
        ...bundleProducts,
      ];
      final hasExpressProduct = allProducts.any((p) => p.isExpressEligible);
      _locationCubit.setExpressZone(hasExpressProduct);

      if (!isClosed) {
        emit(HomeLoaded(
          banners: banners,
          midBanners: midBanners.isNotEmpty ? midBanners : [null, null, null],
          midBannersMobile: midBannersMobile.isNotEmpty ? midBannersMobile : [null, null, null],
          categories: categories,
          campaignCategories: campaignCategories,
          bestSellers: bestSellers,
          newArrivals: newArrivals,
          trendingProducts: trendingProducts,
          buyAgain: buyAgain,
          brands: brands,
          bundleProducts: bundleProducts,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(HomeError(e.toString()));
    }
  }

  Future<T> _safeFetch<T>(Future<T> Function() fetch, T fallback) async {
    try {
      return await fetch();
    } catch (_) {
      return fallback;
    }
  }
}