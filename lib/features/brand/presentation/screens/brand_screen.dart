// lib/features/brand/presentation/screens/brand_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/features/brand/presentation/cubit/brand_cubit.dart';
import 'package:fastway/features/home/presentation/view/products_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrandScreen extends StatefulWidget {
  final String brandId;
  final String brandName;
  final String? brandLogoUrl;

  const BrandScreen({
    super.key,
    required this.brandId,
    required this.brandName,
    this.brandLogoUrl,
  });

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BrandCubit>().loadBrand(widget.brandId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BrandCubit, BrandState>(
      builder: (context, state) {
        if (state is BrandLoading || state is BrandInitial) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0F18) : const Color(0xFFF6F7FB),
            appBar: CustomAppBar(title: widget.brandName),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is BrandError) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0F18) : const Color(0xFFF6F7FB),
            appBar: CustomAppBar(title: widget.brandName),
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<BrandCubit>().loadBrand(widget.brandId),
                  child: Text('common.retry'.tr()),
                ),
              ]),
            ),
          );
        }

        final brand = state is BrandLoaded ? state.brand : null;
        if (brand == null) {
          return const SizedBox.shrink();
        }

        return ProductsListScreen(
          brand: brand,
          title: Localizations.localeOf(context).languageCode == 'ar' ? (brand.nameAr ?? brand.name) : brand.name,
        );
      },
    );
  }
}
