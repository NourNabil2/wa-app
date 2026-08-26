// lib/features/legal/return_policy_screen.dart
import 'package:fastway/core/widgets/static_content_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentPage(
      title: 'legal.returns.title'.tr(),
      titleAr: 'legal.returns.title'.tr(),
      subtitle: 'legal.returns.subtitle'.tr(),
      subtitleAr: 'legal.returns.subtitle'.tr(),
      icon: Icons.assignment_return_outlined,
      lastUpdated: 'legal.returns.last_updated'.tr(),
      sections: [
        StaticSection(
          heading: 'legal.returns.section_0_title'.tr(),
          headingAr: 'legal.returns.section_0_title'.tr(),
          body: 'legal.returns.section_0_body'.tr(),
          bodyAr: 'legal.returns.section_0_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.returns.section_1_title'.tr(),
          headingAr: 'legal.returns.section_1_title'.tr(),
          body: 'legal.returns.section_1_body'.tr(),
          bodyAr: 'legal.returns.section_1_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.returns.section_2_title'.tr(),
          headingAr: 'legal.returns.section_2_title'.tr(),
          body: 'legal.returns.section_2_body'.tr(),
          bodyAr: 'legal.returns.section_2_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.returns.section_3_title'.tr(),
          headingAr: 'legal.returns.section_3_title'.tr(),
          body: 'legal.returns.section_3_body'.tr(),
          bodyAr: 'legal.returns.section_3_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.returns.section_4_title'.tr(),
          headingAr: 'legal.returns.section_4_title'.tr(),
          body: 'legal.returns.section_4_body'.tr(),
          bodyAr: 'legal.returns.section_4_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.returns.section_5_title'.tr(),
          headingAr: 'legal.returns.section_5_title'.tr(),
          body: 'legal.returns.section_5_body'.tr(),
          bodyAr: 'legal.returns.section_5_body'.tr(),
        ),
      ],
    );
  }
}
