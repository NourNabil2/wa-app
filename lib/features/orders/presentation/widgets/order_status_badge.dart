// lib/features/orders/presentation/widgets/order_status_badge.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  Color get _backgroundColor {
    switch (status) {
      case 'pending':
      case 'under_review':
        return ColorsManager.warningSurface;
      case 'pending_payment':
      case 'payment_unconfirmed':
        return ColorsManager.warningSurface;
      case 'processing':
        return ColorsManager.infoSurface;
      case 'shipped':
        return ColorsManager.primaryColor.withValues(alpha: 0.1);
      case 'out_for_delivery':
        return const Color(0xFF2563EB).withValues(alpha: 0.12);
      case 'delivered':
        return ColorsManager.successSurface;
      case 'cancelled':
        return ColorsManager.errorSurface;
      case 'cancellation_requested':
        return const Color(0xFFF97316).withValues(alpha: 0.12);
      default:
        return ColorsManager.defaultSurface;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'pending':
      case 'under_review':
        return ColorsManager.warningText;
      case 'pending_payment':
      case 'payment_unconfirmed':
        return ColorsManager.warningText;
      case 'processing':
        return ColorsManager.infoText;
      case 'shipped':
        return ColorsManager.primaryColor;
      case 'out_for_delivery':
        return const Color(0xFF2563EB);
      case 'delivered':
        return ColorsManager.successText;
      case 'cancelled':
        return ColorsManager.errorText;
      case 'cancellation_requested':
        return const Color(0xFFF97316);
      default:
        return ColorsManager.defaultTextSecondary;
    }
  }

  String get _translationKey {
    switch (status) {
      case 'pending':
        return 'orders.status.pending';
      case 'under_review':
        return 'orders.status.under_review';
      case 'pending_payment':
        return 'orders.status.pending_payment';
      case 'payment_unconfirmed':
        return 'orders.status.payment_unconfirmed';
      case 'processing':
        return 'orders.status.processing';
      case 'shipped':
        return 'orders.status.shipped';
      case 'out_for_delivery':
        return 'orders.status.out_for_delivery';
      case 'delivered':
        return 'orders.status.delivered';
      case 'cancelled':
        return 'orders.status.cancelled';
      case 'cancellation_requested':
        return 'orders.status.cancellation_requested';
      default:
        return 'orders.status.unknown';
    }
  }

  IconData get _icon {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'under_review':
        return Icons.pending_actions;
      case 'pending_payment':
      case 'payment_unconfirmed':
        return Icons.account_balance_wallet_outlined;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'cancellation_requested':
        return Icons.pending_actions;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 14,
            color: _textColor,
          ),
          const SizedBox(width: 4),
          Text(
            _translationKey.tr(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
