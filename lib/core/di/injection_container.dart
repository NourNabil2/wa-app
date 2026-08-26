import 'package:dio/dio.dart';
import 'package:fastway/features/legal/warehouse_cubit.dart';
import 'package:fastway/features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/user_data/user_cubit.dart';
import 'package:fastway/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:fastway/features/cart/data/datasources/cart_remote_datasource.dart'; // BUG-8.8
import 'package:fastway/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fastway/features/cart/domain/repositories/cart_repository.dart';
import 'package:fastway/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:fastway/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:fastway/features/cart/domain/usecases/merge_guest_cart_usecase.dart';
import 'package:fastway/features/cart/domain/usecases/remove_coupon_usecase.dart';
import 'package:fastway/features/cart/domain/usecases/update_quantity_usecase.dart';
import 'package:fastway/features/cart/domain/usecases/toggle_express_item_usecase.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/checkout/data/datasources/checkout_local_datasource.dart';
import 'package:fastway/features/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:fastway/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:fastway/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:fastway/features/checkout/domain/usecases/get_checkout_data_usecase.dart';
import 'package:fastway/features/checkout/domain/usecases/get_cities_usecase.dart';
import 'package:fastway/features/checkout/domain/usecases/get_payment_methods_usecase.dart';
import 'package:fastway/features/checkout/domain/usecases/get_shipping_methods_usecase.dart';
import 'package:fastway/features/checkout/domain/usecases/place_order_usecase.dart';
import 'package:fastway/features/checkout/domain/usecases/get_delivery_slots_usecase.dart';
import 'package:fastway/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:fastway/features/home/data/datasources/products_local_datasource.dart';
import 'package:fastway/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fastway/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:fastway/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fastway/features/orders/domain/repositories/orders_repository.dart';
import 'package:fastway/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/get_order_details_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/reorder_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/track_order_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/submit_return_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/submit_store_review_usecase.dart';
import 'package:fastway/features/orders/domain/usecases/submit_shipment_review_usecase.dart';
import 'package:fastway/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:fastway/features/points/data/datasources/points_remote_datasource.dart';
import 'package:fastway/features/points/data/repositories/points_repository_impl.dart';
import 'package:fastway/features/points/domain/repositories/points_repository.dart';
import 'package:fastway/features/points/domain/usecases/get_points_summary_usecase.dart';
import 'package:fastway/features/points/presentation/cubit/points_cubit.dart';
import 'package:fastway/features/product_details/data/datasources/product_details_remote_datasource.dart'; // BUG-42
import 'package:fastway/features/product_details/data/repositories/product_details_repository_impl.dart';
import 'package:fastway/features/product_details/domain/repositories/product_details_repository.dart';

import 'package:fastway/features/product_details/domain/usecases/get_product_details_usecase.dart';
import 'package:fastway/features/product_details/domain/usecases/toggle_favorite_usecase.dart';
import '../../features/product_details/domain/usecases/join_waitlist_usecase.dart';
import '../../features/product_details/domain/usecases/notify_me_usecase.dart';
import '../../features/product_details/domain/usecases/fetch_questions_usecase.dart';
import '../../features/product_details/domain/usecases/submit_question_usecase.dart';
import '../../features/product_details/domain/usecases/submit_review_usecase.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_cubit.dart';
import 'package:fastway/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:fastway/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:fastway/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fastway/features/profile/domain/repositories/profile_repository.dart';
import 'package:fastway/features/profile/domain/usecases/get_addresses_usecase.dart';
import 'package:fastway/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:fastway/features/points/domain/usecases/get_points_history_usecase.dart';
import 'package:fastway/features/profile/presentation/cubit/addresses_cubit.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';

import 'package:fastway/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:fastway/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:fastway/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fastway/features/wallet/domain/usecases/get_wallet_summary_usecase.dart';
import 'package:fastway/features/wallet/domain/usecases/get_wallet_history_usecase.dart';
import 'package:fastway/features/wallet/presentation/cubit/wallet_cubit.dart';

// Auth
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/cart/domain/usecases/apply_coupon_usecase.dart';
import '../../features/cart/domain/usecases/remove_item_usecase.dart';
import '../../features/profile/domain/usecases/add_address_usecase.dart';
import '../../features/profile/domain/usecases/delete_address_usecase.dart';
import '../../features/profile/domain/usecases/set_default_address_usecase.dart';
import '../../features/profile/domain/usecases/update_address_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/domain/usecases/lookup_address_usecase.dart';
import '../../features/profile/domain/usecases/get_nearest_address_usecase.dart';
import '../../features/user_data/user_repo.dart';

