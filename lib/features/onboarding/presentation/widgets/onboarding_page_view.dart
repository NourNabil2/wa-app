// lib/features/onboarding/presentation/widgets/onboarding_single_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/theme/colors.dart';

import '../models/onboarding_item.dart';

class OnboardingSinglePage extends StatefulWidget {
  final OnboardingItem item;

  const OnboardingSinglePage({super.key, required this.item});


  @override
  State<OnboardingSinglePage> createState() => _OnboardingSinglePageState();
}

class _OnboardingSinglePageState extends State<OnboardingSinglePage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;

  // Image
  late final Animation<Offset> _imgSlide;
  late final Animation<double>  _imgFade;

  // Text block
  late final Animation<Offset> _textSlide;
  late final Animation<double>  _textFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _imgSlide = Tween(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.00, 0.65, curve: Curves.easeOutCubic)));
    _imgFade  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOut)));

    _textSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.45, 1.00, curve: Curves.easeOutCubic)));
    _textFade  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut)));

    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [

          // ── الصورة ────────────────────────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _imgSlide,
              child: FadeTransition(
                opacity: _imgFade,
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(widget.item.image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // ── Title + Subtitle ────────────────────────────────────────────
          SlideTransition(
            position: _textSlide,
            child: FadeTransition(
              opacity: _textFade,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  children: [
                    Text.rich(
                      widget.item.titleSpan,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:   22.sp,
                        fontWeight: FontWeight.bold,
                        color:      ColorsManager.defaultText,
                        height:     1.4,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      widget.item.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:    ColorsManager.defaultTextSecondary,
                        height:   1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 28.h),
        ],
      ),
    );
  }
}