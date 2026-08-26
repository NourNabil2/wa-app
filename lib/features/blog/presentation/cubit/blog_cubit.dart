import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/features/blog/data/datasources/blog_remote_datasource.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';
import 'blog_state.dart';

class BlogCubit extends Cubit<BlogState> {
  final BlogRemoteDataSource _datasource;

  BlogCubit(this._datasource) : super(BlogInitial());

  // ── Load posts + categories ───────────────────────────────────────────────

  Future<void> loadPosts({BlogCategory? initialCategory}) async {
    emit(BlogLoading());
    try {
      // Fetch both in parallel
      final results = await Future.wait([
        _datasource.getCategories(),
        _datasource.getPosts(),
      ]);

      final categories = [BlogCategory.all, ...(results[0] as List<BlogCategory>)];
      final posts      = results[1] as List<BlogPost>;

      final selected = initialCategory != null &&
              categories.any((c) => c.id == initialCategory.id)
          ? initialCategory
          : BlogCategory.all;

      final filtered = selected == BlogCategory.all
          ? posts
          : posts.where((p) => p.categoryId == selected.id).toList();

      emit(BlogLoaded(
        posts:            posts,
        filteredPosts:    filtered,
        selectedCategory: selected,
        categories:       categories,
      ));
    } catch (e) {
      emit(BlogError(message: e.toString()));
    }
  }

  // ── Filter locally (instant UI response) ─────────────────────────────────

  void filterByCategory(BlogCategory category) {
    final current = state;
    if (current is! BlogLoaded) return;

    final filtered = category == BlogCategory.all
        ? current.posts
        : current.posts.where((p) => p.categoryId == category.id).toList();

    emit(BlogLoaded(
      posts:            current.posts,
      filteredPosts:    filtered,
      selectedCategory: category,
      categories:       current.categories,
    ));
  }

  // ── Post detail ───────────────────────────────────────────────────────────

  Future<void> loadPostDetail(String slug) async {
    emit(BlogLoading());
    try {
      final results = await Future.wait([
        _datasource.getPost(slug),
        _datasource.getPosts(),
      ]);
      final post = results[0] as BlogPost;
      final allPosts = results[1] as List<BlogPost>;

      final related = allPosts
          .where((p) => p.slug != slug && p.categoryId == post.categoryId)
          .take(3)
          .toList();

      if (related.length < 3) {
        final more = allPosts
            .where((p) => p.slug != slug && !related.contains(p))
            .take(3 - related.length);
        related.addAll(more);
      }

      emit(BlogDetailLoaded(post: post, related: related));
    } catch (e) {
      emit(BlogError(message: e.toString()));
    }
  }
}
