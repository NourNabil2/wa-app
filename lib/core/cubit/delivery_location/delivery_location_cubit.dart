import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/user_data/user_cubit.dart';
import '../../../features/auth/domain/entities/user.dart';
import '../../../features/profile/presentation/cubit/addresses_cubit.dart';
import '../../../features/profile/presentation/cubit/addresses_state.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import 'delivery_location_state.dart';

// ── SharedPrefs keys ──────────────────────────────────────────────────────────
const _kPrefLabel = 'dloc_label';
const _kPrefLat   = 'dloc_lat';
const _kPrefLng   = 'dloc_lng';
const _kPrefZone  = 'dloc_zone';

/// Delivery Location rules:
///
/// • DISPLAY LABEL  → city from saved address (logged-in) or GPS geocoded city (guest).
///
/// • COORDINATES    → address lat/lng first (from backend geocoding), then device GPS.
///                    Used to pass to API calls so the backend can compute express
///                    eligibility per product (warehouse distance check).
///
/// • isExpressZone  → driven by HomeCubit after products load. True if ANY product
///                    returned for the current location has is_express_eligible=true.
///                    This is NOT a local bounding-box check anymore.
class DeliveryLocationCubit extends Cubit<DeliveryLocationState> {
  final UserCubit _userCubit;
  final AddressesCubit _addressesCubit;
  final GeocodingService _geocodingService;

  User? _lastKnownUser;
  late StreamSubscription<User?> _userSubscription;
  late StreamSubscription<AddressesState> _addressesSubscription;
  String? _lastKnownDefaultAddressId;

