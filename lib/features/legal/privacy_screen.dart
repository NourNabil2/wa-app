// lib/features/legal/privacy_screen.dart
import 'package:fastway/core/widgets/static_content_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentPage(
      title: 'legal.privacy.title'.tr(),
      titleAr: 'legal.privacy.title'.tr(), // StaticContentPage handles isAr internally but we provide translated for both
      subtitle: 'legal.privacy.subtitle'.tr(),
      subtitleAr: 'legal.privacy.subtitle'.tr(),
      icon: Icons.shield_outlined,
      lastUpdated: 'legal.privacy.last_updated'.tr(),
      sections: [
        StaticSection(
          heading: 'legal.privacy.section_0_title'.tr(),
          headingAr: 'legal.privacy.section_0_title'.tr(),
          body: 'legal.privacy.section_0_body'.tr(),
          bodyAr: 'legal.privacy.section_0_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_1_title'.tr(),
          headingAr: 'legal.privacy.section_1_title'.tr(),
          body: 'legal.privacy.section_1_body'.tr(),
          bodyAr: 'legal.privacy.section_1_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_2_title'.tr(),
          headingAr: 'legal.privacy.section_2_title'.tr(),
          body: 'legal.privacy.section_2_body'.tr(),
          bodyAr: 'legal.privacy.section_2_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_3_title'.tr(),
          headingAr: 'legal.privacy.section_3_title'.tr(),
          body: 'legal.privacy.section_3_body'.tr(),
          bodyAr: 'legal.privacy.section_3_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_4_title'.tr(),
          headingAr: 'legal.privacy.section_4_title'.tr(),
          body: 'legal.privacy.section_4_body'.tr(),
          bodyAr: 'legal.privacy.section_4_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_5_title'.tr(),
          headingAr: 'legal.privacy.section_5_title'.tr(),
          body: 'legal.privacy.section_5_body'.tr(),
          bodyAr: 'legal.privacy.section_5_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.privacy.section_6_title'.tr(),
          headingAr: 'legal.privacy.section_6_title'.tr(),
          body: 'legal.privacy.section_6_body'.tr(),
          bodyAr: 'legal.privacy.section_6_body'.tr(),
        ),
      ],
    );
  }
}
