// lib/main.dart
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:fastway/core/utils/app_constans.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fastway/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/routes/routes.dart';
import 'core/routes/web_route_observer.dart';
import 'core/service/app_initializer.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/push_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/biometric_lock_screen.dart';
import 'package:fastway/core/layout/web_url_helper.dart'
    if (dart.library.html) 'package:fastway/core/layout/web_url_helper_web.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/announcements/presentation/cubit/announcements_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/user_data/user_cubit.dart';
import 'features/user_data/user_repo.dart';
import 'core/cubit/delivery_location/delivery_location_cubit.dart';
import 'features/profile/presentation/cubit/addresses_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';


Future<void> _initGuestSession() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(AppConstants.sessionKey) == null) {
    await prefs.setString(AppConstants.sessionKey, const Uuid().v4());
  }
}

void main() async {
  // ⚠️ MUST be called before WidgetsFlutterBinding.ensureInitialized() on Web.
  // Switches from hash-based URLs (/#/products) to path URLs (/products).
  // gated by kIsWeb so mobile (iOS/Android) is completely unaffected.
  if (kIsWeb) usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for ALL platforms (Android, iOS, Web).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppInitializer.init();
  await _initGuestSession();
  // Fire-and-forget: AppSettingsService loads from SharedPrefs cache instantly;
  // the API call runs in the background so it never blocks the white screen.
  AppSettingsService.instance.initialize();

  // EasyLocalization MUST be initialized before runApp() on web.
  // Without this, _deviceLocale is a late field that hasn't been set,
  // causing a LateInitializationError crash on the first frame.
  await EasyLocalization.ensureInitialized();

  // Read the saved language so we can pass it as startLocale.
  // This ensures the very first frame renders in the correct language
  // without a flash of Arabic (the fallback locale) on English users.
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString(SettingsCubit.langKey) ?? 'ar';

  // Load persisted user before UI starts
  await UserRepository().loadUser();

  // Initialize FCM push handler — Android, iOS and Web.
  // PushHandler internally splits native vs web initialization paths.
  // We don't await this because on Web, requestPermission might block indefinitely 
  // without user interaction, preventing the app from rendering.
  PushHandler.instance.initialize(
    navigatorKey: AppRouter.navigatorKey,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      // startLocale synced with SettingsCubit's persisted value so the first
      // frame renders in the user's chosen language. On subsequent launches,
      // EasyLocalization also reads its own cache, so this just ensures
      // both systems agree from the start.
      startLocale: Locale(savedLang),
      child: const _AppProviders(),
    ),
  );

  // After the first frame the NavigatorState is mounted and ready.
  // Hook the browser back/forward button so it pops Flutter's route stack.
  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebUrlHelper.initBackButtonHandler(() async {
        // Signal to WebRouteObserver.didPop that this pop was triggered
        // by the browser back button — so it must NOT call goBack().
        WebRouteObserver.handlingBrowserBack = true;

        final navigator = AppRouter.navigatorKey.currentState;
        final popped = await navigator?.maybePop() ?? false;

        // Unconditionally clear the flag. If we only clear it when !popped,
        // or rely on didPop to clear it, popping a Dialog (which returns early from didPop)
        // leaves the flag stuck as true, breaking the next in-app back press.
        WebRouteObserver.handlingBrowserBack = false;
      });
    });
  }
}