  DeliveryLocationCubit({
    required UserCubit userCubit,
    required AddressesCubit addressesCubit,
    required GeocodingService geocodingService,
  })  : _userCubit = userCubit,
        _addressesCubit = addressesCubit,
        _geocodingService = geocodingService,
        super(DeliveryLocationInitial()) {
    _lastKnownUser = _userCubit.state;
    _userSubscription = _userCubit.stream.listen((user) {
      final wasLoggedIn = _lastKnownUser != null;
      final isLoggedIn  = user != null;
      _lastKnownUser = user;

      if (isLoggedIn && !wasLoggedIn) {
        // Just logged in → fetch city from saved addresses + GPS for zone
        _resolveForLoggedInUser();
      } else if (!isLoggedIn && wasLoggedIn) {
        // Just logged out → drop address label, use GPS only
        _clearPersistedLocation();
        _resolveForGuestUser();
      }
    });

    // Changing "default" from the address book only updates AddressesCubit's
    // own state (backend + its list) — it never notifies us directly, so
    // without this, selectedAddress/lat/lng stay stale until a full app
    // restart. Adopt the new default ONLY when the DEFAULT ITSELF actually
    // changes (tracked via _lastKnownDefaultAddressId) — NOT whenever
    // AddressesCubit merely reloads (e.g. opening the address picker calls
    // load(), which must never override a manually-selected non-default
    // address).
    _addressesSubscription = _addressesCubit.stream.listen((addrState) {
      if (addrState is! AddressesLoaded || addrState.addresses.isEmpty) return;

      final addresses = addrState.addresses;
      final newDefault = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );

      final previousDefaultId = _lastKnownDefaultAddressId;
      _lastKnownDefaultAddressId = newDefault.id;

      // First observation (e.g. right after login) — resolveInitialLocation /
      // _resolveForLoggedInUser already handles establishing the initial
      // selection, so just record the baseline without forcing a change.
      if (previousDefaultId == null) return;

      if (previousDefaultId != newDefault.id) {
        setManualAddress(newDefault);
      }
    });
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _addressesSubscription.cancel();
    return super.close();
  }


  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _persist({
    required String label,
    double? lat,
    double? lng,
    required bool isZone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefLabel, label);
      await prefs.setBool(_kPrefZone, isZone);
      if (lat != null) {
        await prefs.setDouble(_kPrefLat, lat);
      } else {
        await prefs.remove(_kPrefLat);
      }
      if (lng != null) {
        await prefs.setDouble(_kPrefLng, lng);
      } else {
        await prefs.remove(_kPrefLng);
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefLabel);
      await prefs.remove(_kPrefLat);
      await prefs.remove(_kPrefLng);
      await prefs.remove(_kPrefZone);
    } catch (_) {}
  }

  /// Instantly restore the last-known location from SharedPreferences.
  /// Returns true if a cached location was found and emitted.
  Future<bool> _tryRestoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final label = prefs.getString(_kPrefLabel);
      if (label == null || label.isEmpty) return false;

      final lat  = prefs.getDouble(_kPrefLat);
      final lng  = prefs.getDouble(_kPrefLng);
      final zone = prefs.getBool(_kPrefZone) ?? false;

      if (!isClosed) {
        emit(DeliveryLocationResolved(
          displayLabel: label,
          lat: lat,
          lng: lng,
          isExpressZone: zone,
        ));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Public entry point ───────────────────────────────────────────────────────

  Future<void> resolveInitialLocation() async {
    // 1. Show cache instantly — zero delay, no flicker on refresh
    final hadCache = await _tryRestoreFromCache();

    // 2. Resolve city label in background
    if (_userCubit.isLoggedIn) {
      // Logged-in: city label from saved default address
      if (hadCache) {
        unawaited(_resolveForLoggedInUser());
      } else {
        await _resolveForLoggedInUser();
      }
    } else {
      // Guest: GPS is the only source of location
      if (!hadCache) emit(DeliveryLocationDenied());

      // Try silently first (works if permission already granted from a previous visit)
      unawaited(_enrichWithGpsCoordinates());

      // Then auto-prompt after the page loads — triggers the browser GPS dialog
      // so guests get their location detected without having to click anything.
      unawaited(_requestGpsAfterPageLoad());
    }

    // 3. For logged-in users, GPS still needed for express zone detection.
    //    Run in background after city label is already shown.
    if (_userCubit.isLoggedIn) {
      unawaited(_enrichWithGpsCoordinates());
    }
  }

  // ── Private resolvers ────────────────────────────────────────────────────────

  /// Sets displayLabel from saved default address city.
  /// Coordinates ALWAYS come from GPS — never from the address.
  Future<void> _resolveForLoggedInUser() async {
    try {
      final addresses = await _addressesCubit.loadAndReturn();
      if (isClosed) return;

      if (addresses.isEmpty) {
        if (!isClosed) emit(DeliveryLocationDenied());
        return;
      }

      final defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );

      // City from address (e.g. "Riyadh")
      final city = defaultAddr.city.isNotEmpty
          ? defaultAddr.city
          : defaultAddr.label;

      if (isClosed) return;

      // Use address-level coords if available (geocoded by backend), else fall back to GPS
      final addrLat = defaultAddr.lat;
      final addrLng = defaultAddr.lng;
      final currentLat = addrLat ?? ((state is DeliveryLocationResolved)
          ? (state as DeliveryLocationResolved).lat
          : null);
      final currentLng = addrLng ?? ((state is DeliveryLocationResolved)
          ? (state as DeliveryLocationResolved).lng
          : null);

      emit(DeliveryLocationResolved(
        displayLabel: city,
        lat: currentLat,
        lng: currentLng,
        selectedAddress: defaultAddr,   // ← store the full entity
        isExpressZone: false,           // HomeCubit sets this after products load
      ));
      unawaited(_persist(label: city, lat: currentLat, lng: currentLng, isZone: false));

    } catch (_) {
      // Network failure — emit Denied ONLY if we are still in Initial/Loading,
      // so the HomeTabScreen listener triggers and loads the fallback.
      if (state is DeliveryLocationInitial || state is DeliveryLocationLoading) {
        if (!isClosed) emit(DeliveryLocationDenied());
      }
    }
  }

  Future<void> _resolveForGuestUser() async {
    if (!isClosed) emit(DeliveryLocationDenied());
    unawaited(_enrichWithGpsCoordinates());
  }

  /// Gets GPS coordinates silently (no dialog) and enriches the current state.
  /// This is the SOLE source of lat/lng and isExpressZone.
  Future<void> _enrichWithGpsCoordinates() async {
    try {
      final pos = await LocationService.instance.getPosition();
      if (pos == null || isClosed) return;

      _applyGpsCoords(pos);
    } catch (_) {}
  }

  /// Prompts for GPS permission after page renders (guests + first-time users).
  Future<void> _requestGpsAfterPageLoad() async {
    await Future.delayed(const Duration(seconds: 2));
    if (isClosed) return;

    try {
      final pos = await LocationService.instance.requestAndGetPosition();
      if (pos == null || isClosed) return;
      _applyGpsCoords(pos);
    } catch (_) {}
  }

  /// Applies GPS position to the current state:
  /// - If guest/denied  → also geocodes city from GPS
  /// - If resolved      → keeps existing city label and isExpressZone, only updates coords
  void _applyGpsCoords(Position pos) {
    // Preserve the current isExpressZone (driven by HomeCubit) — don't reset it.
    final currentZone = (state is DeliveryLocationResolved)
        ? (state as DeliveryLocationResolved).isExpressZone
        : false;
    final current = state;

    if (current is DeliveryLocationResolved) {
      // Already have a city label (from saved address) — just enrich coords
      final updated = current.copyWith(
        lat: pos.latitude,
        lng: pos.longitude,
        isExpressZone: currentZone,  // preserve HomeCubit-set zone
      );
      if (!isClosed) {
        emit(updated);
        unawaited(_persist(
          label: updated.displayLabel,
          lat: pos.latitude,
          lng: pos.longitude,
          isZone: currentZone,
        ));
      }
      return;
    }

    // Guest/denied: geocode city from GPS coordinates
    if (current is DeliveryLocationDenied || current is DeliveryLocationInitial) {
      unawaited(_geocodeAndEmit(pos, currentZone));
    }
  }

  Future<void> _geocodeAndEmit(Position pos, bool zone) async {
    try {
      final city = await _geocodingService.getCityFromCoordinates(
          pos.latitude, pos.longitude);
      if (isClosed) return;
      final label = city ?? 'address.map.current_location'.tr();
      emit(DeliveryLocationResolved(
        displayLabel: label,
        lat: pos.latitude,
        lng: pos.longitude,
        isExpressZone: zone,  // starts false, HomeCubit sets it to true once products load
      ));
      unawaited(_persist(label: label, lat: pos.latitude, lng: pos.longitude, isZone: zone));
    } catch (_) {}
  }

  // ── Public user-triggered actions ────────────────────────────────────────────

  /// Called when the user taps the location button in the header.
  /// Shows the browser GPS dialog explicitly.
  Future<void> requestLocationFromUser() async {
    final prevState = state;
    emit(DeliveryLocationLoading());
    try {
      final pos = await LocationService.instance.requestAndGetPosition();
      if (pos == null) {
        emit(prevState is DeliveryLocationResolved ? prevState : DeliveryLocationDenied());
        return;
      }
      // isExpressZone stays false here; HomeCubit will set it after products reload.
      String label = 'address.map.current_location'.tr();
      try {
        final city = await _geocodingService.getCityFromCoordinates(
            pos.latitude, pos.longitude);
        if (city != null) label = city;
      } catch (_) {}

      if (isClosed) return;
      emit(DeliveryLocationResolved(
        displayLabel: label,
        lat: pos.latitude,
        lng: pos.longitude,
        isExpressZone: false,
      ));
      unawaited(_persist(label: label, lat: pos.latitude, lng: pos.longitude, isZone: false));
    } catch (_) {
      emit(prevState is DeliveryLocationResolved ? prevState : DeliveryLocationDenied());
    }
  }

  /// Called from the map screen when the user confirms their position visually.
  /// ONLY for display — not a delivery address selection.
  /// isExpressZone stays false until HomeCubit reloads products for this location.
  void setManualCoordinates(double lat, double lng, String city) {
    emit(DeliveryLocationResolved(
      displayLabel: city,
      lat: lat,
      lng: lng,
      isExpressZone: false,
    ));
    unawaited(_persist(label: city, lat: lat, lng: lng, isZone: false));
  }

  /// Called by HomeCubit after products load.
  /// Sets isExpressZone = true if the backend returned ANY express-eligible product
  /// for the current location. This replaces the old hardcoded bounding-box check.
  void setExpressZone(bool isAvailable) {
    final s = state;
    if (s is! DeliveryLocationResolved) return;
    if (s.isExpressZone == isAvailable) return; // no-op if unchanged
    emit(s.copyWith(isExpressZone: isAvailable));
    // Persist so the green dot survives a page refresh
    unawaited(_persist(
      label: s.displayLabel,
      lat: s.lat,
      lng: s.lng,
      isZone: isAvailable,
    ));
  }

  /// Called when the user selects a saved address from the navbar picker.
  /// Uses address-level coords (geocoded by backend) first, falls back to GPS.
  /// isExpressZone is preserved from current state — HomeCubit will update it
  /// after the home page reloads with the new address.
  Future<void> setManualAddress(dynamic address) async {
    final city = (address.city?.isNotEmpty == true)
        ? address.city as String
        : address.label as String;

    final addrLat = address.lat as double?;
    final addrLng = address.lng as double?;
    final currentLat = addrLat ?? ((state is DeliveryLocationResolved)
        ? (state as DeliveryLocationResolved).lat
        : null);
    final currentLng = addrLng ?? ((state is DeliveryLocationResolved)
        ? (state as DeliveryLocationResolved).lng
        : null);

    // Reset zone to false — HomeCubit will re-evaluate after reloading products
    // for the newly selected address.
    emit(DeliveryLocationResolved(
      displayLabel: city,
      lat: currentLat,
      lng: currentLng,
      selectedAddress: address,
      isExpressZone: false,
    ));
    unawaited(_persist(label: city, lat: currentLat, lng: currentLng, isZone: false));
  }
}
