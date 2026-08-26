import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_cubit.dart';
import 'package:fastway/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fastway/features/auth/presentation/view/auth_screen.dart';
import 'package:fastway/features/auth/presentation/view/otp_verification_page.dart';
import 'package:fastway/features/auth/presentation/widget/taps/signup_tab.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/view/cart_screen.dart';
import 'package:fastway/features/checkout/domain/entities/place_order_result.dart';
import 'package:fastway/features/checkout/domain/entities/saved_address_entity.dart';
import 'package:fastway/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:fastway/features/checkout/presentation/view/checkout_screen.dart';
import 'package:fastway/features/checkout/presentation/view/order_success_screen.dart';
import 'package:fastway/features/checkout/presentation/view/pay_link_gate.dart';
import 'package:fastway/features/dashboard/dashboard.dart';
import 'package:fastway/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:fastway/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:fastway/features/orders/presentation/screens/order_details_screen.dart';
import 'package:fastway/features/orders/presentation/screens/order_tracking_screen.dart';
import 'package:fastway/features/orders/presentation/screens/orders_list_screen.dart';
import 'package:fastway/features/points/presentation/cubit/points_cubit.dart';
import 'package:fastway/features/points/presentation/view/points_screen.dart';
import 'package:fastway/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:fastway/features/wallet/presentation/view/wallet_screen.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_cubit.dart';
import 'package:fastway/features/product_details/presentation/view/product_details_screen.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/view/profile_screen.dart';
import 'package:fastway/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';
import 'package:fastway/features/blog/presentation/screens/blog_screen.dart';
import 'package:fastway/features/blog/presentation/screens/blog_detail_screen.dart';
import 'package:fastway/features/wishlist/presentation/view/wishlist_screen.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastway/features/home/presentation/view/categories_screen.dart';
import 'package:fastway/features/category/presentation/screens/sub_categories_screen.dart';
import 'package:fastway/features/home/presentation/view/products_list_screen.dart';
import 'package:fastway/features/home/presentation/view/location_map_screen.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/features/orders/domain/entities/order_entity.dart';
import 'package:fastway/features/orders/presentation/screens/return_status_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/features/search/presentation/view/search_sheet.dart';
import '../../features/auth/presentation/widget/taps/login_tab.dart';
import '../../features/auth/presentation/view/phone_login_screen.dart';
import '../../features/profile/presentation/cubit/addresses_cubit.dart';
import '../../features/profile/presentation/view/add_edit_address_screen.dart';
import '../../features/profile/presentation/view/addresses_screen.dart';
import '../di/injection_container.dart' as di;
import 'package:fastway/features/legal/terms_screen.dart';
import 'package:fastway/features/legal/privacy_screen.dart';
import 'package:fastway/features/legal/return_policy_screen.dart';
import 'package:fastway/features/legal/shipping_screen.dart';
import 'package:fastway/features/legal/contact_screen.dart';
import 'package:fastway/features/brand/presentation/screens/brand_screen.dart';
import 'package:fastway/features/brand/presentation/cubit/brand_cubit.dart';


