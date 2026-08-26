import 'package:equatable/equatable.dart';

class ReturnEntity extends Equatable {
  final String id;
  final String status;
  final String reason;
  final String? notes;
  final double? refundAmount;
  final String? refundMethod;

  const ReturnEntity({
    required this.id,
    required this.status,
    required this.reason,
    this.notes,
    this.refundAmount,
    this.refundMethod,
  });

  factory ReturnEntity.fromJson(Map<String, dynamic> json) {
    return ReturnEntity(
      id: json['id'].toString(),
      status: json['status'] ?? 'pending',
      reason: json['reason'] ?? '',
      notes: json['notes'],
      refundAmount: json['refund_amount'] != null ? double.tryParse(json['refund_amount'].toString()) : null,
      refundMethod: json['refund_method'],
    );
  }

  @override
  List<Object?> get props => [id, status, reason, notes, refundAmount, refundMethod];
}
