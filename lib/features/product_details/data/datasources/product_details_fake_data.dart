/*
// lib/features/product_details/data/datasources/product_details_fake_data.dart

import '../models/product_details_model.dart';

class ProductDetailsFakeData {
  static Future<ProductDetailsModel> getProductDetails(String productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return _mockProducts[productId] ?? _getDefaultProduct(productId);
  }

  static ProductDetailsModel _getDefaultProduct(String id) {
    return ProductDetailsModel(
      id: id,
      name: 'واي بروتين جولد ستاندرد',
      imageUrl:
      'https://th.bing.com/th/id/OIP.K75A4VUDe5bOKkMzDEpeJAHaHa?w=154&h=198&c=12&rs=1&p=0&bgcl=a875dd&r=0&o=6&dpr=1.3&pid=23.1',
      galleryImages: [
        'https://th.bing.com/th/id/OIP.K75A4VUDe5bOKkMzDEpeJAHaHa?w=154&h=198&c=12&rs=1&p=0&bgcl=a875dd&r=0&o=6&dpr=1.3&pid=23.1',
        'https://egyfitness.com/wp-content/uploads/2014/07/url.jpg',
        'https://th.bing.com/th/id/OIP.l1P8AfBlL1DJ09Wl7W7wFgAAAA?w=108&h=108&c=1&bgcl=368170&r=0&o=7&dpr=1.3&pid=ImgRC&rm=3',
      ],
      price: 189,
      originalPrice: 249,
      rating: 4.6,
      reviewCount: 198,
      isNew: true,
      isAvailable: true,
      description:
      'واي بروتين جولد ستاندرد من أوبتيموم نيوتريشن هو المكمل الأكثر مبيعاً عالمياً. يحتوي على 24 جرام بروتين عالي الجودة لكل حصة، مع إضافة الأحماض الأمينية الأساسية والجلوتامين.',
      brand: 'Optimum Nutrition',
      category: 'بروتين',
      nutritionFacts: const NutritionFactsModel(
        calories: 120,
        protein: 24,
        carbs: 3,
        fats: 1,
        servingSize: 30,
        servingUnit: 'جرام',
      ),
      ingredients: [
        'واي بروتين معزول',
        'واي بروتين مركز',
        'ببتيدات واي بروتين',
        'نكهات طبيعية',
        'ليسيثين الصويا',
      ],
      benefits: [
        'يساعد في بناء العضلات',
        'سريع الامتصاص',
        'يحتوي على BCAA',
        'قليل الدهون والكربوهيدرات',
        'سهل الخلط',
      ],
      usage:
      'اخلط مغرفة واحدة (30 جرام) مع 200-250 مل من الماء أو الحليب. تناول بعد التمرين مباشرة أو بين الوجبات.',
      reviews: [
        ProductReviewModel(
          id: '1',
          userName: 'أحمد محمد',
          userImage: 'https://i.pravatar.cc/150?img=1',
          rating: 5,
          comment: 'منتج ممتاز! طعمه رائع ونتائجه واضحة بعد أسبوعين',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ProductReviewModel(
          id: '2',
          userName: 'سارة علي',
          userImage: 'https://i.pravatar.cc/150?img=2',
          rating: 4.5,
          comment: 'جودة عالية جداً، لكن السعر مرتفع قليلاً',
          date: DateTime.now().subtract(const Duration(days: 12)),
        ),
        ProductReviewModel(
          id: '3',
          userName: 'محمد حسن',
          rating: 5,
          comment: 'أفضل بروتين جربته على الإطلاق!',
          date: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ],
      relatedProducts: ['2', '3', '7', '9'],
    );
  }

  static final Map<String, ProductDetailsModel> _mockProducts = {
    '1': ProductDetailsModel(
      id: '1',
      name: 'واي بروتين جولد ستاندرد',
      imageUrl:
      'https://th.bing.com/th/id/OIP.K75A4VUDe5bOKkMzDEpeJAHaHa?w=154&h=198&c=12&rs=1&p=0&bgcl=a875dd&r=0&o=6&dpr=1.3&pid=23.1',
      galleryImages: [
        'https://th.bing.com/th/id/OIP.K75A4VUDe5bOKkMzDEpeJAHaHa?w=154&h=198&c=12&rs=1&p=0&bgcl=a875dd&r=0&o=6&dpr=1.3&pid=23.1',
        'https://egyfitness.com/wp-content/uploads/2014/07/url.jpg',
        'https://th.bing.com/th/id/OIP.l1P8AfBlL1DJ09Wl7W7wFgAAAA?w=108&h=108&c=1&bgcl=368170&r=0&o=7&dpr=1.3&pid=ImgRC&rm=3',
      ],
      price: 189,
      originalPrice: 249,
      rating: 4.6,
      reviewCount: 198,
      isNew: true,
      isAvailable: true,
      description:
      'واي بروتين جولد ستاندرد من أوبتيموم نيوتريشن هو المكمل الأكثر مبيعاً عالمياً. يحتوي على 24 جرام بروتين عالي الجودة لكل حصة، مع إضافة الأحماض الأمينية الأساسية والجلوتامين.',
      brand: 'Optimum Nutrition',
      category: 'بروتين',
      nutritionFacts: const NutritionFactsModel(
        calories: 120,
        protein: 24,
        carbs: 3,
        fats: 1,
        servingSize: 30,
        servingUnit: 'جرام',
      ),
      ingredients: [
        'واي بروتين معزول',
        'واي بروتين مركز',
        'ببتيدات واي بروتين',
        'نكهات طبيعية',
        'ليسيثين الصويا',
      ],
      benefits: [
        'يساعد في بناء العضلات',
        'سريع الامتصاص',
        'يحتوي على BCAA',
        'قليل الدهون والكربوهيدرات',
        'سهل الخلط',
      ],
      usage:
      'اخلط مغرفة واحدة (30 جرام) مع 200-250 مل من الماء أو الحليب. تناول بعد التمرين مباشرة أو بين الوجبات.',
      reviews: [
        ProductReviewModel(
          id: '1',
          userName: 'أحمد محمد',
          userImage: 'https://i.pravatar.cc/150?img=1',
          rating: 5,
          comment: 'منتج ممتاز! طعمه رائع ونتائجه واضحة بعد أسبوعين',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ProductReviewModel(
          id: '2',
          userName: 'سارة علي',
          userImage: 'https://i.pravatar.cc/150?img=2',
          rating: 4.5,
          comment: 'جودة عالية جداً، لكن السعر مرتفع قليلاً',
          date: DateTime.now().subtract(const Duration(days: 12)),
        ),
        ProductReviewModel(
          id: '3',
          userName: 'محمد حسن',
          rating: 5,
          comment: 'أفضل بروتين جربته على الإطلاق!',
          date: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ],
      relatedProducts: ['2', '3', '7', '9'],
    ),
    '2': ProductDetailsModel(
      id: '2',
      name: 'كرياتين مونوهيدرات',
      imageUrl: 'https://egyfitness.com/wp-content/uploads/2014/07/url.jpg',
      galleryImages: [
        'https://egyfitness.com/wp-content/uploads/2014/07/url.jpg',
      ],
      price: 120,
      rating: 4.3,
      reviewCount: 85,
      isAvailable: true,
      description:
      'كرياتين نقي 100% يساعد على زيادة القوة والأداء الرياضي. مثالي للرياضيين ومحبي اللياقة البدنية.',
      brand: 'Universal Nutrition',
      category: 'كرياتين',
      nutritionFacts: const NutritionFactsModel(
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
        servingSize: 5,
        servingUnit: 'جرام',
      ),
      ingredients: [
        'كرياتين مونوهيدرات',
      ],
      benefits: [
        'يزيد القوة العضلية',
        'يحسن الأداء الرياضي',
        'يساعد في التعافي',
        'نقي 100%',
      ],
      usage: 'تناول 5 جرام يومياً مع الماء أو العصير',
      reviews: [],
      relatedProducts: ['1', '7', '9'],
    ),
  };
}*/
