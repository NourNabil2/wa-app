// lib/features/home/data/datasources/products_local_datasource.dart
// BUG-61: Replaced wrong-project supplement content with neutral ecommerce items
// BUG-62: Replaced expiring Bing CDN URLs with stable picsum.photos URLs
// BUG-13: Added nameAr to CategoryEntity mock data
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';

abstract class ProductsLocalDataSource {
  Future<List<ProductModel>> getProducts({int page, int perPage});
  Future<List<CategoryEntity>> getCategories();
}

class ProductsLocalDataSourceImpl implements ProductsLocalDataSource {
  @override
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final start = (page - 1) * perPage;
    final end = (start + perPage).clamp(0, _mockProducts.length);
    if (start >= _mockProducts.length) return [];
    return _mockProducts.sublist(start, end);
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCategories;
  }
}

const List<ProductModel> _mockProducts = [
  ProductModel(id: '1', name: 'Wireless Headphones', imageUrl: 'https://picsum.photos/seed/prod1/300/300', price: 189, originalPrice: 249, rating: 4.6, reviewCount: 198, isNew: true),
  ProductModel(id: '2', name: 'Smart Watch', imageUrl: 'https://picsum.photos/seed/prod2/300/300', price: 320, rating: 4.3, reviewCount: 85),
  ProductModel(id: '3', name: 'Running Shoes', imageUrl: 'https://picsum.photos/seed/prod3/300/300', price: 185, originalPrice: 220, rating: 4.8, reviewCount: 312, isNew: true),
  ProductModel(id: '4', name: 'Coffee Maker', imageUrl: 'https://picsum.photos/seed/prod4/300/300', price: 275, rating: 4.1, reviewCount: 44),
  ProductModel(id: '5', name: 'Backpack', imageUrl: 'https://picsum.photos/seed/prod5/300/300', price: 98, originalPrice: 130, rating: 4.5, reviewCount: 76),
  ProductModel(id: '6', name: 'Sunglasses', imageUrl: 'https://picsum.photos/seed/prod6/300/300', price: 145, rating: 4.0, reviewCount: 33, isNew: true),
  ProductModel(id: '7', name: 'Yoga Mat', imageUrl: 'https://picsum.photos/seed/prod7/300/300', price: 60, originalPrice: 80, rating: 4.7, reviewCount: 154),
  ProductModel(id: '8', name: 'Desk Lamp', imageUrl: 'https://picsum.photos/seed/prod8/300/300', price: 135, rating: 4.2, reviewCount: 91),
  ProductModel(id: '9', name: 'Bluetooth Speaker', imageUrl: 'https://picsum.photos/seed/prod9/300/300', price: 160, originalPrice: 200, rating: 4.4, reviewCount: 207),
  ProductModel(id: '10', name: 'Water Bottle', imageUrl: 'https://picsum.photos/seed/prod10/300/300', price: 45, rating: 4.3, reviewCount: 62, isNew: true),
  ProductModel(id: '11', name: 'Phone Stand', imageUrl: 'https://picsum.photos/seed/prod11/300/300', price: 25, originalPrice: 35, rating: 4.6, reviewCount: 289),
  ProductModel(id: '12', name: 'Notebook Set', imageUrl: 'https://picsum.photos/seed/prod12/300/300', price: 55, rating: 4.5, reviewCount: 118),
];

const List<CategoryEntity> _mockCategories = [
  CategoryEntity(id: '1', name: 'Electronics', nameAr: 'إلكترونيات', iconUrl: 'assets/icons/electronics.svg', color: '#E8F5F1'),
  CategoryEntity(id: '2', name: 'Clothing', nameAr: 'ملابس', iconUrl: 'assets/icons/clothing.svg', color: '#FFF3E0'),
  CategoryEntity(id: '3', name: 'Sports', nameAr: 'رياضة', iconUrl: 'assets/icons/sports.svg', color: '#E8EAF6'),
  CategoryEntity(id: '4', name: 'Home', nameAr: 'المنزل', iconUrl: 'assets/icons/home.svg', color: '#FCE4EC'),
  CategoryEntity(id: '5', name: 'Books', nameAr: 'كتب', iconUrl: 'assets/icons/books.svg', color: '#E0F7FA'),
  CategoryEntity(id: '6', name: 'Beauty', nameAr: 'جمال', iconUrl: 'assets/icons/beauty.svg', color: '#F3E5F5'),
];