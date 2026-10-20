import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/supabase/supabase_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/features/home/data/model/category_model.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/banner_entity.dart';
import '../../../../core/api/base_api_services.dart';
import '../../../../core/api/model/http_method.dart';
import '../../../../core/errors/exceptions.dart';

abstract class ProductsRemoteDataSource {
  Future<List<ProductModel>> getProducts({int page, int perPage});
  Future<List<ProductModel>> getFeatured();
  Future<List<ProductModel>> getNewArrivals();
  Future<List<CategoryModel>> getCategories();
  Future<List<BannerEntity>> getBanners();
  Future<Map<String, dynamic>> getHome({double? lat, double? lng, String? addressId});
  Future<Map<String, dynamic>> searchProducts(String query, {int page});
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final BaseApiServices _apiServices;

  ProductsRemoteDataSourceImpl(this._apiServices);

  List<ProductModel> get _dummyRosaryProducts {
    return List.generate(48, (index) {
      return ProductModel(
        id: 'rosary_${index + 1}',
        name: 'Premium Rosary ${index + 1}',
        nameAr: 'سبحة فاخرة ${index + 1}',
        imageUrl: 'assets/images/rosary_${index + 1}.jpeg',
        price: 99.0,
        originalPrice: 150.0,
        isAvailable: true,
        categoryId: '2',
        rating: 5.0,
        reviewCount: 12,
        isNew: true,
        isFeatured: true,
      );
    });
  }

  List<Map<String, dynamic>> get _dummyRosaryProductsJson {
    return _dummyRosaryProducts.map((e) => e.toJson()).toList();
  }

