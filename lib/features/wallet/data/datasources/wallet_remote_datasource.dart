import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/features/wallet/data/models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary();
  Future<List<WalletHistoryModel>> getWalletHistory(int page);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final BaseApiServices _api;
  WalletRemoteDataSourceImpl(this._api);

  @override
  Future<WalletSummaryModel> getWalletSummary() async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.wallet,
      );
      return WalletSummaryModel.fromJson(res['data'] ?? res);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WALLET_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WALLET_FETCH_ERROR');
    }
  }

  @override
  Future<List<WalletHistoryModel>> getWalletHistory(int page) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.walletHistory}?page=$page',
      );
      final List<dynamic> data = res['data']?['history'] ?? res['history'] ?? [];
      return data.map((e) => WalletHistoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WALLET_HISTORY_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WALLET_HISTORY_FETCH_ERROR');
    }
  }
}
