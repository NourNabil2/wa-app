import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  Timer? _debounceTimer;
  
  // Riyadh default
  LatLng _currentPosition = const LatLng(24.7136, 46.6753);
  bool _isLoadingLocation = true;
  bool _isConfirming = false;
  String _currentAddress = 'home.header_status.determining_location'.tr();

  final GeocodingService _geocodingService = sl<GeocodingService>();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    // User explicitly tapped GPS button — OK to show permission dialog here
    final pos = await LocationService.instance.requestAndGetPosition();
    if (pos != null) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _moveCamera(pos.latitude, pos.longitude);
    }
    await _updateAddressFromCoords(_currentPosition);
    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _moveCamera(double lat, double lng) async {
    _mapController.move(LatLng(lat, lng), 16.0);
  }

  Future<void> _updateAddressFromCoords(LatLng position) async {
    final address = await _geocodingService.getAddressFromCoordinates(position.latitude, position.longitude);
    if (mounted) {
      setState(() {
        _currentAddress = address ?? 'home.unknown_location'.tr();
      });
    }
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    _currentPosition = position.center;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateAddressFromCoords(_currentPosition);
    });
  }

  Future<void> _confirmLocation() async {
    setState(() {
      _isConfirming = true;
    });

    final city = await _geocodingService.getCityFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);
    final displayCity = city ?? 'home.unknown_location'.tr();

    if (mounted) {
      context.read<DeliveryLocationCubit>().setManualCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
        displayCity,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home.select_via_map'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.app.wa',
              ),
            ],
          ),
          
          // Center Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on,
                size: 40.r,
                color: ColorsManager.primaryColor,
              ),
            ),
          ),

          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),

          // Floating GPS Button
          Positioned(
            right: 16.w,
            bottom: 120.h,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: ColorsManager.primaryColor),
            ),
          ),

          // Bottom Address Bar & Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.zero),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: ColorsManager.primaryColor),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isConfirming ? null : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: ColorsManager.primaryColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'home.confirm_location'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
