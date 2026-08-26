import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import '../models/wishlist_item_model.dart';

abstract class WishlistRemoteDataSource {
  Future<WishlistModel> getWishlist();
  Future<Map<String, dynamic>> toggleWishlist(String productId);
  Future<int> removeItem(String wishlistItemId);
  Future<void> clearWishlist();
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final BaseApiServices _api;
  WishlistRemoteDataSourceImpl(this._api);

  @override
  Future<WishlistModel> getWishlist() async {
    try {
      final res = await _api.request(method: HttpMethod.get, url: Endpoints.wishlist);
      return WishlistModel.fromJson(res['data'] as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WISHLIST_GET_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WISHLIST_GET_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> toggleWishlist(String productId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.wishlistToggle,
        body: {'product_id': int.parse(productId)},
      );
      return res['data'] as Map<String, dynamic>;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WISHLIST_TOGGLE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WISHLIST_TOGGLE_ERROR');
    }
  }

  @override
  Future<int> removeItem(String wishlistItemId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.delete,
        url: '${Endpoints.wishlist}/$wishlistItemId',
      );
      return (res['data']?['count'] ?? 0) as int;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WISHLIST_REMOVE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WISHLIST_REMOVE_ERROR');
    }
  }

  @override
  Future<void> clearWishlist() async {
    try {
      await _api.request(method: HttpMethod.delete, url: Endpoints.wishlist);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WISHLIST_CLEAR_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WISHLIST_CLEAR_ERROR');
    }
  }
}
