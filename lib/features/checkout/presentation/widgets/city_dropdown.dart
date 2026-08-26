import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/features/checkout/domain/entities/city_entity.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// A searchable dropdown for selecting a Saudi city.
/// Pass [cities] from the Cubit's loaded state.
class CityDropdown extends StatefulWidget {
  final List<CityEntity> cities;
  final CityEntity? selectedCity;
  final ValueChanged<CityEntity?> onChanged;

  const CityDropdown({
    super.key,
    required this.cities,
    this.selectedCity,
    required this.onChanged,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  final _searchController = TextEditingController();
  List<CityEntity> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.cities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = widget.cities
          .where((c) =>
      c.name.toLowerCase().contains(lower) ||
          c.nameAr.contains(q))
          .toList();
    });
  }

  Future<void> _showPicker() async {
    _searchController.clear();
    _filtered = widget.cities;

    final chosen = await showModalBottomSheet<CityEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (ctx) => _CityPickerSheet(
        cities: widget.cities,
        initialSelected: widget.selectedCity,
      ),
    );

    if (chosen != null) widget.onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    final label = widget.selectedCity == null
        ? 'checkout.selectCity'.tr()
        : (isRtl
        ? widget.selectedCity!.nameAr
        : widget.selectedCity!.name);

    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: h.s16, vertical: v.s14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.keyboard_arrow_down_rounded,
                color: ColorsManager.primaryColor, size: t.s20),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: t.s14,
                color: widget.selectedCity == null
                    ? ColorsManager.defaultTextSecondary
                    : ColorsManager.defaultText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  final List<CityEntity> cities;
  final CityEntity? initialSelected;

  const _CityPickerSheet({required this.cities, this.initialSelected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _ctrl = TextEditingController();
  late List<CityEntity> _filtered;
  bool _isAr = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.cities;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAr = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = widget.cities
          .where((c) =>
      c.name.toLowerCase().contains(lower) ||
          c.nameAr.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: v.s8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorsManager.inputBorder,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s8),
            child: TextField(
              controller: _ctrl,
              onChanged: _filter,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'checkout.searchCity'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city = _filtered[i];
                final isSelected =
                    widget.initialSelected?.code == city.code;
                return ListTile(
                  onTap: () => Navigator.of(context).pop(city),
                  title: Text(
                    _isAr ? city.nameAr : city.name,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? ColorsManager.primaryColor
                          : ColorsManager.defaultText,
                      fontSize: t.s14,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                      color: ColorsManager.primaryColor)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}