// Products
import 'package:fastway/features/home/data/datasources/products_remote_datasource.dart';
import 'package:fastway/features/home/data/repositories/products_repository_impl.dart';
import 'package:fastway/features/home/domain/repositories/products_repository.dart';
import 'package:fastway/features/home/domain/usecases/get_products_usecase.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/search/presentation/cubit/search_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/mock_api_interceptor.dart';
import '../api/local_database.dart';

import 'package:fastway/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:fastway/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:fastway/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_cubit.dart';

import 'package:fastway/features/blog/data/datasources/blog_remote_datasource.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_cubit.dart';

// Core
import '../api/base_api_services.dart';
import '../api/dio_client.dart';
import '../api/model/endpoints.dart';
import '../layout/web_nav_controller.dart';
import '../services/geocoding_service.dart';
import '../cubit/delivery_location/delivery_location_cubit.dart';

import 'package:fastway/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:fastway/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:fastway/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:fastway/features/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:fastway/features/wishlist/domain/usecases/toggle_wishlist_usecase.dart';
import 'package:fastway/features/wishlist/domain/usecases/remove_wishlist_item_usecase.dart';
import 'package:fastway/features/wishlist/domain/usecases/clear_wishlist_usecase.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import 'package:fastway/features/announcements/data/datasources/announcements_remote_data_source.dart';
import 'package:fastway/features/announcements/data/repositories/announcements_repository_impl.dart';
import 'package:fastway/features/announcements/domain/repositories/announcements_repository.dart';
import 'package:fastway/features/announcements/presentation/cubit/announcements_cubit.dart';

import 'package:fastway/features/brand/presentation/cubit/brand_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await _initExternal();
  _initCore();
  _initAuth();
  _initProducts();
  _initProfile();
  _initProductDetails();
  _initPoints();
  _initWallet();
  _registerCartDependencies();
  _initOrders(); // ← Orders Feature
  _initNotifications(); // ← Notifications Feature
  _initBlog(); // ← Blog Feature
  _initWishlist(); // ← Wishlist Feature
  _initAnnouncements(); // ← Announcements Feature
  _initWarehouses(); // ← Warehouses / Contact Us
  _initBrand(); // ← Brand Feature
}

Future<void> _initExternal() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}

