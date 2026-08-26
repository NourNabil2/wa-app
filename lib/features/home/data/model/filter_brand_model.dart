/// Lightweight brand model used exclusively by the product filter sidebar.
/// The full [BrandEntity] is too heavy (includes products list) for this use-case.
class FilterBrandModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? logoUrl;

  const FilterBrandModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.logoUrl,
  });

  factory FilterBrandModel.fromJson(Map<String, dynamic> json) {
    String s(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }

    return FilterBrandModel(
      id: json['id'].toString(),
      name: s(json['name'], 'Unknown'),
      nameAr: json['name_ar']?.toString(),
      logoUrl: json['logo_url']?.toString(),
    );
  }

  String localizedName(String locale) =>
      locale == 'ar' && (nameAr?.isNotEmpty ?? false) ? nameAr! : name;
}
