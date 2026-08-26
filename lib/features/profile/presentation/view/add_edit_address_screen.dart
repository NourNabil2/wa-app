// lib/features/addresses/presentation/view/add_edit_address_screen.dart
//
// MOBILE REDESIGN:
//   • Fields grouped in a single clean card with hairline row-dividers
//   • Icon + label + input row pattern (same as edit_profile)
//   • "Set as default" row at bottom of card
//   • Save button pinned outside scroll
//   • Web layout unchanged (card + constrained width)

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_buton.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../features/checkout/domain/entities/city_entity.dart';
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../../../../features/checkout/presentation/widgets/city_dropdown.dart';
import '../cubit/addresses_cubit.dart';
import '../cubit/addresses_state.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/widgets/web_breadcrumb.dart';
import 'package:google_places_flutter/model/prediction.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressEntity? address;
  final List<CityEntity> availableCities;
  final bool isModal;

  const AddEditAddressScreen({
    super.key,
    this.address,
    this.availableCities = const [],
    this.isModal = false,
  });

  static Future<void> show(BuildContext context, AddressesCubit cubit,
      {AddressEntity? address}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    // Mobile: bottom sheet as before
    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.zero),
        ),
        builder: (ctx) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.9,
            child: BlocProvider.value(
              value: cubit,
              child: AddEditAddressScreen(address: address, isModal: true),
            ),
          ),
        ),
      );
    }

    // Web / Tablet / Desktop: centered responsive dialog
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) {
        final dialogWidth = screenWidth < 900
            ? screenWidth * 0.9   // tablet
            : 850.0;              // desktop
        final maxH = MediaQuery.sizeOf(context).height * 0.88;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: maxH),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: BlocProvider.value(
                value: cubit,
                child: AddEditAddressScreen(address: address, isModal: true),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _shortAddressCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _additionalNumCtrl;
  bool _isDefault = false;
  CityEntity? _selectedCity;
  List<CityEntity> _cities = [];
  bool _isLookingUp = false;
  bool _lookupDone = false;
  double? _lat;
  double? _lng;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _addressCtrl = TextEditingController(text: a?.fullAddress ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _shortAddressCtrl = TextEditingController(text: a?.shortAddress ?? '');
    _buildingCtrl = TextEditingController(text: a?.building ?? '');
    _streetCtrl = TextEditingController(text: a?.street ?? '');
    _districtCtrl = TextEditingController(text: a?.district ?? '');
    _postalCodeCtrl = TextEditingController(text: a?.postalCode ?? '');
    _additionalNumCtrl = TextEditingController(text: a?.additionalNumber ?? '');
    _isDefault = a?.isDefault ?? false;
    _lat = a?.lat;
    _lng = a?.lng;
    _cities = widget.availableCities;
    // If editing an existing address, treat lookup as already done
    _lookupDone = _isEdit;

    if (a?.city != null && _cities.isNotEmpty) {
      final match = _cities.where((c) =>
          c.name.toLowerCase() == a!.city.toLowerCase() || c.nameAr == a.city);
      if (match.isNotEmpty) _selectedCity = match.first;
    }

    if (_cities.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddressesCubit>().loadCities();
      });
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _shortAddressCtrl.dispose();
    _buildingCtrl.dispose();
    _streetCtrl.dispose();
    _districtCtrl.dispose();
    _postalCodeCtrl.dispose();
    _additionalNumCtrl.dispose();
    super.dispose();
  }

  void _onPlaceSelected(Prediction prediction) {
    if (prediction.description != null) {
      _addressCtrl.text = prediction.description!;
      _addressCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description!.length));
    }

    // Auto populate fields based on description or lat/lng if we had full details.
    if (prediction.description != null) {
      final parts = prediction.description!.split(',');
      if (parts.isNotEmpty) {
        setState(() {
          if (_streetCtrl.text.isEmpty) _streetCtrl.text = parts[0].trim();
          if (parts.length > 1 && _districtCtrl.text.isEmpty) {
            _districtCtrl.text = parts[1].trim();
          }
        });
      }
    }
  }

  Future<void> _lookupShortAddress() async {
    final shortAddr = _shortAddressCtrl.text.trim();
    if (shortAddr.isEmpty) return;

    setState(() => _isLookingUp = true);
    final data =
        await context.read<AddressesCubit>().lookupNationalAddress(shortAddr);
    setState(() => _isLookingUp = false);

    if (data != null && mounted) {
      setState(() {
        _lookupDone = true;
        _buildingCtrl.text = data['building']?.toString() ?? _buildingCtrl.text;
        _streetCtrl.text = data['street']?.toString() ?? _streetCtrl.text;
        final district = data['district']?.toString()
            ?? data['region']?.toString()
            ?? '';
        if (district.isNotEmpty) _districtCtrl.text = district;
        _postalCodeCtrl.text =
            data['postal_code']?.toString() ?? _postalCodeCtrl.text;
        _additionalNumCtrl.text =
            data['additional_number']?.toString() ?? _additionalNumCtrl.text;
        _addressCtrl.text =
            data['full_address']?.toString() ??
            data['street']?.toString() ??
            _addressCtrl.text;
        // Store coordinates for saving
        _lat = (data['latitude']  as num?)?.toDouble() ?? _lat;
        _lng = (data['longitude'] as num?)?.toDouble() ?? _lng;

        final city = data['city']?.toString();
        if (city != null && _cities.isNotEmpty) {
          final match = _cities.where((c) =>
              c.name.toLowerCase() == city.toLowerCase() ||
              c.nameAr == city ||
              c.nameAr.toLowerCase() == city.toLowerCase());
          if (match.isNotEmpty) _selectedCity = match.first;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.guest_form.fetch_success'.tr()),
        backgroundColor: ColorsManager.primaryColor,
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('address.not_found'.tr()),
        backgroundColor: ColorsManager.errorFill,
      ));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Require short address lookup for new addresses
    if (!_isEdit && !_lookupDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.guest_form.fetch_error'.tr()),
        backgroundColor: ColorsManager.errorFill,
      ));
      return;
    }
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('address.selectCityRequired'.tr()),
        backgroundColor: ColorsManager.errorFill,
      ));
      return;
    }
    final cubit = context.read<AddressesCubit>();
    if (_isEdit) {
      await cubit.updateAddress(
        id: widget.address!.id,
        label: _labelCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _selectedCity!.name,
        isDefault: _isDefault,
        shortAddress: _shortAddressCtrl.text.trim(),
        building: _buildingCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        postalCode: _postalCodeCtrl.text.trim(),
        additionalNumber: _additionalNumCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
      );
    } else {
      await cubit.addAddress(
        label: _labelCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _selectedCity!.name,
        isDefault: _isDefault,
        shortAddress: _shortAddressCtrl.text.trim(),
        building: _buildingCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        postalCode: _postalCodeCtrl.text.trim(),
        additionalNumber: _additionalNumCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressesCubit, AddressesState>(
      listener: (context, state) {
        if (state is AddressesCitiesLoaded) {
          setState(() {
            _cities = state.cities;
            final city = widget.address?.city;
            if (city != null && _selectedCity == null) {
              final match = _cities.where((c) =>
                  c.name.toLowerCase() == city.toLowerCase() ||
                  c.nameAr == city);
              if (match.isNotEmpty) _selectedCity = match.first;
            }
          });
        }
        if (state is AddressesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: ColorsManager.errorFill));
        }
      },
      builder: (context, state) {
        final isLoading = state is AddressActionLoading;
        if (!isMobileLayout(context)) {
          return _buildWeb(context, state, isLoading);
        }
        return _buildMobile(context, state, isLoading);
      },
    );
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────

  Widget _buildMobile(
      BuildContext context, AddressesState state, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final titleStr = _isEdit ? 'address.edit'.tr() : 'address.add'.tr();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F5F7),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 6, bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : Colors.black, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(titleStr,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // ── Scrollable form ────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: ColorsManager.primaryColor),
                          const SizedBox(width: 5),
                          Text('checkout.guest_form.title'.tr(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.primaryColor)),
                        ],
                      ),
                    ),

                    // Fields card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        // BoxShadow removed
                      ),
                      child: Column(
                        children: [
                          // Label
                          _AddressFieldRow(
                            icon: Icons.label_outline_rounded,
                            label: 'address.label'.tr(),
                            hint: 'address.hints.label'.tr(),
                            controller: _labelCtrl,
                            isDark: isDark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'validation.required'.tr()
                                : null,
                          ),

                          // Short Address — required, with search button
                          _AddressFieldRow(
                            icon: Icons.qr_code_2_outlined,
                            label: 'address.short_national_address'.tr(),
                            hint: 'address.hints.short_national_address'.tr(),
                            controller: _shortAddressCtrl,
                            isDark: isDark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'checkout.guest_form.short_address_req'.tr()
                                : null,
                            suffixIcon: _isLookingUp
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _lookupShortAddress,
                                    color: ColorsManager.primaryColor,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                          ),
                          if (!_lookupDone && !_isEdit)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 62, bottom: 6),
                              child: Text(
                                'checkout.guest_form.search_short_address'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ColorsManager.primaryColor
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          if (_lookupDone)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 62, bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 11, color: Colors.green),
                                  const SizedBox(width: 3),
                                  Text(
                                    'checkout.guest_form.address_verified'.tr(),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),

                          // Street — always editable
                          _AddressFieldRow(
                            icon: Icons.add_road_outlined,
                            label: 'checkout.guest_form.street'.tr(),
                            hint: 'checkout.guest_form.street_hint'.tr(),
                            controller: _streetCtrl,
                            isDark: isDark,
                          ),

                          // District — editable (API often returns null)
                          _AddressFieldRow(
                            icon: Icons.map_outlined,
                            label: 'checkout.guest_form.district'.tr(),
                            hint: 'checkout.guest_form.district_hint'.tr(),
                            controller: _districtCtrl,
                            isDark: isDark,
                          ),

                          // Building, Postal Code, Additional Number on same row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AddressFieldRow(
                                    icon: Icons.apartment_outlined,
                                    label: 'checkout.guest_form.building'.tr(),
                                    hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                                    controller: _buildingCtrl,
                                    isDark: isDark,
                                    keyboardType: TextInputType.number,
                                    readOnly: true,
                                    margin: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _AddressFieldRow(
                                    icon: Icons.local_post_office_outlined,
                                    label: 'checkout.guest_form.postal'.tr(),
                                    hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                                    controller: _postalCodeCtrl,
                                    isDark: isDark,
                                    keyboardType: TextInputType.number,
                                    readOnly: true,
                                    margin: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _AddressFieldRow(
                                    icon: Icons.numbers_outlined,
                                    label: 'checkout.guest_form.extra'.tr(),
                                    hint: 'checkout.guest_form.auto_fill_hint'.tr(),
                                    controller: _additionalNumCtrl,
                                    isDark: isDark,
                                    keyboardType: TextInputType.number,
                                    readOnly: true,
                                    margin: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Landmark (optional) — replaces "full address"
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('checkout.guest_form.landmark'.tr(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      TextFormField(
                                        controller: _addressCtrl,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                                  vertical: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Phone — optional
                          _AddressFieldRow(
                            icon: Icons.phone_outlined,
                            label: 'address.phone'.tr() +
                                'address.optional_suffix'.tr(),
                            hint: 'address.hints.phone'.tr(),
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            isDark: isDark,
                          ),

                          // City dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('address.city'.tr(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      _AddressFieldRow(
                                        icon: Icons.location_city_outlined,
                                        label: '',
                                        hint: 'address.city'.tr(),
                                        controller: TextEditingController(text: _selectedCity?.name ?? ''),
                                        isDark: isDark,
                                        readOnly: true,
                                        margin: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Set as default toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('address.setAsDefault'.tr(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface)),
                                ),
                                Switch.adaptive(
                                  value: _isDefault,
                                  activeColor: ColorsManager.primaryColor,
                                  onChanged: (v) =>
                                      setState(() => _isDefault = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Pinned save button ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              // BoxShadow removed from save bar
            ),
            child: AppButton(
              text: 'common.save'.tr(),
              onPressed: _save,
              isLoading: isLoading,
              backgroundColor: ColorsManager.primary2Color,
              horizontalPadding: 0,
              verticalPadding: 0,
              borderRadius: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Web (unchanged design) ─────────────────────────────────────────────────

  Widget _buildWeb(BuildContext context, AddressesState state, bool isLoading) {
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStr = _isEdit ? 'address.edit'.tr() : 'address.add'.tr();
    final isWide = MediaQuery.sizeOf(context).width > 700 && widget.isModal;

    final content = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Dialog header with title + close button (only if modal) ──
            if (widget.isModal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      titleStr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: widget.isModal
                                ? double.infinity
                                : MediaQuery.sizeOf(context).width * 0.4),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 8),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!widget.isModal)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: WebBreadcrumb(
                                    isDark: isDark,
                                    labels: ['dashboard.home'.tr(), 'profile.addresses'.tr(), titleStr],
                                    onTaps: [
                                      () => AppNavigator.pushNamed(context, Routes.dashBoard),
                                      () => AppNavigator.pushNamed(context, Routes.addresses),
                                      null,
                                    ],
                                  ),
                                ),
                              Text(titleStr,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : ColorsManager.surfaceDarkElevated,
                                    letterSpacing: -0.5,
                                  )),
                              SizedBox(height: v.s32),

                              _buildResponsiveRow(
                                isWide,
                                _webField('address.label'.tr(),
                                    'address.hints.label'.tr(), _labelCtrl,
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'validation.required'.tr()
                                        : null),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _webField(
                                      'address.short_national_address'.tr(),
                                      'address.hints.short_national_address'.tr(),
                                      _shortAddressCtrl,
                                      validator: (v) => v == null || v.trim().isEmpty
                                          ? 'address.errors.short_national_address_required'.tr()
                                          : null,
                                      suffixIcon: _isLookingUp
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : IconButton(
                                              icon: const Icon(Icons.search),
                                              onPressed: _lookupShortAddress,
                                              color: ColorsManager.primaryColor,
                                            ),
                                    ),
                                    if (_lookupDone) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 13, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text('address.verified'.tr(), style: const TextStyle(fontSize: 12, color: Colors.green)),
                                        ],
                                      ),
                                    ] else if (!_isEdit) ...[
                                      const SizedBox(height: 4),
                                      Text('address.search_national_address'.tr(), style: TextStyle(fontSize: 11, color: ColorsManager.primaryColor.withValues(alpha: 0.7))),
                                    ],
                                  ],
                                ),
                              ),

                              _buildResponsiveRow(
                                isWide,
                                _webField('address.street'.tr(), 'address.hints.street'.tr(), _streetCtrl),
                                _webField('address.district'.tr(), 'address.hints.district'.tr(), _districtCtrl, required: false),
                              ),

                              Row(
                                children: [
                                  Expanded(child: _webField('address.building_number'.tr(), 'address.hints.auto_filled'.tr(), _buildingCtrl, keyboardType: TextInputType.number, readOnly: true)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _webField('address.postal_code'.tr(), 'address.hints.auto_filled'.tr(), _postalCodeCtrl, keyboardType: TextInputType.number, readOnly: true)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _webField('address.additional_number'.tr(), 'address.hints.auto_filled'.tr(), _additionalNumCtrl, keyboardType: TextInputType.number, readOnly: true)),
                                ],
                              ),
                              SizedBox(height: isWide ? 16 : v.s16),

                              _buildResponsiveRow(
                                isWide,
                                _webField('address.landmark_optional'.tr(), 'address.hints.landmark'.tr(), _addressCtrl, maxLines: 2, required: false),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _webField('address.phone'.tr() + 'address.optional_suffix'.tr(), 'address.hints.phone'.tr(), _phoneCtrl, keyboardType: TextInputType.phone, required: false),
                                    SizedBox(height: isWide ? 16 : v.s16),
                                    _webField('address.city'.tr(), '', TextEditingController(text: _selectedCity?.name ?? ''), readOnly: true),
                                  ],
                                ),
                              ),
                              SizedBox(height: v.s24),

                              // Default toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('address.setAsDefault'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Switch.adaptive(
                                      value: _isDefault,
                                      activeColor: ColorsManager.primaryColor,
                                      onChanged: (v) => setState(() => _isDefault = v),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: v.s32),
                              AppButton(
                                text: 'common.save'.tr(),
                                onPressed: _save,
                                isLoading: isLoading,
                                backgroundColor: ColorsManager.primary2Color,
                                horizontalPadding: 0,
                                verticalPadding: 0,
                                borderRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isModal) return content;
    return SimpleWebShell(content: content);
  }

  Widget _buildResponsiveRow(bool isWide, Widget child1, Widget child2) {
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child1),
            const SizedBox(width: 16),
            Expanded(child: child2),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child1,
        const SizedBox(height: 16),
        child2,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _webField(
    String label,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: readOnly ? dimColor : null,
                  fontSize: 14,
                )),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? dimColor : null,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: readOnly
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.06))
                : Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ColorsManager.primaryColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ColorsManager.errorFill)),
            suffixIcon: suffixIcon,
          ),
          validator: validator ??
              (required
                  ? (v) => v == null || v.trim().isEmpty
                      ? 'validation.required'.tr()
                      : null
                  : null),
        ),
      ],
    );
  }
}

// ── Field row widget ──────────────────────────────────────────────────────────

class _AddressFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool readOnly; // dims field — filled from API
  final EdgeInsetsGeometry? margin;

  const _AddressFieldRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dimColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.35);
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: readOnly ? dimColor : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  readOnly: readOnly,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: readOnly ? dimColor : cs.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorsManager.primaryColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorsManager.errorFill)),
                    filled: true,
                    fillColor: readOnly ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: suffixIcon,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final bool isDark;
  const _RowDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 62,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      );
}
