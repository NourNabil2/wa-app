// ── Blog Category ────────────────────────────────────────────────────────────

class BlogCategory {
  final String id;
  final String name;
  final String nameAr;
  final int postsCount;
  final String? image;

  const BlogCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    this.postsCount = 0,
    this.image,
  });

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      id:         json['id']?.toString() ?? '',
      name:       json['name'] ?? '',
      nameAr:     json['name_ar'] ?? '',
      postsCount: json['posts_count'] as int? ?? 0,
      image:      json['image'] as String?,
    );
  }

  /// All-categories sentinel used for the "All" filter chip.
  static const BlogCategory all = BlogCategory(id: '', name: 'All', nameAr: 'الكل');

  @override
  bool operator ==(Object other) => other is BlogCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Blog Post ────────────────────────────────────────────────────────────────

class BlogPost {
  final String id;
  final String title;
  final String titleAr;
  final String slug;
  final String excerpt;
  final String excerptAr;
  final String? coverImage;
  final int readTimeMinutes;
  final String publishedAt;
  final String? content;
  final String? contentAr;
  // Category info from the API
  final String? categoryId;
  final String? categoryName;
  final String? categoryNameAr;

  const BlogPost({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.slug,
    required this.excerpt,
    required this.excerptAr,
    this.coverImage,
    required this.readTimeMinutes,
    required this.publishedAt,
    this.content,
    this.contentAr,
    this.categoryId,
    this.categoryName,
    this.categoryNameAr,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id:              json['id']?.toString() ?? '',
      title:           json['title'] ?? '',
      titleAr:         json['title_ar'] ?? '',
      slug:            json['slug'] ?? '',
      excerpt:         json['excerpt'] ?? '',
      excerptAr:       json['excerpt_ar'] ?? '',
      coverImage:      json['cover_image'],
      readTimeMinutes: json['read_time_minutes'] ?? 0,
      publishedAt:     json['published_at'] ?? '',
      content:         json['content'],
      contentAr:       json['content_ar'],
      categoryId:      json['category_id']?.toString(),
      categoryName:    json['category_name'],
      categoryNameAr:  json['category_name_ar'],
    );
  }
}
