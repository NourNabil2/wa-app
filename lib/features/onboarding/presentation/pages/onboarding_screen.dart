// lib/features/onboarding/presentation/pages/onboarding_screen.dart

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import '../../../../core/widgets/app_buton.dart';
import '../models/onboarding_item.dart';
import 'dart:ui' as ui;
import '../widgets/onboarding_page_view.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  final PageController _pageCtrl = PageController();
  int _current = 0;

  List<OnboardingItem> get _items => [
    OnboardingItem(
      image:    Assets.onboarding1,
      titleSpan: const TextSpan(
        children: [
          TextSpan(text: 'خصومات', style: TextStyle(color: ColorsManager.primaryColor)),
          TextSpan(text: ' و عروض حصرية...', style: TextStyle(color: ColorsManager.secondaryColor)),
        ],
      ),
      subtitle: 'onboarding.page1.subtitle'.tr(),
    ),
    OnboardingItem(
      image:    Assets.onboarding2,
      titleSpan: const TextSpan(
        children: [
          TextSpan(text: 'توصيل ', style: TextStyle(color: ColorsManager.secondaryColor)),
          TextSpan(text: 'سريع', style: TextStyle(color: ColorsManager.primaryColor)),
          TextSpan(text: ' لباب بيتك...', style: TextStyle(color: ColorsManager.secondaryColor)),
        ],
      ),
      subtitle: 'onboarding.page2.subtitle'.tr(),
    ),
    OnboardingItem(
      image:    Assets.onboarding3,
      titleSpan: const TextSpan(
        text: 'خيارات دفع متعددة',
        style: TextStyle(color: ColorsManager.secondaryColor),
      ),
      subtitle: 'onboarding.page3.subtitle'.tr(),
    ),
  ];

  bool get _isLastPage => _current == _items.length - 1;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _next() {
    if (!_isLastPage) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve:    Curves.easeInOutCubic,
      );
    } else {
      _goHome();
    }
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    AppNavigator.pushReplacementNamed(context, Routes.dashBoard);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            children: [
              _buildTopBar(),
              _buildPageView(),
              _buildButton(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          PageIndicator(count: _items.length, current: _current),
          const Spacer(),
          GestureDetector(
            onTap: _goHome,
            child: Text(
              'onboarding.skip'.tr(),
              style: TextStyle(
                fontSize:   14.sp,
                fontWeight: FontWeight.w600,
                color:      ColorsManager.defaultTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PageView ──────────────────────────────────────────────────────────────

  Widget _buildPageView() {
    return Expanded(
      child: PageView.builder(
        controller:    _pageCtrl,
        onPageChanged: (i) => setState(() => _current = i),
        itemCount:     _items.length,
        itemBuilder:   (_, i) => OnboardingSinglePage(item: _items[i]),
      ),
    );
  }

  // ── Button ────────────────────────────────────────────────────────────────

  Widget _buildButton() {
    return AppButton(
      text:              _isLastPage ? 'onboarding.start'.tr() : 'onboarding.next'.tr(),
      onPressed:         _next,
      leadingIcon:       Icons.chevron_left_rounded,
      horizontalPadding: 24.w,
      verticalPadding:   0,
    );
  }
}