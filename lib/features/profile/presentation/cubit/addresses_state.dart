import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../../../../features/checkout/domain/entities/city_entity.dart';

abstract class AddressesState {}

class AddressesInitial extends AddressesState {}

class AddressesLoading extends AddressesState {}

class AddressesLoaded extends AddressesState {
  final List<AddressEntity> addresses;
  AddressesLoaded(this.addresses);
}

// FIX: Added the missing state to handle loaded cities
class AddressesCitiesLoaded extends AddressesState {
  final List<CityEntity> cities;
  AddressesCitiesLoaded(this.cities);
}

class AddressesError extends AddressesState {
  final String message;
  AddressesError(this.message);
}

class AddressActionLoading extends AddressesState {
  final List<AddressEntity> currentAddresses;
  AddressActionLoading(this.currentAddresses);
}

class AddressActionSuccess extends AddressesState {
  final List<AddressEntity> addresses;
  final String? message;
  AddressActionSuccess(this.addresses, {this.message});
}
