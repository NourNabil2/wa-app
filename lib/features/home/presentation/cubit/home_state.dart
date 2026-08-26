// lib/features/home/presentation/cubit/home_state.dart
import 'package:equatable/equatable.dart';
import 'package:fastway/features/home/domain/entities/brand_entity.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/mid_banner_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BannerEntity> banners;
  final List<MidBannerEntity?> midBanners;
  final List<MidBannerEntity?> midBannersMobile;
  final List<CategoryEntity> categories;
  final List<CategoryEntity> campaignCategories;
  final List<ProductEntity> bestSellers;
  final List<ProductEntity> newArrivals;
  final List<ProductEntity> trendingProducts;
  final List<ProductEntity> buyAgain;
  final List<BrandEntity> brands;
  final List<ProductEntity> bundleProducts;

  const HomeLoaded({
    required this.banners,
    this.midBanners = const [null, null, null],
    this.midBannersMobile = const [null, null, null],
    required this.categories,
    required this.campaignCategories,
    required this.bestSellers,
    required this.newArrivals,
    required this.trendingProducts,
    required this.buyAgain,
    this.brands = const [],
    this.bundleProducts = const [],
  });

  @override
  List<Object?> get props => [
    banners,
    midBanners,
    midBannersMobile,
    categories,
    campaignCategories,
    bestSellers,
    newArrivals,
    trendingProducts,
    buyAgain,
    brands,
    bundleProducts,
  ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}