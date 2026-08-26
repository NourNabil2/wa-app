import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';
import 'package:fastway/features/user_data/auth_guard.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/routes/app_navigator.dart';

class NotifyMeButton extends StatelessWidget {
  final double height;
  final String productId;

  const NotifyMeButton({
    super.key,
    required this.productId,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
      listenWhen: (previous, current) =>
          current is ProductDetailsNotifyMeSuccess ||
          current is ProductDetailsNotifyMeError,
      listener: (context, state) {
        if (state is ProductDetailsNotifyMeSuccess) {
          CustomSnackBar.show(
            context,
            message: state.message.tr(),
            type: SnackBarType.success,
          );
        } else if (state is ProductDetailsNotifyMeError) {
          CustomSnackBar.show(
            context,
            message: state.message.tr(),
            type: SnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        return InkWell(
          onTap: () {
            if (AuthGuard.isGuest(context)) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text('auth.loginRequired'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  content: Text('auth.checkoutLoginMessage'.tr(), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('common.cancel'.tr()),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        AppNavigator.pushNamed(context, Routes.auth);
                      },
                      child: Text('auth.login'.tr()),
                    ),
                  ],
                ),
              );
              return;
            }
            context.read<ProductDetailsCubit>().notifyMe();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorsManager.primary2Color.withValues(alpha: 0.1),
              border: Border.all(color: ColorsManager.primary2Color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: ColorsManager.primary2Color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'notify_me'.tr(),
                  style: const TextStyle(
                    color: ColorsManager.primary2Color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
