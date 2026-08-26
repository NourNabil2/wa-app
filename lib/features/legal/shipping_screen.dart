// lib/features/legal/shipping_screen.dart
import 'package:fastway/core/widgets/static_content_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentPage(
      title: 'legal.shipping.title'.tr(),
      titleAr: 'legal.shipping.title'.tr(),
      subtitle: 'legal.shipping.subtitle'.tr(),
      subtitleAr: 'legal.shipping.subtitle'.tr(),
      icon: Icons.local_shipping_outlined,
      lastUpdated: 'legal.shipping.last_updated'.tr(),
      sections: [
        StaticSection(
          heading: 'legal.shipping.section_0_title'.tr(),
          headingAr: 'legal.shipping.section_0_title'.tr(),
          body: 'legal.shipping.section_0_body'.tr(),
          bodyAr: 'legal.shipping.section_0_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_1_title'.tr(),
          headingAr: 'legal.shipping.section_1_title'.tr(),
          body: 'legal.shipping.section_1_body'.tr(),
          bodyAr: 'legal.shipping.section_1_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_2_title'.tr(),
          headingAr: 'legal.shipping.section_2_title'.tr(),
          body: 'legal.shipping.section_2_body'.tr(),
          bodyAr: 'legal.shipping.section_2_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_3_title'.tr(),
          headingAr: 'legal.shipping.section_3_title'.tr(),
          body: 'legal.shipping.section_3_body'.tr(),
          bodyAr: 'legal.shipping.section_3_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_4_title'.tr(),
          headingAr: 'legal.shipping.section_4_title'.tr(),
          body: 'legal.shipping.section_4_body'.tr(),
          bodyAr: 'legal.shipping.section_4_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_5_title'.tr(),
          headingAr: 'legal.shipping.section_5_title'.tr(),
          body: 'legal.shipping.section_5_body'.tr(),
          bodyAr: 'legal.shipping.section_5_body'.tr(),
        ),
        StaticSection(
          heading: 'legal.shipping.section_6_title'.tr(),
          headingAr: 'legal.shipping.section_6_title'.tr(),
          body: 'legal.shipping.section_6_body'.tr(),
          bodyAr: 'legal.shipping.section_6_body'.tr(),
        ),
      ],
    );
  }
}
