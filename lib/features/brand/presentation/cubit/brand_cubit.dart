// lib/features/brand/presentation/cubit/brand_cubit.dart
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fastway/features/brand/data/models/brand_model.dart';
import 'package:fastway/features/brand/domain/entities/brand_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class BrandState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BrandInitial extends BrandState {}

class BrandLoading extends BrandState {}

class BrandLoaded extends BrandState {
  final BrandEntity brand;
  final bool isLoadingMore;
  BrandLoaded({required this.brand, this.isLoadingMore = false});

  BrandLoaded copyWith({BrandEntity? brand, bool? isLoadingMore}) =>
      BrandLoaded(brand: brand ?? this.brand, isLoadingMore: isLoadingMore ?? this.isLoadingMore);

  @override
  List<Object?> get props => [brand, isLoadingMore];
}

class BrandError extends BrandState {
  final String message;
  BrandError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class BrandCubit extends Cubit<BrandState> {
  final Dio _dio;

  BrandCubit(this._dio) : super(BrandInitial());

  Future<void> loadBrand(String brandId) async {
    if (isClosed) return;
    emit(BrandLoading());
    try {
      final response = await _dio.get(
        '/brands/$brandId',
        queryParameters: {'page': 1, 'per_page': 12},
      );
      if (isClosed) return;
      final data = response.data['data'] as Map<String, dynamic>;
      emit(BrandLoaded(brand: BrandModel.fromJson(data)));
    } on DioException catch (e) {
      if (!isClosed) emit(BrandError(e.message ?? 'Failed to load brand'));
    } catch (e) {
      if (!isClosed) emit(BrandError(e.toString()));
    }
  }

  Future<void> loadMore(String brandId) async {
    final current = state;
    if (current is! BrandLoaded) return;
    if (current.isLoadingMore) return;
    if (current.brand.currentPage >= current.brand.lastPage) return;
    if (isClosed) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.brand.currentPage + 1;
    try {
      final response = await _dio.get(
        '/brands/$brandId',
        queryParameters: {'page': nextPage, 'per_page': 12},
      );
      if (isClosed) return;
      final data = response.data['data'] as Map<String, dynamic>;
      final newPage = BrandModel.fromJson(data);
      final merged = BrandModel(
        id: current.brand.id,
        name: current.brand.name,
        nameAr: current.brand.nameAr,
        logoUrl: current.brand.logoUrl,
        description: current.brand.description,
        country: current.brand.country,
        products: [...current.brand.products, ...newPage.products],
        total: newPage.total,
        currentPage: newPage.currentPage,
        lastPage: newPage.lastPage,
      );
      emit(BrandLoaded(brand: merged));
    } catch (_) {
      if (!isClosed) emit(current.copyWith(isLoadingMore: false));
    }
  }
}
