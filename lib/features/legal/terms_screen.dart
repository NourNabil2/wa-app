// lib/features/legal/terms_screen.dart
import 'package:fastway/core/widgets/static_content_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentPage(
      title: 'legal.terms.title'.tr(),
      titleAr: 'legal.terms.title'.tr(),
      subtitle: 'legal.terms.subtitle'.tr(),
      subtitleAr: 'legal.terms.subtitle'.tr(),
      icon: Icons.gavel_rounded,
      lastUpdated: 'legal.terms.last_updated'.tr(),
      sections: [
        StaticSection(
          heading: 'legal.terms.section_0_title'.tr(),
          headingAr: 'legal.terms.section_0_title'.tr(),
          body: 'legal.terms.section_0_body'.tr(),
          bodyAr: 'legal.terms.section_0_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_1_title'.tr(),
          headingAr: 'legal.terms.section_1_title'.tr(),
          body: 'legal.terms.section_1_body'.tr(),
          bodyAr: 'legal.terms.section_1_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_2_title'.tr(),
          headingAr: 'legal.terms.section_2_title'.tr(),
          body: 'legal.terms.section_2_body'.tr(),
          bodyAr: 'legal.terms.section_2_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_3_title'.tr(),
          headingAr: 'legal.terms.section_3_title'.tr(),
          body: 'legal.terms.section_3_body'.tr(),
          bodyAr: 'legal.terms.section_3_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_4_title'.tr(),
          headingAr: 'legal.terms.section_4_title'.tr(),
          body: 'legal.terms.section_4_body'.tr(),
          bodyAr: 'legal.terms.section_4_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_5_title'.tr(),
          headingAr: 'legal.terms.section_5_title'.tr(),
          body: 'legal.terms.section_5_body'.tr(),
          bodyAr: 'legal.terms.section_5_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_6_title'.tr(),
          headingAr: 'legal.terms.section_6_title'.tr(),
          body: 'legal.terms.section_6_body'.tr(),
          bodyAr: 'legal.terms.section_6_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.terms.section_7_title'.tr(),
          headingAr: 'legal.terms.section_7_title'.tr(),
          body: 'legal.terms.section_7_body'.tr(),
          bodyAr: 'legal.terms.section_7_body'.tr(),
        ),
      ],
    );
  }
}
