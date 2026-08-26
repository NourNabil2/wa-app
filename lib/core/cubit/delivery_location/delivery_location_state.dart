import 'package:equatable/equatable.dart';
import '../../../features/checkout/domain/entities/saved_address_entity.dart';

abstract class DeliveryLocationState extends Equatable {
  const DeliveryLocationState();

  @override
  List<Object?> get props => [];
}

class DeliveryLocationInitial extends DeliveryLocationState {}

class DeliveryLocationLoading extends DeliveryLocationState {}

class DeliveryLocationResolved extends DeliveryLocationState {
  final String displayLabel;
  final double? lat;
  final double? lng;
  final AddressEntity? selectedAddress;
  final bool isExpressZone;

  const DeliveryLocationResolved({
    required this.displayLabel,
    this.lat,
    this.lng,
    this.selectedAddress,
    this.isExpressZone = false,
  });

  DeliveryLocationResolved copyWith({
    String? displayLabel,
    double? lat,
    double? lng,
    AddressEntity? selectedAddress,
    bool? isExpressZone,
  }) {
    return DeliveryLocationResolved(
      displayLabel: displayLabel ?? this.displayLabel,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isExpressZone: isExpressZone ?? this.isExpressZone,
    );
  }

  @override
  List<Object?> get props => [displayLabel, lat, lng, selectedAddress, isExpressZone];
}

class DeliveryLocationDenied extends DeliveryLocationState {}
