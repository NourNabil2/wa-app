// lib/features/profile/presentation/view/map_address_picker_screen.dart
//
// T8.8 — Google Maps Address Picker
// ─────────────────────────────────────────────────────────────────────────────
// Premium full-screen Google Maps pin-drop picker with:
//   • Draggable pin (center camera idle → reverse geocode)
//   • My Location floating button
//   • Google Places autocomplete search bar at top
//   • Animated bottom sheet with address preview + confirm button
//   • Returns MapPickResult(lat, lng, street, district, city, fullAddress)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';

// ── Result Model ──────────────────────────────────────────────────────────────

class MapPickResult {
  final double lat;
  final double lng;
  final String fullAddress;
  final String? street;
  final String? district;
  final String? city;

  const MapPickResult({
    required this.lat,
    required this.lng,
    required this.fullAddress,
    this.street,
    this.district,
    this.city,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MapAddressPickerScreen extends StatefulWidget {
  /// Optional initial position (e.g. from an existing address)
  final LatLng? initialPosition;
  final String googleApiKey;

  const MapAddressPickerScreen({
    super.key,
    this.initialPosition,
    required this.googleApiKey,
  });

  /// Convenience push — returns MapPickResult? or null if cancelled
  static Future<MapPickResult?> push(
    BuildContext context, {
    LatLng? initialPosition,
    String googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY',
  }) {
    return Navigator.of(context).push<MapPickResult?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapAddressPickerScreen(
          initialPosition: initialPosition,
          googleApiKey: googleApiKey,
        ),
      ),
    );
  }

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen>
    with SingleTickerProviderStateMixin {
  // ── Map ───────────────────────────────────────────────────────────────────
  static const LatLng _riyadhDefault = LatLng(24.7136, 46.6753);
  final MapController _mapCtrl = MapController();
  Timer? _debounceTimer;

  late LatLng _pinPos;
  bool _isCameraMoving = false;
  bool _isLoadingAddress = false;
  bool _isConfirming = false;

  // ── Address Data ──────────────────────────────────────────────────────────
  String _addressLine = '';
  String? _street;
  String? _district;
  String? _city;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearchBar = false;

  // ── Animation (pin bounce) ────────────────────────────────────────────────
  late AnimationController _pinAnim;
  late Animation<double> _pinOffset;

  final GeocodingService _geo = sl<GeocodingService>();

  @override
  void initState() {
    super.initState();
    _pinPos = widget.initialPosition ?? _riyadhDefault;

    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pinOffset = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _pinAnim, curve: Curves.easeOut),
    );

    // If no initial position, get current location
    if (widget.initialPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation());
    } else {
      _reverseGeocode(_pinPos);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pinAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Camera helpers ────────────────────────────────────────────────────────

  Future<void> _animateTo(LatLng pos, {double zoom = 16.5}) async {
    _mapCtrl.move(pos, zoom);
  }

  Future<void> _goToMyLocation() async {
    final pos = await LocationService.instance.requestAndGetPosition();
    if (pos != null && mounted) {
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinPos = latlng);
      await _animateTo(latlng);
      await _reverseGeocode(latlng);
    }
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final address =
          await _geo.getAddressFromCoordinates(pos.latitude, pos.longitude);
      final city =
          await _geo.getCityFromCoordinates(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _addressLine = address ?? 'address.map.unknown_location'.tr();
          _city = city;
          // Parse street/district from address parts
          final parts = (address ?? '').split(',');
          _street = parts.isNotEmpty ? parts[0].trim() : null;
          _district = parts.length > 1 ? parts[1].trim() : null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onPositionChanged(MapCamera pos, bool hasGesture) {
    _pinPos = pos.center;
    if (!_isCameraMoving) {
      setState(() => _isCameraMoving = true);
      _pinAnim.forward();
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isCameraMoving = false);
        _pinAnim.reverse();
        _reverseGeocode(_pinPos);
      }
    });
  }

  // ── Place selection from autocomplete ─────────────────────────────────────

  void _onPlaceSelected(Prediction prediction) {
    _searchCtrl.text = prediction.description ?? '';
    setState(() => _showSearchBar = false);

    // If lat/lng available, move camera
    final lat = double.tryParse(prediction.lat ?? '');
    final lng = double.tryParse(prediction.lng ?? '');
    if (lat != null && lng != null) {
      final pos = LatLng(lat, lng);
      setState(() => _pinPos = pos);
      _animateTo(pos);
      _reverseGeocode(pos);
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    final result = MapPickResult(
      lat: _pinPos.latitude,
      lng: _pinPos.longitude,
      fullAddress: _addressLine,
      street: _street,
      district: _district,
      city: _city,
    );
    if (mounted) Navigator.of(context).pop(result);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinPos,
              initialZoom: 14,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fastway.app',
              ),
            ],
          ),

          // ── Animated pin ─────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pinAnim,
            builder: (_, __) => Center(
              child: Transform.translate(
                offset: Offset(0, _pinOffset.value - 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shadow (stays still)
                    if (!_isCameraMoving)
                      Container(
                        width: 12.r,
                        height: 6.h,
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    Icon(
                      Icons.location_pin,
                      size: 52.r,
                      color: ColorsManager.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar: back + search ────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: _showSearchBar
                      ? _buildSearchBar(isDark)
                      : Row(
                          children: [
                            // Back
                            _MapButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                              isDark: isDark,
                            ),
                            SizedBox(width: 8.w),
                            // Title chip
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _showSearchBar = true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.zero,
                                    // BoxShadow removed from search button
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search,
                                          size: 18.r, color: Colors.grey),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'address.map.search_location'.tr(),
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ── My Location button ────────────────────────────────────────────
          Positioned(
            left: 16.w,
            bottom: 200.h,
            child: _MapButton(
              icon: Icons.my_location_rounded,
              onTap: _goToMyLocation,
              isDark: isDark,
              color: ColorsManager.primaryColor,
            ),
          ),

          // ── Bottom address card ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.zero,
        // BoxShadow removed from location button
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => setState(() {
              _showSearchBar = false;
              _searchCtrl.clear();
            }),
          ),
          Expanded(
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchCtrl,
              googleAPIKey: widget.googleApiKey,
              inputDecoration: InputDecoration(
                hintText: 'address.map.search_address'.tr(),
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              debounceTime: 600,
              countries: const ['sa'],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: _onPlaceSelected,
              itemClick: _onPlaceSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.zero),
        // BoxShadow removed from address panel
      ),
      padding: EdgeInsets.fromLTRB(
          20.w, 20.h, 20.w, MediaQuery.paddingOf(context).bottom + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Label
          Text(
            'address.map.selected_location'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),

          // Address line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded,
                  color: ColorsManager.primaryColor, size: 20.r),
              SizedBox(width: 8.w),
              Expanded(
                child: _isLoadingAddress
                    ? const LinearProgressIndicator(
                        minHeight: 3,
                        color: ColorsManager.primaryColor,
                        borderRadius: BorderRadius.zero,
                      )
                    : Text(
                        _addressLine.isEmpty
                            ? 'address.map.locating'.tr()
                            : _addressLine,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed:
                  (_isLoadingAddress || _isConfirming || _addressLine.isEmpty)
                      ? null
                      : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              child: _isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'address.map.confirm_location'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small icon button (for map overlay buttons) ───────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: BoxShape.circle,
          // BoxShadow removed from map buttons
        ),
        child: Icon(icon,
            size: 20, color: color ?? (isDark ? Colors.white : Colors.black87)),
      ),
    );
  }
}
