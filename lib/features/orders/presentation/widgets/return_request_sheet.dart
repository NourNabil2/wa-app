import 'dart:typed_data';
import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/app_buton.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';

class ReturnRequestSheet extends StatefulWidget {
  final OrderEntity order;

  const ReturnRequestSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderEntity order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<OrdersCubit>(),
        child: ReturnRequestSheet(order: order),
      ),
    );
  }

  @override
  State<ReturnRequestSheet> createState() => _ReturnRequestSheetState();
}

class _ReturnRequestSheetState extends State<ReturnRequestSheet> {
  final _notesController = TextEditingController();
  String? _selectedReason;
  bool _imageError = false;

  // order_item_id -> quantity to return
  final Map<String, int> _selectedItems = {};
  // order_item_id -> condition
  final Map<String, String> _itemConditions = {};

  // Picked proof images (paths / blob URLs)
  final List<XFile> _images = [];

  final List<String> _reasons = [
    'wrong_item',
    'damaged',
    'not_as_described',
    'changed_mind',
    'other',
  ];

  final _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _images.length;
    if (remaining <= 0) {
      CustomSnackBar.show(context, message: 'orders.return_max_images'.tr(), type: SnackBarType.error);
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.take(remaining));
        if (_images.isNotEmpty) _imageError = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _submit() {
    if (_selectedItems.isEmpty) {
      CustomSnackBar.show(context, message: 'orders.return_select_items'.tr(), type: SnackBarType.error);
      return;
    }
    if (_selectedReason == null) {
      CustomSnackBar.show(context, message: 'orders.return_select_reason'.tr(), type: SnackBarType.error);
      return;
    }
    if (_images.isEmpty) {
      setState(() => _imageError = true);
      CustomSnackBar.show(context, message: 'orders.return_image_required'.tr(), type: SnackBarType.error);
      return;
    }

    final itemsPayload = _selectedItems.entries.map((e) => {
      'order_item_id': e.key,
      'quantity': e.value,
      'condition': _itemConditions[e.key] ?? 'unopened',
    }).toList();

    context.read<OrdersCubit>().submitReturn(
      orderNumber: widget.order.orderNumber,
      orderId: widget.order.id,
      items: itemsPayload,
      reason: _selectedReason!,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      imagePaths: _images.map((f) => f.path).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<OrdersCubit, OrdersState>(
      listener: (context, state) {
        if (state is OrderReturned) {
          Navigator.pop(context);
          CustomSnackBar.show(context, message: 'orders.return_success'.tr(), type: SnackBarType.success);
        } else if (state is OrderReturnError) {
          CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.90,
          decoration: BoxDecoration(
            color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.zero,
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'orders.request_return'.tr(),
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  // ── Items ──────────────────────────────────────────
                  _SectionTitle('orders.return_items'.tr()),
                  SizedBox(height: 12.h),
                  ...widget.order.items.map((item) {
                    final isSelected = _selectedItems.containsKey(item.id);
                    final quantity = _selectedItems[item.id] ?? 0;
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? ColorsManager.primaryColor
                              : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: ColorsManager.primaryColor,
                                onChanged: (val) => setState(() {
                                  if (val == true) {
                                    _selectedItems[item.id] = 1;
                                    _itemConditions[item.id] = 'unopened';
                                  } else {
                                    _selectedItems.remove(item.id);
                                    _itemConditions.remove(item.id);
                                  }
                                }),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    SizedBox(height: 4.h),
                                    Text('Max qty: ${item.quantity}',
                                        style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: quantity > 1
                                          ? () => setState(() => _selectedItems[item.id] = quantity - 1)
                                          : null,
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: quantity < item.quantity
                                          ? () => setState(() => _selectedItems[item.id] = quantity + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (isSelected) ...[
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text('orders.return_condition'.tr(), style: TextStyle(fontSize: 12.sp)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Container(
                                    height: 36.h,
                                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _itemConditions[item.id] ?? 'unopened',
                                        isExpanded: true,
                                        items: ['unopened', 'damaged', 'used'].map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text('orders.return_conditions.$c'.tr(), style: const TextStyle(fontSize: 12)),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _itemConditions[item.id] = val!),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 24.h),

                  // ── Reason ─────────────────────────────────────────
                  _SectionTitle('orders.return_reason'.tr()),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReason,
                        hint: Text('orders.return_select_reason_hint'.tr(), style: const TextStyle(fontSize: 14)),
                        isExpanded: true,
                        items: _reasons.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('orders.return_reasons.$r'.tr(), style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedReason = val),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ── Proof Images (MANDATORY) ────────────────────────
                  Row(
                    children: [
                      _SectionTitle('orders.return_proof_images'.tr()),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'orders.required'.tr(),
                          style: TextStyle(fontSize: 10.sp, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'orders.return_proof_hint'.tr(),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 12.h),

                  // Image grid
                  if (_images.isNotEmpty) ...[
                    SizedBox(
                      height: 100.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + (_images.length < 5 ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(width: 10.w),
                        itemBuilder: (context, index) {
                          if (index == _images.length) {
                            return _AddImageTile(onTap: _pickImages);
                          }
                          return _ImagePreviewTile(
                            xfile: _images[index],
                            onRemove: () => _removeImage(index),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_images.length}/5 ${'orders.return_images_selected'.tr()}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ] else ...[
                    // Empty state — tap to add
                    GestureDetector(
                      onTap: _pickImages,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 110.h,
                        decoration: BoxDecoration(
                          color: _imageError
                              ? Colors.red.withValues(alpha: 0.05)
                              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _imageError ? Colors.red : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            width: _imageError ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36.r,
                              color: _imageError ? Colors.red : Colors.grey,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'orders.return_add_images'.tr(),
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: _imageError ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_imageError) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'orders.return_image_required'.tr(),
                                style: TextStyle(fontSize: 11.sp, color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // ── Notes ──────────────────────────────────────────
                  _SectionTitle('orders.return_notes'.tr()),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'orders.return_notes_hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  BlocBuilder<OrdersCubit, OrdersState>(
                    builder: (context, state) {
                      return AppButton(
                        text: 'orders.return_submit'.tr(),
                        isLoading: state is OrderReturning,
                        onPressed: _submit,
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90.w,
        height: 90.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 28.r, color: ColorsManager.primaryColor),
            SizedBox(height: 4.h),
            Text('Add', style: TextStyle(fontSize: 11.sp, color: ColorsManager.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final XFile xfile;
  final VoidCallback onRemove;
  const _ImagePreviewTile({required this.xfile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: FutureBuilder<Uint8List>(
            future: xfile.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  width: 90.w,
                  height: 90.w,
                  fit: BoxFit.cover,
                );
              }
              return Container(
                width: 90.w,
                height: 90.w,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
