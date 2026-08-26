// lib/features/product_details/presentation/view/product_details_screen.dart

import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/features/product_details/presentation/view/web/product_details_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';
import 'mobile/product_details_mobile.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductDetailsLoaded? _lastLoadedState;
  late String _activeProductId;

  @override
  void initState() {
    super.initState();
    _activeProductId = widget.productId;
    context.read<ProductDetailsCubit>().loadProductDetails(widget.productId);
  }

  void _switchVariant(String variantId) {
    setState(() => _activeProductId = variantId);
    context.read<ProductDetailsCubit>().loadProductDetails(variantId);
  }

  @override
  Widget build(BuildContext context) {
    // Use kIsWeb platform check (not pixel width) so narrow browser
    // windows still receive the full web layout with header + footer.
    final isWeb = isWebLayout(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CartCubit, CartState>(
          listener: (context, cartState) {
            if (cartState is AddedToCart) CustomSnackBar.show(context, message: cartState.message, type: SnackBarType.success);
            if (cartState is CartToastError) CustomSnackBar.show(context, message: cartState.message, type: SnackBarType.error);
          },
        ),
        BlocListener<ProductDetailsCubit, ProductDetailsState>(
          listener: (context, state) {
            if (state is ProductDetailsWaitlistSuccess) CustomSnackBar.show(context, message: state.message, type: SnackBarType.success);
            if (state is ProductDetailsWaitlistError) CustomSnackBar.show(context, message: state.message, type: SnackBarType.error);
            if (state is QuestionSubmitSuccess) CustomSnackBar.show(context, message: state.message, type: SnackBarType.success);
            if (state is QuestionSubmitError) CustomSnackBar.show(context, message: state.message, type: SnackBarType.error);
          },
        ),
      ],
      child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) {
          if (state is ProductDetailsLoaded) _lastLoadedState = state;

          if (_lastLoadedState != null) {
            if (isWeb) {
              return ProductDetailsWeb(
                product: _lastLoadedState!.product,
                productId: _activeProductId,
                quantity: _lastLoadedState!.quantity,
                questions: _lastLoadedState!.questions,
                questionsLoading: _lastLoadedState!.questionsLoading,
                onVariantSwitch: _switchVariant,
              );
            }
            return ProductDetailsMobile(
              product: _lastLoadedState!.product,
              productId: _activeProductId,
              quantity: _lastLoadedState!.quantity,
              questions: _lastLoadedState!.questions,
              questionsLoading: _lastLoadedState!.questionsLoading,
              onVariantSwitch: _switchVariant,
            );
          }

          if (state is ProductDetailsError) {
            return Scaffold(body: Center(child: Text(state.message)));
          }

          return Scaffold(
            body: ProductDetailSkeleton(isWeb: isWeb),
          );
        },
      ),
    );
  }
}