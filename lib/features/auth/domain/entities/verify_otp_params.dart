import 'package:equatable/equatable.dart';

class VerifyOtpParams extends Equatable {
  final String identifier; // phone or email
  final String otp;

  const VerifyOtpParams({required this.identifier, required this.otp});

  @override
  List<Object?> get props => [identifier, otp];
}