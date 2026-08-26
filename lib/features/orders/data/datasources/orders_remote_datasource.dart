import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/features/orders/data/models/order_model.dart';


abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders({int page, int perPage});
  Future<OrderModel> getOrderDetails(String orderId);
  Future<OrderModel> trackOrder(String orderId);
  Future<void> cancelOrder(String orderId);
  Future<void> requestCancellation(String orderId, String reason);
  Future<void> confirmDelivery(String orderId);
  Future<void> submitStoreReview(String orderId, int rating, String? comment);
  Future<void> submitShipmentReview(String orderId, int rating, String? comment);
  Future<String> reorder(String orderId);
  Future<void> submitReturn({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  });
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final BaseApiServices _api;
  OrdersRemoteDataSourceImpl(this._api);

  @override
  Future<List<OrderModel>> getOrders({int page = 1, int perPage = 15}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.orders,
        queryParams: {'page': page, 'per_page': perPage},
      );

      // API returns: { status, message, data: { orders: [...], total, current_page, last_page } }
      final data = res['data'] as Map<String, dynamic>;
      final list = data['orders'] as List<dynamic>;

      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDERS_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDERS_FETCH_ERROR');
    }
  }

  @override
  Future<OrderModel> getOrderDetails(String orderId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.orders}/$orderId',
      );
      return OrderModel.fromJson(res['data'] ?? res);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_DETAIL_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_DETAIL_ERROR');
    }
  }

  @override
  Future<OrderModel> trackOrder(String orderId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.orders}/$orderId/track',
      );
      return OrderModel.fromJson(res['data'] ?? res);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_TRACK_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_TRACK_ERROR');
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/cancel',
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_CANCEL_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_CANCEL_ERROR');
    }
  }

  @override
  Future<void> requestCancellation(String orderId, String reason) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/request-cancellation',
        body: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_CANCEL_REQUEST_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_CANCEL_REQUEST_ERROR');
    }
  }

  @override
  Future<void> confirmDelivery(String orderId) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/confirm-delivery',
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_DELIVERY_CONFIRM_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_DELIVERY_CONFIRM_ERROR');
    }
  }

  @override
  Future<void> submitStoreReview(String orderId, int rating, String? comment) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/store-review',
        body: {'rating': rating, if (comment != null) 'comment': comment},
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'STORE_REVIEW_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'STORE_REVIEW_ERROR');
    }
  }

  @override
  Future<void> submitShipmentReview(String orderId, int rating, String? comment) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/shipment-review',
        body: {'rating': rating, if (comment != null) 'comment': comment},
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'SHIPMENT_REVIEW_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'SHIPMENT_REVIEW_ERROR');
    }
  }

  @override
  Future<String> reorder(String orderId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.orders}/$orderId/reorder',
      );
      return res['message'] as String? ?? 'Items added to cart successfully';
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_REORDER_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_REORDER_ERROR');
    }
  }

  @override
  Future<void> submitReturn({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  }) async {
    try {
      // Build multipart FormData so we can attach proof images
      final formData = FormData();
      formData.fields
        ..add(MapEntry('order_number', orderNumber))
        ..add(MapEntry('reason', reason));
      if (notes != null && notes.isNotEmpty) {
        formData.fields.add(MapEntry('notes', notes));
      }

      // Encode items array as indexed fields (Laravel reads items[0][field])
      for (int i = 0; i < items.length; i++) {
        items[i].forEach((key, value) {
          formData.fields.add(MapEntry('items[$i][$key]', value.toString()));
        });
      }

      // Attach proof images — detect MIME from bytes so Flutter Web blob URLs
      // (which have no file extension) get the correct content-type header.
      for (int i = 0; i < imagePaths.length; i++) {
        final bytes = await _readFileBytes(imagePaths[i]);
        final mime = _detectImageMime(bytes);
        final ext  = mime.split('/').last; // jpeg | png | webp
        final filename = 'image_$i.$ext';
        formData.files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mime),
          ),
        ));
      }

      await _api.request(
        method: HttpMethod.post,
        url: Endpoints.returns,
        body: formData,
      );
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ORDER_RETURN_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ORDER_RETURN_ERROR');
    }
  }

  /// Reads file bytes from path — works on both native and web via dart:io / XFile.
  Future<List<int>> _readFileBytes(String path) async {
    // image_picker on web returns a blob: URL; use XFile for cross-platform reading.
    final xfile = _XFileBridge(path);
    return xfile.readAsBytes();
  }

  /// Sniff MIME type from the first bytes of an image.
  /// Falls back to image/jpeg (the most common case).
  String _detectImageMime(List<int> bytes) {
    if (bytes.length >= 12) {
      // PNG: 89 50 4E 47
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // WebP: RIFF....WEBP
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
    }
    return 'image/jpeg';
  }
}

// Lightweight cross-platform file reader
class _XFileBridge {
  final String path;
  const _XFileBridge(this.path);

  Future<List<int>> readAsBytes() async {
    // On web, image_picker returns a blob URL stored as a path.
    // We use the cross_file package (already pulled by image_picker) to read it.
    final xfile = XFile(path);
    return xfile.readAsBytes();
  }
}
