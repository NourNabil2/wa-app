import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/features/profile/data/models/profile_model.dart';
import 'package:image_picker/image_picker.dart';

import '../../../checkout/data/models/checkout_model.dart'; // ProfileModel

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile({String? name, String? phone});
  Future<ProfileModel> uploadAvatar(XFile avatar);
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> addAddress(Map<String, dynamic> body);
  Future<AddressModel> updateAddress(String id, Map<String, dynamic> body);
  Future<void> deleteAddress(String id);
  Future<AddressModel> setDefaultAddress(String id);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<Map<String, dynamic>> lookupAddress(String shortAddress);
  Future<AddressModel?> getNearestAddress(double lat, double lng);
  Future<void> deleteAccount();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final BaseApiServices _api;
  ProfileRemoteDataSourceImpl(this._api);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.profile,
      );
      return ProfileModel.fromJson(res['data'] ?? res);
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'PROFILE_FETCH_ERROR');
    }
  }

  @override
  Future<ProfileModel> updateProfile({String? name, String? phone}) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      };
      final res = await _api.request(
        method: HttpMethod.put,
        url: Endpoints.profile,
        body: body,
      );
      return ProfileModel.fromJson(res['data'] ?? res);
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'PROFILE_UPDATE_ERROR');
    }
  }

  @override
  Future<ProfileModel> uploadAvatar(XFile avatar) async {
    try {
      final bytes = await avatar.readAsBytes();
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          bytes,
          filename: avatar.name.isNotEmpty ? avatar.name : 'avatar.jpg',
        ),
      });
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.profileAvatar,
        body: formData,
      );
      return ProfileModel.fromJson(res['data'] ?? res);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'AVATAR_UPLOAD_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'AVATAR_UPLOAD_ERROR');
    }
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.addresses,
      );
      final list = (res['data'] ?? res) as List;
      return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ADDRESSES_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ADDRESSES_FETCH_ERROR');
    }
  }

  @override
  Future<AddressModel> addAddress(Map<String, dynamic> body) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.addresses,
        body: body,
      );
      return AddressModel.fromJson(res['data'] ?? res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'ADD_ADDRESS_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'ADD_ADDRESS_ERROR');
    }
  }

  @override
  Future<AddressModel> updateAddress(String id, Map<String, dynamic> body) async {
    try {
      final res = await _api.request(
        method: HttpMethod.put,
        url: '${Endpoints.addresses}/$id',
        body: body,
      );
      return AddressModel.fromJson(res['data'] ?? res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'UPDATE_ADDRESS_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'UPDATE_ADDRESS_ERROR');
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await _api.request(
        method: HttpMethod.delete,
        url: '${Endpoints.addresses}/$id',
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'DELETE_ADDRESS_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'DELETE_ADDRESS_ERROR');
    }
  }

  @override
  Future<AddressModel> setDefaultAddress(String id) async {
    try {
      final res = await _api.request(
        method: HttpMethod.put,
        url: '${Endpoints.addresses}/$id/default',
      );
      return AddressModel.fromJson(res['data'] ?? res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'SET_DEFAULT_ADDRESS_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'SET_DEFAULT_ADDRESS_ERROR');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.profile}/change-password',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CHANGE_PASSWORD_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> lookupAddress(String shortAddress) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.addressLookup}?short_address=$shortAddress',
      );
      return (res['data'] ?? res) as Map<String, dynamic>;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'LOOKUP_ADDRESS_ERROR');
    }
  }

  @override
  Future<AddressModel?> getNearestAddress(double lat, double lng) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.nearestAddress}?lat=$lat&lng=$lng',
      );
      final data = res['data'];
      if (data == null) return null;
      return AddressModel.fromJson(data);
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'NEAREST_ADDRESS_ERROR');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _api.request(
        method: HttpMethod.delete,
        url: Endpoints.deleteAccount,
      );
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'DELETE_ACCOUNT_ERROR');
    }
  }
}