class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  /// Helper: extract a path segment by position from the URL name.
  /// e.g. _seg('/orders/42/track', 1) → '42'
  static String? _seg(String name, int index) {
    final segs = Uri.tryParse(name)?.pathSegments;
    return (segs != null && segs.length > index) ? segs[index] : null;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';

    // ══════════════════════════════════════════════════════════════════════
    // DYNAMIC PATH ROUTES — ID/slug embedded in URL
    // These must be checked BEFORE the switch to handle sub-paths correctly.
    // ══════════════════════════════════════════════════════════════════════

    // /p/:slug  →  Product detail   e.g. /p/whey-protein-gold-123
    if (name.startsWith('/p/') || (name == '/p' && settings.arguments is String)) {
      final rawSlug = name.startsWith('/p/')
          ? name.substring(3)
          : settings.arguments as String;
      final productId = SlugUtils.extractId(rawSlug);
      return CupertinoPageRoute(
        settings: settings,
        builder: (_) => BlocProvider<ProductDetailsCubit>(
          create: (_) => sl<ProductDetailsCubit>(),
          child: ProductDetailsScreen(productId: productId),
        ),
      );
    }

    // /categories/:slug/sub  →  Sub-categories    e.g. /categories/protein-3/sub
    if (name.startsWith('/categories/') && name.endsWith('/sub')) {
      final rawSlug = _seg(name, 1) ?? '';
      final catId = SlugUtils.extractId(rawSlug);
      final cat = settings.arguments is CategoryEntity
          ? settings.arguments as CategoryEntity
          : CategoryEntity(id: catId, name: catId, nameAr: catId, iconUrl: '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SubCategoriesScreen(category: cat),
      );
    }

    // /categories/:slug  →  Products in category   e.g. /categories/protein-3
    if (name.startsWith('/categories/')) {
      final rawSlug = _seg(name, 1) ?? '';
      final catId = SlugUtils.extractId(rawSlug);
      final cat = settings.arguments is CategoryEntity
          ? settings.arguments as CategoryEntity
          : CategoryEntity(id: catId, name: catId, nameAr: catId, iconUrl: '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ProductsListScreen(category: cat),
      );
    }

    // /orders/:id/track   →  Order tracking    e.g. /orders/ORD-001/track
    if (name.startsWith('/orders/') && name.endsWith('/track')) {
      final orderId = _seg(name, 1) ?? (settings.arguments as String? ?? '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => BlocProvider(
          create: (_) => sl<OrdersCubit>(),
          child: OrderTrackingScreen(orderId: orderId),
        ),
      );
    }

    // /orders/:id/return  →  Return status     e.g. /orders/ORD-001/return
    if (name.startsWith('/orders/') && name.endsWith('/return')) {
      final orderId = _seg(name, 1);
      // On fresh load we don't have the full OrderEntity — go to order detail.
      if (settings.arguments is OrderEntity) {
        final order = settings.arguments as OrderEntity;
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => ReturnStatusScreen(order: order),
        );
      }
      // Fallback: redirect to order detail (user can re-initiate return)
      return onGenerateRoute(RouteSettings(
        name: '/orders/$orderId',
        arguments: orderId,
      ));
    }

    // /orders/:id  →  Order detail              e.g. /orders/ORD-001
    if (name.startsWith('/orders/') && _seg(name, 1) != null) {
      final orderId = _seg(name, 1) ?? (settings.arguments as String? ?? '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => BlocProvider(
          create: (_) => sl<OrdersCubit>(),
          child: OrderDetailsScreen(orderId: orderId),
        ),
      );
    }

    // /profile/addresses/:id/edit  →  Edit address
    if (name.startsWith('/profile/addresses/') && name.endsWith('/edit')) {
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider.value(
            value: args['cubit'] as AddressesCubit,
            child: AddEditAddressScreen(address: args['address'] as AddressEntity),
          ),
        );
      }
      // On refresh, redirect to addresses list
      return onGenerateRoute(const RouteSettings(name: Routes.addresses));
    }

    // /blog/:slug  →  Blog article               e.g. /blog/protein-guide
    // Note: /blog alone falls through to the list screen in the switch below.
    if (name.startsWith('/blog/')) {
      final slug = name.substring(6);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => BlogDetailScreen(slug: slug),
      );
    }

    // /verify/:phone  →  OTP verification
    if (name.startsWith('/verify/')) {
      final phone = Uri.decodeComponent(name.substring(8));
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => BlocProvider<AuthCubit>(
          create: (_) => di.sl<AuthCubit>(),
          child: OtpVerificationPage(phone: phone),
        ),
      );
    }

    // /pay/:token  →  Admin payment link → seed cart + open normal checkout
    if (name.startsWith('/pay/')) {
      final token = _seg(name, 1) ?? '';
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PayLinkGate(token: token),
      );
    }

    // /brands/:id  →  Brand page   e.g. /brands/1
    if (name.startsWith('/brands/')) {
      final brandId = _seg(name, 1) ?? '';
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => BlocProvider<BrandCubit>(
          create: (_) => di.sl<BrandCubit>(),
          child: BrandScreen(
            brandId: brandId,
            brandName: args?['brandName'] as String? ?? '',
            brandLogoUrl: args?['brandLogoUrl'] as String?,
          ),
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // STATIC ROUTES
    // ══════════════════════════════════════════════════════════════════════
    switch (name) {

      // ── Root / Dashboard ─────────────────────────────────────────────
      case '/':
      case Routes.dashBoard:
        int? initialIndex;
        if (settings.arguments is int) {
          initialIndex = settings.arguments as int;
        }
        if (!kIsWeb) {
          final prefs = di.sl<SharedPreferences>();
          final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
          if (!hasSeenOnboarding) {
            return MaterialPageRoute(
        settings: settings,builder: (_) => const OnboardingScreen());
          }
        }
        return MaterialPageRoute(
        settings: settings,builder: (_) => Dashboard(initialIndex: initialIndex));

      // ── Onboarding & Auth ─────────────────────────────────────────────
      case Routes.onboarding:
        return MaterialPageRoute(
        settings: settings,builder: (_) => const OnboardingScreen());

      case Routes.auth:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) {
            if (kIsWeb) return const AuthScreen();
            return BlocProvider<AuthCubit>(
              create: (_) => di.sl<AuthCubit>(),
              child: const PhoneLoginScreen(),
            );
          },
        );

      case Routes.login:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider<AuthCubit>(
            create: (_) => di.sl<AuthCubit>(),
            child: const PhoneLoginScreen(),
          ),
        );

      case Routes.passwordLogin:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider<AuthCubit>(
            create: (_) => di.sl<AuthCubit>(),
            child: const LoginScreen(),
          ),
        );

      case Routes.signup:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider<AuthCubit>(
            create: (_) => di.sl<AuthCubit>(),
            child: const SignupScreen(),
          ),
        );

      case Routes.verification:
        // Argument may be a plain phone String, or a Map carrying a debug OTP.
        final args = settings.arguments;
        final phone = args is Map
            ? (args['phone'] as String? ?? '')
            : (args as String? ?? '');
        final debugOtp = args is Map ? args['debugOtp'] as String? : null;
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider<AuthCubit>(
            create: (_) => di.sl<AuthCubit>(),
            child: OtpVerificationPage(phone: phone, debugOtp: debugOtp),
          ),
        );

      // ── Products ─────────────────────────────────────────────────────
      case Routes.products:
        final args = settings.arguments;
        String? productType;
        String? searchQuery;
        if (args is String) {
          productType = args;
        } else if (args is Map) {
          productType = args['productType'] as String?;
          searchQuery = args['searchQuery'] as String?;
        }
        return MaterialPageRoute(
        settings: settings,builder: (_) => ProductsListScreen(productType: productType, searchQuery: searchQuery));

      // ── Categories ───────────────────────────────────────────────────
      case Routes.categories:
        return MaterialPageRoute(
        settings: settings,builder: (_) => const CategoriesScreen());

      // ── Cart & Checkout ──────────────────────────────────────────────
      case Routes.cart:
        // Optional arg: a coupon code to auto-apply (from a discount push).
        final cartArgs = settings.arguments;
        final autoCoupon = (cartArgs is Map && cartArgs['coupon'] is String)
            ? cartArgs['coupon'] as String
            : null;
        return MaterialPageRoute(
        settings: settings,
          builder: (context) => BlocProvider.value(
            value: context.read<CartCubit>(),
            child: CartScreen(applyCouponCode: autoCoupon),
          ),
        );

      case Routes.checkout:
        return MaterialPageRoute(
        settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<CheckoutCubit>(
                create: (context) => sl<CheckoutCubit>(
                  param1: context.read<DeliveryLocationCubit>(),
                ),
              ),
              BlocProvider.value(value: context.read<CartCubit>()),
            ],
            child: const CheckoutScreen(),
          ),
        );

      case Routes.orderSuccess:
        // Accept either a full PlaceOrderResult (COD / place-order flow) or a
        // bare order-number String (Telr PaymentConfirmed flow, which only
        // carries the order number back from the gateway return). Passing a
        // String here used to fail the `as PlaceOrderResult` cast and fall
        // through to a blank dashboard route after a successful payment.
        final args = settings.arguments;
        PlaceOrderResult? result;
        if (args is PlaceOrderResult) {
          result = args;
        } else if (args is String && args.isNotEmpty) {
          result = PlaceOrderResult(
            orderId:     '',
            orderNumber: args,
            status:      'processing',
            total:       0,
            isCod:       false,
          );
        }
        if (result == null) return _dashRoute();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OrderSuccessScreen(result: result!),
        );

      // ── Orders ───────────────────────────────────────────────────────
      case Routes.orders:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider(
            create: (_) => sl<OrdersCubit>(),
            child: const OrdersListScreen(),
          ),
        );

      // ── Profile ──────────────────────────────────────────────────────
      case Routes.profile:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => const ProfileScreen(),
        );

      case Routes.points:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<PointsCubit>()),
              BlocProvider(create: (_) => sl<WalletCubit>()),
            ],
            child: const PointsScreen(),
          ),
        );

      case Routes.wallet:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider(
            create: (_) => sl<WalletCubit>()..loadWallet(),
            child: const WalletScreen(),
          ),
        );

      case Routes.notifications:
        return MaterialPageRoute(
        settings: settings,
          builder: (context) => BlocProvider.value(
            value: context.read<NotificationsCubit>(),
            child: const NotificationsScreen(),
          ),
        );

      case Routes.wishlist:
        return MaterialPageRoute(
        settings: settings,
          builder: (context) => BlocProvider.value(
            value: context.read<WishlistCubit>(),
            child: const WishlistScreen(),
          ),
        );

      // ── Addresses ────────────────────────────────────────────────────
      case Routes.addresses:
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider(
            create: (_) => sl<AddressesCubit>(),
            child: const AddressesScreen(),
          ),
        );

      case Routes.addAddress:
        final cubit = settings.arguments is AddressesCubit
            ? settings.arguments as AddressesCubit
            : sl<AddressesCubit>();
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: const AddEditAddressScreen(),
          ),
        );

      // ── Blog ───────────────────────────────────────────────────────────────
      case Routes.blog:
        // argument can be a BlogCategory (from NavBar chips) or null (open all)
        final cat = settings.arguments is BlogCategory
            ? settings.arguments as BlogCategory
            : null;
        return MaterialPageRoute(
        settings: settings,
          builder: (_) => BlogScreen(initialCategory: cat),
        );

      // ── Misc ─────────────────────────────────────────────────────────
      case Routes.search:
        return MaterialPageRoute(
        settings: settings,builder: (_) => const SearchSheet());

      case Routes.locationMap:
        return MaterialPageRoute(
        settings: settings,builder: (_) => const LocationMapScreen());

      case Routes.helpCenter:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text('profile.helpCenter'.tr()),
              leading: const BackButton(),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 72,
                      color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 16),
                  Text('profile.coming_soon'.tr(),
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );

      case Routes.tracking:
        return MaterialPageRoute(builder: (_) => const Dashboard());

      // ── Legal & Static Pages ──────────────────────────────────────────
      case Routes.terms:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TermsScreen(),
        );

      case Routes.privacy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrivacyScreen(),
        );

      case Routes.returnPolicy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ReturnPolicyScreen(),
        );

      case Routes.shipping:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ShippingScreen(),
        );

      case Routes.contact:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ContactScreen(),
        );


      default:
        return _dashRoute();
    }
  }

  /// Fallback route — always shows Dashboard.
  static Route<dynamic> _dashRoute() => MaterialPageRoute(
        builder: (_) => const Dashboard(),
      );

  static Route<dynamic> _errorRoute() => MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('common.error'.tr())),
        ),
      );
}