// lib/features/addresses/presentation/cubit/addresses_cubit.dart
//
// FIXES:
//  • Added loadCities() — fetches cities from backend for the add/edit form
//  • AddressesCitiesLoaded state emitted so AddEditAddressScreen can receive cities
//  • All existing add/update/delete/setDefault flows preserved

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../checkout/domain/entities/saved_address_entity.dart';
import '../../../checkout/domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/delete_address_usecase.dart';
import '../../domain/usecases/get_addresses_usecase.dart';
import '../../domain/usecases/lookup_address_usecase.dart';
import '../../domain/usecases/set_default_address_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import 'addresses_state.dart';

class AddressesCubit extends Cubit<AddressesState> {
  final GetAddressesUseCase _get;
  final AddAddressUseCase _add;
  final UpdateAddressUseCase _update;
  final DeleteAddressUseCase _delete;
  final SetDefaultAddressUseCase _setDefault;
  final GetCitiesUseCase _getCities;
  final LookupAddressUseCase _lookupAddress;

  AddressesCubit({
    required GetAddressesUseCase get,
    required AddAddressUseCase add,
    required UpdateAddressUseCase update,
    required DeleteAddressUseCase delete,
    required SetDefaultAddressUseCase setDefault,
    required GetCitiesUseCase getCities,
    required LookupAddressUseCase lookupAddress,
  })  : _get = get,
        _add = add,
        _update = update,
        _delete = delete,
        _setDefault = setDefault,
        _getCities = getCities,
        _lookupAddress = lookupAddress,
        super(AddressesInitial());

  List<AddressEntity> get _currentList {
    final s = state;
    if (s is AddressesLoaded) return s.addresses;
    if (s is AddressActionLoading) return s.currentAddresses;
    return [];
  }

  // ── Load addresses ────────────────────────────────────────────────────────

  Future<void> load() async {
    if (isClosed) return;
    emit(AddressesLoading());
    final result = await _get();
    if (isClosed) return;
    result.fold(
      (f) => emit(AddressesError(f.message)),
      (list) => emit(AddressesLoaded(list)),
    );
  }

  Future<List<AddressEntity>> loadAndReturn() async {
    emit(AddressesLoading());
    final result = await _get();
    if (isClosed) {
      return result.fold((f) => [], (list) => list);
    }
    return result.fold(
      (f) {
        emit(AddressesError(f.message));
        return [];
      },
      (list) {
        emit(AddressesLoaded(list));
        return list;
      },
    );
  }

  // ── Load cities (for add/edit form) ──────────────────────────────────────

  Future<void> loadCities() async {
    final result = await _getCities();
    if (isClosed) return;
    result.fold(
      (_) => null, // silently ignore; form shows empty picker
      (cities) => emit(AddressesCitiesLoaded(cities)),
    );
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> addAddress({
    required String label,
    required String fullAddress,
    required String phone,
    required String city,
    bool isDefault = false,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  }) async {
    if (isClosed) return;
    emit(AddressActionLoading(_currentList));
    final result = await _add(
      label: label,
      fullAddress: fullAddress,
      phone: phone,
      city: city,
      isDefault: isDefault,
      building: building,
      street: street,
      district: district,
      shortAddress: shortAddress,
      postalCode: postalCode,
      additionalNumber: additionalNumber,
      lat: lat,
      lng: lng,
    );
    if (isClosed) return;
    result.fold(
      (f) => emit(AddressesError(f.message)),
      (_) => load(),
    );
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateAddress({
    required String id,
    required String label,
    required String fullAddress,
    required String phone,
    required String city,
    bool isDefault = false,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  }) async {
    if (isClosed) return;
    emit(AddressActionLoading(_currentList));
    final result = await _update(
      id: id,
      label: label,
      fullAddress: fullAddress,
      phone: phone,
      city: city,
      isDefault: isDefault,
      building: building,
      street: street,
      district: district,
      shortAddress: shortAddress,
      postalCode: postalCode,
      additionalNumber: additionalNumber,
      lat: lat,
      lng: lng,
    );
    if (isClosed) return;
    result.fold(
      (f) => emit(AddressesError(f.message)),
      (_) => load(),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteAddress(String id) async {
    if (isClosed) return;
    emit(AddressActionLoading(_currentList));
    final result = await _delete(id);
    if (isClosed) return;
    result.fold(
      (f) => emit(AddressesError(f.message)),
      (_) => load(),
    );
  }

  // ── Set default ───────────────────────────────────────────────────────────

  Future<void> setDefault(String id) async {
    if (isClosed) return;
    emit(AddressActionLoading(_currentList));
    final result = await _setDefault(id);
    if (isClosed) return;
    result.fold(
      (f) => emit(AddressesError(f.message)),
      (_) => load(),
    );
  }

  // ── Lookup ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> lookupNationalAddress(
      String shortAddress) async {
    // We don't emit loading state here to avoid resetting the entire form UI,
    // we'll just return the result for the UI to handle a local loading spinner.
    final result = await _lookupAddress(shortAddress);
    return result.fold(
      (f) {
        emit(AddressesError(f.message));
        return null;
      },
      (data) => data,
    );
  }
}