  Future<List<ProductModel>> _fetchProductsFromSupabase() async {
    try {
      final response = await SupabaseConfig.client
          .from('products')
          .select('*')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      final list = (response as List).map((row) {
        final images = (row['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final firstImage = images.isNotEmpty ? images.first : 'assets/images/rosary_1.jpeg';
        return ProductModel(
          id: row['id'].toString(),
          name: row['name_en'] ?? row['name_ar'] ?? '',
          nameAr: row['name_ar'],
          imageUrl: firstImage,
          price: (row['price'] as num?)?.toDouble() ?? 0.0,
          originalPrice: (row['original_price'] as num?)?.toDouble(),
          isAvailable: row['is_available'] as bool? ?? true,
          categoryId: row['category_id']?.toString() ?? '1',
          rating: (row['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
          isNew: row['is_new'] as bool? ?? true,
          isFeatured: row['is_featured'] as bool? ?? false,
        );
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[Supabase] Products error: $e');
      return _dummyRosaryProducts;
    }
  }

  Future<List<CategoryModel>> _fetchCategoriesFromSupabase() async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select('*')
          .order('sort_order', ascending: true);

      return (response as List).map((row) {
        return CategoryModel(
          id: row['id'].toString(),
          name: row['name_en'] ?? row['name_ar'] ?? '',
          nameAr: row['name_ar'] ?? '',
          iconUrl: row['image_url'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] Categories error: $e');
      return [];
    }
  }

  Future<List<BannerEntity>> _fetchBannersFromSupabase() async {
    try {
      final response = await SupabaseConfig.client
          .from('banners')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List).map((row) {
        return BannerEntity(
          id: row['id'].toString(),
          title: (row['title_en'] ?? '') as String,
          titleAr: (row['title_ar'] ?? '') as String,
          imageUrl: (row['image_url'] ?? '') as String,
          linkUrl: row['link_url'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Supabase] Banners error: $e');
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getProducts({int page = 1, int perPage = 10}) async {
    if (SupabaseConfig.isConfigured) {
      return _fetchProductsFromSupabase();
    }
    try {
      final list = await _processRequest<ProductModel>(
        url: Endpoints.products,
        queryParams: {'page': page, 'per_page': perPage},
        mapper: (json) => ProductModel.fromJson(json),
        errorLabel: 'PRODUCTS_FETCH_ERROR',
      );
      if (page == 1) list.insertAll(0, _dummyRosaryProducts);
      return list;
    } catch (_) {
      if (page == 1) return _dummyRosaryProducts;
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getFeatured() async {
    if (SupabaseConfig.isConfigured) {
      final all = await _fetchProductsFromSupabase();
      final featured = all.where((p) => p.isFeatured).toList();
      return featured.isNotEmpty ? featured : all;
    }
    try {
      final list = await _processRequest<ProductModel>(
        url: Endpoints.featured,
        mapper: (json) => ProductModel.fromJson(json),
        errorLabel: 'FEATURED_FETCH_ERROR',
      );
      list.insertAll(0, _dummyRosaryProducts);
      return list;
    } catch (_) {
      return _dummyRosaryProducts;
    }
  }

  @override
  Future<List<ProductModel>> getNewArrivals() async {
    if (SupabaseConfig.isConfigured) {
      return _fetchProductsFromSupabase();
    }
    try {
      final list = await _processRequest<ProductModel>(
        url: Endpoints.newArrivals,
        mapper: (json) => ProductModel.fromJson(json),
        errorLabel: 'NEW_ARRIVALS_FETCH_ERROR',
      );
      list.insertAll(0, _dummyRosaryProducts);
      return list;
    } catch (_) {
      return _dummyRosaryProducts;
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (SupabaseConfig.isConfigured) {
      final supaCats = await _fetchCategoriesFromSupabase();
      if (supaCats.isNotEmpty) return supaCats;
    }
    return _processRequest<CategoryModel>(
      url: Endpoints.categories,
      mapper: (json) => CategoryModel.fromJson(json),
      errorLabel: 'CATEGORIES_FETCH_ERROR',
    );
  }

  @override
  Future<List<BannerEntity>> getBanners() async {
    if (SupabaseConfig.isConfigured) {
      final supaBanners = await _fetchBannersFromSupabase();
      if (supaBanners.isNotEmpty) return supaBanners;
    }
    const primaryEndpoint = kIsWeb ? Endpoints.banners : Endpoints.mobileBanners;
    const fallbackEndpoint = kIsWeb ? Endpoints.mobileBanners : Endpoints.banners;

    try {
      final banners = await _processRequest<BannerEntity>(
        url: primaryEndpoint,
        mapper: (json) => BannerEntity(
          id: json['id'].toString(),
          title: (json['title'] ?? '') as String,
          titleAr: (json['title_ar'] ?? '') as String,
          imageUrl: (json['image_url'] ?? json['image'] ?? '') as String,
          linkUrl: json['link'] as String?,
        ),
        errorLabel: 'PRIMARY_BANNERS_FETCH_ERROR',
      );
      
      if (banners.isNotEmpty) {
        return banners;
      }
    } catch (_) {
      // Fallback if the endpoint fails (e.g., 404 or not implemented yet)
    }

    // Fallback to default banners
    return _processRequest<BannerEntity>(
      url: fallbackEndpoint,
      mapper: (json) => BannerEntity(
        id: json['id'].toString(),
        title: (json['title'] ?? '') as String,
        titleAr: (json['title_ar'] ?? '') as String,
          imageUrl: (json['image_url'] ?? json['image'] ?? '') as String,
        linkUrl: json['link'] as String?,
      ),
      errorLabel: 'FALLBACK_BANNERS_FETCH_ERROR',
    );
  }

  @override
  Future<Map<String, dynamic>> getHome({double? lat, double? lng, String? addressId}) async {
    try {
      final params = <String, dynamic>{};
      if (addressId != null) {
        params['address_id'] = addressId;
      } else if (lat != null && lng != null) {
        params['lat'] = lat;
        params['lng'] = lng;
      }
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: Endpoints.home,
        queryParams: params.isEmpty ? null : params,
      );
      final data = Map<String, dynamic>.from((response['data'] ?? response) as Map<String, dynamic>);
      
      // Inject dummy rosaries into home lists
      data['best_sellers'] = [...?data['best_sellers'], ..._dummyRosaryProductsJson];
      data['new_arrivals'] = [...?data['new_arrivals'], ..._dummyRosaryProductsJson];
      
      return data;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'HOME_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'HOME_FETCH_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> searchProducts(String query, {int page = 1}) async {
    try {
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: Endpoints.search,
        queryParams: {'q': query, 'page': page},
      );
      final data = Map<String, dynamic>.from((response['data'] ?? response) as Map<String, dynamic>);
      
      // If search query is empty or matches rosary, return them
      if (query.isEmpty || 'سبحة'.contains(query) || 'rosary'.contains(query.toLowerCase())) {
        if (page == 1) {
          data['products'] = [..._dummyRosaryProductsJson, ...?data['products']];
        }
      }
      return data;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'SEARCH_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'SEARCH_FETCH_ERROR');
    }
  }

  /// Generic Helper Method for API Requests
  Future<List<T>> _processRequest<T>({
    required String url,
    required T Function(Map<String, dynamic> json) mapper,
    required String errorLabel,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: url,
        queryParams: queryParams,
      );

      List<dynamic> data = [];

      if (response['data'] is List) {
        data = response['data'] as List<dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is List) {
        data = response['data']['data'] as List<dynamic>;
      }

      return data.map((item) => mapper(item as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), errorLabel);
    } catch (e) {
      throw ServerException(e.toString(), errorLabel);
    }
  }
}