void _initCore() {
  final dio = Dio(
    BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': '*/*',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(MockApiInterceptor(LocalDatabase(sl())));
  sl.registerLazySingleton(() => dio);

  sl.registerLazySingleton<BaseApiServices>(
        () => DioApiService(sl()),
  );
}

void _initAuth() {
  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(apiServices: sl(), userRepository: sl()),
  );

  sl.registerLazySingleton(() => UserRepository());

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));

  // Cubit
  sl.registerFactory(
        () => AuthCubit(
      loginUseCase: sl(),
      signupUseCase: sl(),
      logoutUseCase: sl(),
      verifyOtpUseCase: sl(),
      authRepository: sl(),
      userRepository: sl(),
    ),
  );
}

void _initProducts() {
  // DataSource - remote is primary
  sl.registerLazySingleton<ProductsRemoteDataSource>(
        () => ProductsRemoteDataSourceImpl(sl()),
  );
  // Local kept for fallback
  sl.registerLazySingleton<ProductsLocalDataSource>(
        () => ProductsLocalDataSourceImpl(),
  );

  // Repository uses remote
  sl.registerLazySingleton<ProductsRepository>(
        () => ProductsRepositoryImpl(sl<ProductsRemoteDataSource>()),
  );

  // UseCase
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));

  // HomeCubit receives the already-created DeliveryLocationCubit from main.dart
  // so it can read the selected address and call setExpressZone() after loading.
  sl.registerFactoryParam<HomeCubit, DeliveryLocationCubit, void>(
    (locationCubit, _) => HomeCubit(sl<ProductsRemoteDataSource>(), locationCubit),
  );

  
  // Search
  sl.registerFactory(() => SearchCubit(sl<ProductsRemoteDataSource>()));
}

void _initProductDetails() {
  // BUG-42 FIX: Register remote datasource and inject into repository
  sl.registerLazySingleton<ProductDetailsRemoteDataSource>(
        () => ProductDetailsRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ProductDetailsRepository>(
        () => ProductDetailsRepositoryImpl(sl<ProductDetailsRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductDetailsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteProductUseCase(sl()));
  sl.registerLazySingleton(() => JoinWaitlistUseCase(sl()));
  sl.registerLazySingleton(() => NotifyMeUseCase(sl()));
  sl.registerLazySingleton(() => FetchQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitQuestionUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReviewUseCase(sl()));

  sl.registerFactory(
    () => ProductDetailsCubit(
      getProductDetailsUseCase: sl(),
      toggleFavoriteUseCase: sl(),
      joinWaitlistUseCase: sl(),
      notifyMeUseCase: sl(),
      fetchQuestionsUseCase: sl(),
      submitQuestionUseCase: sl(),
    ),
  );
}

void _registerCartDependencies() {
  // ── Cart Data Sources ─────────────────────────────────
  sl.registerLazySingleton<CartLocalDataSource>(
        () => CartLocalDataSourceImpl(sl()),
  );
  // BUG-8.8 FIX: Register remote datasource for production cart sync
  sl.registerLazySingleton<CartRemoteDataSource>(
        () => CartRemoteDataSourceImpl(sl()),
  );

  // ── Cart Repository (uses remote datasource) ──────────
  sl.registerLazySingleton<CartRepository>(
        () => CartRepositoryImpl(sl<CartRemoteDataSource>()),
  );

  // ── Cart Use Cases ────────────────────────────────────
  sl.registerLazySingleton(() => GetCartUseCase(sl()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl()));
  sl.registerLazySingleton(() => UpdateQuantityUseCase(sl()));
  sl.registerLazySingleton(() => RemoveItemUseCase(sl()));
  sl.registerLazySingleton(() => ApplyCouponUseCase(sl()));
  sl.registerLazySingleton(() => ToggleExpressItemUseCase(sl()));
  sl.registerLazySingleton(() => MergeGuestCartUseCase(sl()));

  sl.registerLazySingleton(() => RemoveCouponUseCase(sl())); // was missing
  sl.registerLazySingleton<CheckoutLocalDataSource>(
        () => CheckoutLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CheckoutRemoteDataSource>(
        () => CheckoutRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
        () => CheckoutRepositoryImpl(sl()),
  );

  // ── Checkout Use Cases ────────────────────────────────
  sl.registerLazySingleton(() => GetCheckoutDataUseCase(sl()));
  sl.registerLazySingleton(() => GetShippingMethodsUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentMethodsUseCase(sl()));
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl()));
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton(() => GetCountriesUseCase(sl()));
  sl.registerLazySingleton(() => GetAddressesUseCase(sl()));
  sl.registerLazySingleton(() => GetDeliverySlotsUseCase(sl()));

  // ── Cubits ────────────────────────────────────────────
  // CartCubit is a FactoryParam: it receives DeliveryLocationCubit from main.dart
  // so it can automatically use the globally-selected delivery address for all
  // cart API calls (express eligibility, etc.)
  sl.registerFactoryParam<CartCubit, DeliveryLocationCubit, void>(
    (locationCubit, _) => CartCubit(
      getCartUseCase: sl(),
      addToCartUseCase: sl(),
      updateQuantityUseCase: sl(),
      removeItemUseCase: sl(),
      applyCouponUseCase: sl(),
      removeCouponUseCase: sl(),
      toggleExpressItemUseCase: sl(),
      mergeGuestCartUseCase: sl(),
      locationCubit: locationCubit,
    ),
  );



  sl.registerLazySingleton(() => AddAddressUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAddressUseCase(sl()));
  sl.registerLazySingleton(() => SetDefaultAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAddressUseCase(sl()));
  sl.registerLazySingleton(() => LookupAddressUseCase(sl()));
  sl.registerLazySingleton(() => GetNearestAddressUseCase(sl()));

  sl.registerLazySingleton<GeocodingService>(
        () => GeocodingServiceImpl(sl()),
  );

  sl.registerFactoryParam<DeliveryLocationCubit, UserCubit, void>((userCubit, _) => DeliveryLocationCubit(
    userCubit: userCubit,
    addressesCubit: sl(),
    geocodingService: sl(),
  ));

  sl.registerLazySingleton(() => AddressesCubit(
    get: sl(),
    add: sl(),
    update: sl(),
    delete: sl(),
    setDefault: sl(),
    getCities: sl(),
    lookupAddress: sl(),
  ));

  // CheckoutCubit is FactoryParam: created fresh per checkout session,
  // injected with the global DeliveryLocationCubit as the location source.
  sl.registerFactoryParam<CheckoutCubit, DeliveryLocationCubit, void>(
    (locationCubit, _) => CheckoutCubit(
      getCheckoutDataUseCase: sl(),
      getShippingMethodsUseCase: sl(),
      getPaymentMethodsUseCase: sl(),
      getCitiesUseCase: sl(),
      getCountriesUseCase: sl(),
      placeOrderUseCase: sl(),
      getAddressesUseCase: sl(),
      getDeliverySlotsUseCase: sl(),
      checkoutRepository: sl(),
      locationCubit: locationCubit,
      applyCouponUseCase: sl(),
      removeCouponUseCase: sl(),
    ),
  );
}

void _initProfile() {
  // Remote data source
  sl.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(sl()),
  );
  // Local data source (settings, logout)
  sl.registerLazySingleton<ProfileLocalDataSource>(
        () => ProfileLocalDataSourceImpl(sl()),
  );

  // Repository — uses both remote (profile) + local (settings)
  sl.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(sl(), sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSettingsUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  // Cubit
  sl.registerFactory(
        () => ProfileCubit(
      getProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      logoutUseCase: sl(),
      getSettingsUseCase: sl(),
      updateSettingsUseCase: sl(),
      changePasswordUseCase: sl(),
      uploadAvatarUseCase: sl(),
      deleteAccountUseCase: sl(),
    ),
  );
}

void _initPoints() {
  // Remote data source
  sl.registerLazySingleton<PointsRemoteDataSource>(
        () => PointsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PointsRepository>(
        () => PointsRepositoryImpl(sl<PointsRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetPointsSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetPointsHistoryUseCase(sl()));
  sl.registerFactory(() => PointsCubit(
    getPointsSummaryUseCase: sl(),
    getPointsHistoryUseCase: sl(),
  ));
}

void _initWallet() {
  sl.registerLazySingleton<WalletRemoteDataSource>(
        () => WalletRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<WalletRepository>(
        () => WalletRepositoryImpl(sl<WalletRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetWalletSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetWalletHistoryUseCase(sl()));
  sl.registerFactory(() => WalletCubit(
    getWalletSummaryUseCase: sl(),
    getWalletHistoryUseCase: sl(),
  ));
}
// ORDERS FEATURE

void _initOrders() {
  // Remote data source (primary for production)
  sl.registerLazySingleton<OrdersRemoteDataSource>(
        () => OrdersRemoteDataSourceImpl(sl()),
  );
  // Keep local registered (for offline/caching later)
  sl.registerLazySingleton<OrdersLocalDataSource>(
        () => OrdersLocalDataSourceImpl(sl()),
  );

  // Repository uses remote
  sl.registerLazySingleton<OrdersRepository>(
        () => OrdersRepositoryImpl(sl<OrdersRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderDetailsUseCase(sl()));
  sl.registerLazySingleton(() => TrackOrderUseCase(sl()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl()));
  sl.registerLazySingleton(() => ReorderUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReturnUseCase(sl()));
  sl.registerLazySingleton(() => SubmitStoreReviewUseCase(sl()));
  sl.registerLazySingleton(() => SubmitShipmentReviewUseCase(sl()));

  sl.registerFactory(() => OrdersCubit(
    getOrdersUseCase: sl(),
    getOrderDetailsUseCase: sl(),
    trackOrderUseCase: sl(),
    cancelOrderUseCase: sl(),
    reorderUseCase: sl(),
    submitReturnUseCase: sl(),
    submitStoreReviewUseCase: sl(),
    submitShipmentReviewUseCase: sl(),
    submitReviewUseCase: sl(),
  ));
}

// NOTIFICATIONS FEATURE

void _initNotifications() {
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSourceImpl(api: sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(() => NotificationsCubit(repository: sl()));
}

// BLOG FEATURE

void _initBlog() {
  sl.registerLazySingleton<BlogRemoteDataSource>(
        () => BlogRemoteDataSourceImpl(sl()),
  );
  // Singleton so every part of the app (NavBar, BlogScreen, Dashboard)
  // shares the same cubit state — no duplicate API calls, no provider lookups.
  sl.registerLazySingleton<BlogCubit>(() => BlogCubit(sl()));
}

// WISHLIST FEATURE

void _initWishlist() {
  sl.registerLazySingleton<WishlistRemoteDataSource>(
    () => WishlistRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(sl<WishlistRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetWishlistUseCase(sl()));
  sl.registerLazySingleton(() => ToggleWishlistUseCase(sl()));
  sl.registerLazySingleton(() => RemoveWishlistItemUseCase(sl()));
  sl.registerLazySingleton(() => ClearWishlistUseCase(sl()));

  sl.registerLazySingleton(() => WishlistCubit(
    getWishlist:  sl(),
    toggle:       sl(),
    removeItem:   sl(),
    clear:        sl(),
  ));
}

// ANNOUNCEMENTS FEATURE
void _initAnnouncements() {
  sl.registerLazySingleton<AnnouncementsRemoteDataSource>(
    () => AnnouncementsRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AnnouncementsRepository>(
    () => AnnouncementsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(() => AnnouncementsCubit(repository: sl()));
}

// WAREHOUSES FEATURE (Contact Us)
void _initWarehouses() {
  sl.registerFactory(() => WarehouseCubit(sl()));
}

// BRAND FEATURE
void _initBrand() {
  sl.registerFactory(() => BrandCubit(sl()));
}
