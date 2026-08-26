import 'package:dartz/dartz.dart';
import '../../../../core/api/base_api_services.dart';
import '../../../../core/api/model/endpoints.dart';
import '../../../../core/api/model/http_method.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../user_data/user_repo.dart';
import '../model/auth_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BaseApiServices apiServices;
  final UserRepository userRepository;

  AuthRepositoryImpl({required this.apiServices, required this.userRepository});

  @override
  Future<Either<Failure, User>> login({
    required String email, // actually phone number from LoginScreen
    required String password, // ignored — OTP flow
  }) async {
    try {
      final response = await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.login,
        body: {'phone': email, 'password': password}, // email is phone from ui
      );

      final authResponse = AuthResponseModel.fromJson(response);

      // If backend immediately returns user (no OTP required), handle it
      if (authResponse.user != null) {
        return Right(authResponse.user!.toEntity());
      }

      // Normal OTP flow: login just sends the OTP, returns a message
      // Return a failure with the server message so AuthCubit shows OTP screen
      return Left(ServerFailure(
        authResponse.message.isNotEmpty ? authResponse.message : 'OTP sent',
      ));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OtpRequestResult>> requestOtp(
      {required String phone}) async {
    try {
      final response = await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.login,
        body: {'phone': phone},
      );
      final authResponse = AuthResponseModel.fromJson(response);
      if (authResponse.status == true) {
        // debug_otp is only present when the admin testing toggle + APP_DEBUG are on
        final debugOtp = authResponse.data?['debug_otp']?.toString();
        return Right(OtpRequestResult(phone: phone, debugOtp: debugOtp));
      }
      return Left(ServerFailure(
        authResponse.message.isNotEmpty ? authResponse.message : 'Failed to send OTP',
      ));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.loginPassword,
        body: {'phone': phone, 'password': password},
      );
      final authResponse = AuthResponseModel.fromJson(response);
      if (authResponse.user != null) {
        return Right(authResponse.user!.toEntity());
      }
      return Left(ServerFailure(
        authResponse.message.isNotEmpty ? authResponse.message : 'Login failed',
      ));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.register,
        body: {
          'name': name,
          'phone': phone,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response);

      // ── TEST MODE: backend returns user+token directly ──
      if (authResponse.user != null) {
        await userRepository.setUser(authResponse.user!.toEntity());
        return const Right('__AUTHENTICATED__');
      }

      // Normal OTP flow
      final returnedEmail = authResponse.data?['email'] as String?
          ?? authResponse.data?['phone'] as String?
          ?? phone;
      return Right(returnedEmail);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.verifyOTP,
        body: {'phone': identifier, 'otp': otp},
      );

      final authResponse = AuthResponseModel.fromJson(response);

      if (authResponse.user != null) {
        return Right(authResponse.user!.toEntity());
      }

      throw ServerException(
        authResponse.message.isNotEmpty
            ? authResponse.message
            : 'Verification failed',
        'VERIFY_OTP_FAILED',
      );
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<void> logout() async {
    await apiServices.request(method: HttpMethod.post, url: Endpoints.logout);
  }

  @override
  Future<Either<Failure, void>> resendOtp({required String phone}) async {
    try {
      await apiServices.request(
        method: HttpMethod.post,
        url: Endpoints.resendOTP,
        body: {'phone': phone},
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}
