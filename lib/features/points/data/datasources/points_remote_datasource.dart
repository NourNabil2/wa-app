import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/features/points/data/models/points_model.dart'; // PointsSummaryModel + RewardModel

abstract class PointsRemoteDataSource {
  Future<PointsSummaryModel> getPointsSummary();
  Future<List<PointsHistoryModel>> getPointsHistory(int page);
}

class PointsRemoteDataSourceImpl implements PointsRemoteDataSource {
  final BaseApiServices _api;
  PointsRemoteDataSourceImpl(this._api);

  @override
  Future<PointsSummaryModel> getPointsSummary() async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.points,
      );
      return PointsSummaryModel.fromJson(res['data'] ?? res);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'POINTS_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'POINTS_FETCH_ERROR');
    }
  }

  @override
  Future<List<PointsHistoryModel>> getPointsHistory(int page) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.points}/history?page=$page',
      );
      final List<dynamic> data = res['data'] ?? res['history'] ?? [];
      return data.map((e) => PointsHistoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'POINTS_HISTORY_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'POINTS_HISTORY_FETCH_ERROR');
    }
  }
}
