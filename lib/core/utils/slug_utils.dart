// lib/core/utils/slug_utils.dart
//
// SEO-friendly URL slug generation and parsing.
//
// Pattern: /p/whey-protein-gold-standard-123
//   └── human-readable slug ──────────┘└ id
//
// The ID is always the LAST segment after the final hyphen.
// This ensures the URL is both readable and reliably resolvable.

class SlugUtils {
  /// Generate a URL-safe slug from a name + ID.
  /// Example: slugify('Whey Protein Gold Standard', '123')
  ///       → 'whey-protein-gold-standard-123'
  static String slugify(String name, String id) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')   // ASCII only
        .replaceAll(RegExp(r'[\s_]+'), '-')          // spaces → hyphen
        .replaceAll(RegExp(r'-{2,}'), '-')           // collapse hyphens
        .replaceAll(RegExp(r'^-+|-+$'), '');          // trim hyphens

    // If slug is empty (e.g. pure Arabic name), just use the ID
    if (slug.isEmpty) return id;
    return '$slug-$id';
  }

  /// Extract the ID from a slug URL segment.
  /// Example: extractId('whey-protein-gold-standard-123') → '123'
  ///          extractId('123') → '123'  (fallback: treat whole thing as ID)
  static String extractId(String slug) {
    if (slug.isEmpty) return '';
    final lastHyphen = slug.lastIndexOf('-');
    if (lastHyphen == -1) return slug; // no hyphen → whole string is the ID
    final candidate = slug.substring(lastHyphen + 1);
    // Only extract if it looks like an ID (numeric or alphanumeric)
    if (candidate.isNotEmpty) return candidate;
    return slug;
  }

  /// Generate a category slug from name + ID.
  /// Example: categorySlug('Protein', '3') → 'protein-3'
  static String categorySlug(String name, String id) => slugify(name, id);
}