/// Separating providers into their own widget keeps MyApp's build() lean
/// and makes it clear that providers sit INSIDE EasyLocalization.
class _AppProviders extends StatelessWidget {
  const _AppProviders();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(
          create: (_) => UserCubit(UserRepository()),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit()..loadSettings(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => di.sl<AuthCubit>(),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => di.sl<NotificationsCubit>()..fetchUnreadCount(),
          lazy: false,
        ),
        BlocProvider<AnnouncementsCubit>(
          create: (_) => di.sl<AnnouncementsCubit>()..fetchAnnouncements(),
          lazy: false,
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            final cubit = di.sl<ProfileCubit>();
            if (UserRepository().isLoggedIn) cubit.loadProfile();
            return cubit;
          },
          lazy: false,
        ),
        // DeliveryLocationCubit MUST come before HomeCubit and CartCubit —
        // HomeCubit reads the selected address from it on every loadHome() call,
        // and CartCubit reads coordinates for express eligibility.
        BlocProvider<DeliveryLocationCubit>(
          create: (context) => di.sl<DeliveryLocationCubit>(
            param1: context.read<UserCubit>(),
          )..resolveInitialLocation(),
          lazy: false,
        ),
        // HomeCubit depends on DeliveryLocationCubit — it sends the selected
        // address_id to the API so the backend uses that address's coordinates,
        // not the user's default address.
        // HomeCubit: do NOT call loadHome() here.
        // HomeTabScreen.initState() is the single source of truth for
        // triggering the home API — calling it twice caused the shimmer
        // to reset immediately after the first load completed.
        BlocProvider<HomeCubit>(
          create: (context) => di.sl<HomeCubit>(
            param1: context.read<DeliveryLocationCubit>(),
          ),
          lazy: false,
        ),
        BlocProvider<CartCubit>(
          create: (context) => di.sl<CartCubit>(
            param1: context.read<DeliveryLocationCubit>(),
          )..loadCart(),
        ),
        BlocProvider(create: (_) => di.sl<WishlistCubit>()),
        // AddressesCubit must be globally available so the checkout screen
        // ("Add Address" button) and DeliveryLocationCubit share the same instance.
        BlocProvider(create: (_) => di.sl<AddressesCubit>()),
      ],
      child: const MyApp(),
    );

  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is LoginSuccess) {
          // Clear or reload scoped data when auth state changes
          // to prevent state leakage between sessions.
          if (state is LoginSuccess) {
            context.read<CartCubit>().mergeAndLoad();
          } else {
            context.read<CartCubit>().loadCart();
          }
          context.read<WishlistCubit>().loadWishlist();
          if (state is AuthUnauthenticated) {
            // Addresses should be cleared for guests. The cubit will handle it or we just don't show them.
            // But doing a load() as guest returns 401. Best to just clear the list if possible, or ignore.
          } else {
            context.read<AddressesCubit>().load();
            context.read<ProfileCubit>().loadProfile();
          }
        }
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return ScreenUtilInit(
            designSize: _designSize,
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
            return MaterialApp(
              key: ValueKey(context.locale.languageCode),
              navigatorKey: AppRouter.navigatorKey,
              // Web: auto-sync browser URL on every route change (push, pop, replace)
              navigatorObservers: [WebRouteObserver()],
              scrollBehavior: const AppScrollBehavior(),
              theme: AppTheme.light,
              // darkTheme: AppTheme.dark,
              themeMode: ThemeMode.light, // settings.themeMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              // Use context.locale from easy_localization as the single
              // source of truth. SettingsCubit.setLanguage() and
              // context.setLocale() are always called together in _applyLang(),
              // so both stay in sync. MaterialApp must NOT override with
              // settings.locale or it breaks easy_localization's .tr() calls.
              locale: context.locale,
              // No initialRoute — Flutter reads the browser URL on boot (web)
              // or uses '/' on mobile (which maps to Dashboard via onGenerateRoute).
              onGenerateRoute: AppRouter.onGenerateRoute,
              // Graceful fallback: routes needing lost arguments redirect to Dashboard.
              onUnknownRoute: (_) => AppRouter.onGenerateRoute(
                const RouteSettings(name: Routes.dashBoard),
              ),
              // On web: wrap every page with a default-cursor scope so that
              // AnnotatedRegion<MouseCursor> (used in HoverableCard, GestureDetector
              // wrappers, etc.) can override the cursor to SystemMouseCursors.click.
              builder: (context, child) {
                Widget tree = child ?? const SizedBox.shrink();
                if (kIsWeb) {
                  tree = MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: tree,
                  );
                }
                return BiometricLockScreen(child: tree);
              },
            );
          },
        );
      },
      ),
    );
  }

  Size get _designSize {
    // Pick size based on physical screen width for all platforms
    final width = WidgetsBinding
        .instance.platformDispatcher.views.first.physicalSize.width;
    final dpr = WidgetsBinding
        .instance.platformDispatcher.views.first.devicePixelRatio;
    final logicalWidth = width / dpr;

    if (logicalWidth >= 900) return kIsWeb ? const Size(1440, 900) : const Size(390, 844);
    return const Size(414, 896);
  }
}

/// Enables trackpad/touch/stylus drag scrolling app-wide.
///
/// PointerDeviceKind.mouse is deliberately EXCLUDED. With the mouse registered
/// as a drag device, every Scrollable installs a drag-to-scroll recognizer that
/// competes in the gesture arena with SelectionArea's TapAndPanGestureRecognizer
/// — and for any drag with a vertical component the scrollable wins, so
/// click-dragging across text silently scrolled the page instead of selecting
/// the text. Excluding the mouse restores standard web behaviour: drag selects,
/// wheel scrolls (the wheel is a pointer signal, not a drag device, so vertical
/// and horizontal scrolling are unaffected).
///
/// Horizontal carousels have no selectable text and users do expect to swipe
/// them with the mouse, so they opt the mouse back in locally via
/// `ScrollConfiguration.of(context).copyWith(dragDevices: ...)` — see
/// products_row, brands_rail, promo_banner, product_image_gallery and the
/// categories rows.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}