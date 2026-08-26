import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/db/shared_pref_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/push_handler.dart';
import '../../../user_data/user_repo.dart';
import '../../domain/entities/verify_otp_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final LogoutUseCase logoutUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final AuthRepository authRepository;
  final UserRepository userRepository;

  AuthCubit({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.logoutUseCase,
    required this.verifyOtpUseCase,
    required this.authRepository,
    required this.userRepository,
  }) : super(AuthInitial());

  /// Re-register the FCM device token so the backend claims it to this user.
  /// The token was first sent at app launch while still a guest (user_id null);
  /// without this re-post after login it would never be linked to the account,
  /// so no targeted push (order updates, cart reminders) could ever reach them.
  /// Fire-and-forget: never block or fail the auth flow on a push hiccup.
  Future<void> _claimPushToken() async {
    try {
      await PushHandler.instance.refreshRegistration();
    } catch (_) {
      // Non-fatal — token will be claimed on the next app launch.
    }
  }

  Future<void> loadCurrentUser() async {
    final user = userRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    if (isClosed) return;
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );
    if (isClosed) return;

    result.fold(
          (failure) {
        if (failure is AccountNotVerifiedFailure) {
          emit(AccountNotVerified(email: failure.email));
        } else {
          emit(AuthFailure(message: failure.message));
        }
      },
          (user) async {
        await userRepository.setUser(user);
        await _claimPushToken();
        if (isClosed) return;
        emit(LoginSuccess());
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (isClosed) return;
    emit(AuthLoading());

    final result = await signupUseCase(
      SignupParams(name: name, email: email, phone: phone, password: password),
    );
    if (isClosed) return;

    result.fold(
          (failure) => emit(AuthFailure(message: failure.message)),
          (emailOrSignal) async {
        await SharedPrefHelper.saveLoginCredentials(phone: phone, password: password);
        if (emailOrSignal == '__AUTHENTICATED__') {
          // TEST MODE: user was already saved in repo by the repository
          final user = userRepository.currentUser!;
          await _claimPushToken();
          if (isClosed) return;
          emit(LoginSuccess());
          emit(AuthAuthenticated(user: user));
        } else {
          emit(SignupSuccess(email: emailOrSignal));
        }
      },
    );
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    if (state is OtpLoading) return;
    emit(const OtpLoading());

    final result = await verifyOtpUseCase(
      VerifyOtpParams(identifier: phone, otp: otp),
    );
    if (isClosed) return;

    result.fold(
          (failure) => emit(OtpFailure(message: failure.message)),
          (user) async {
        await userRepository.setUser(user);
        await _claimPushToken();
        if (isClosed) return;
        emit(LoginSuccess());
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Request OTP via WhatsApp for phone-only login flow
  Future<void> requestOtp(String phone) async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await authRepository.requestOtp(phone: phone);
    if (isClosed) return;
    result.fold(
      (f) => emit(AuthFailure(message: f.message)),
      (r) => emit(OtpSent(phone: r.phone, debugOtp: r.debugOtp)),
    );
  }

  /// Login with password (fallback when WhatsApp OTP unavailable)
  Future<void> loginWithPassword(String phone, String password) async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await authRepository.loginWithPassword(
      phone: phone,
      password: password,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) async {
        await userRepository.setUser(user);
        await SharedPrefHelper.saveLoginCredentials(phone: phone, password: password);
        await _claimPushToken();
        if (isClosed) return;
        emit(LoginSuccess());
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Login securely using locally saved credentials (for Biometric Login)
  Future<void> loginWithBiometric() async {
    if (isClosed) return;
    emit(AuthLoading());
    final credentials = await SharedPrefHelper.getLoginCredentials();
    if (credentials == null) {
      emit(AuthFailure(message: 'No credentials found'));
      return;
    }

    final result = await authRepository.loginWithPassword(
      phone: credentials['phone']!,
      password: credentials['password']!,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) async {
        await userRepository.setUser(user);
        await _claimPushToken();
        if (isClosed) return;
        emit(LoginSuccess());
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> logout() async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await logoutUseCase();
    if (isClosed) return;
    result.fold(
          (failure) => emit(AuthUnauthenticated()),
          (_) => emit(AuthUnauthenticated()),
    );
  }

  /// BUG-67 FIX: Resend OTP — sends a new OTP to the user's phone
  Future<void> resendOtp({required String phone}) async {
    if (isClosed) return;
    emit(const OtpLoading());
    final result = await authRepository.resendOtp(phone: phone);
    if (isClosed) return;
    result.fold(
      (failure) => emit(OtpFailure(message: failure.message)),
      (_) => emit(const OtpResent()),
    );
  }
}