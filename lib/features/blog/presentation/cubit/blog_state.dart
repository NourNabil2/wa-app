import 'package:fastway/features/blog/domain/entities/blog_entity.dart';

abstract class BlogState {}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoaded extends BlogState {
  final List<BlogPost>     posts;
  final List<BlogPost>     filteredPosts;
  final BlogCategory       selectedCategory; // uses BlogCategory.all for "all"
  final List<BlogCategory> categories;       // from API, BlogCategory.all prepended

  BlogLoaded({
    required this.posts,
    required this.filteredPosts,
    required this.selectedCategory,
    required this.categories,
  });
}

class BlogDetailLoaded extends BlogState {
  final BlogPost post;
  final List<BlogPost> related;
  BlogDetailLoaded({required this.post, this.related = const []});
}

class BlogError extends BlogState {
  final String message;
  BlogError({required this.message});
}
