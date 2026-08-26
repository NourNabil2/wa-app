// lib/features/onboarding/presentation/models/onboarding_item.dart

import 'package:flutter/material.dart';

class OnboardingItem {
  final String   image;
  final InlineSpan titleSpan;
  final String   subtitle;

  const OnboardingItem({
    required this.image,
    required this.titleSpan,
    required this.subtitle,
  });
}