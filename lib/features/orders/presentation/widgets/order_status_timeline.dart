// lib/features/orders/presentation/widgets/order_status_timeline.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/order_entity.dart';

class OrderStatusTimeline extends StatelessWidget {
  final List<OrderTimelineEntity> timeline;

  const OrderStatusTimeline({
    super.key,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.inputSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: ColorsManager.inputBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.tracking.title'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.defaultText,
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(timeline.length, (index) {
            final item = timeline[index];
            final isLast = index == timeline.length - 1;
            
            return _TimelineItem(
              item: item,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final OrderTimelineEntity item;
  final bool isLast;

  const _TimelineItem({
    required this.item,
    required this.isLast,
  });

  Color get _activeColor => ColorsManager.primaryColor;
  Color get _inactiveColor => ColorsManager.inputBorder;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              // Dot
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: item.isCompleted ? _activeColor : ColorsManager.inputSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isCompleted ? _activeColor : _inactiveColor,
                    width: 2.w,
                  ),
                ),
                child: item.isCompleted
                    ? Icon(
                        Icons.check,
                        size: 14.sp,
                        color: ColorsManager.inputSurface
                      )
                    : null,
              ),
              
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    color: item.isCompleted ? _activeColor : _inactiveColor,
                  ),
                ),
            ],
          ),
          
          SizedBox(width: 12.w),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: item.isCompleted ? FontWeight.w600 : FontWeight.w400,
                    color: item.isCompleted 
                        ? ColorsManager.defaultText 
                        : ColorsManager.defaultTextSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorsManager.defaultTextSecondary,
                  ),
                ),
                if (item.timestamp != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(item.timestamp!),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: ColorsManager.defaultTextSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                SizedBox(height: isLast ? 0 : 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'orders.timeline.minutes_ago'.tr(args: ['${difference.inMinutes}']);
      }
      return 'orders.timeline.hours_ago'.tr(args: ['${difference.inHours}']);
    } else if (difference.inDays == 1) {
      return 'orders.timeline.yesterday'.tr(args: [DateFormat('HH:mm').format(date)]);
    } else {
      return DateFormat('dd/MM/yyyy - HH:mm').format(date);
    }
  }
}
