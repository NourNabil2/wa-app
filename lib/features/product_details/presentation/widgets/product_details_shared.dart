// lib/features/product_details/presentation/view/product_details_shared.dart

import 'package:fastway/features/product_details/domain/entities/product_details_entity.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/colors.dart';

// ── شارة "وفرت كذا" بتصميم إبداعي ومتحرك ──
class ProductSavingsBadge extends StatelessWidget {
  final double originalPrice;
  final double currentPrice;

  const ProductSavingsBadge({super.key, required this.originalPrice, required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    if (originalPrice <= currentPrice) return const SizedBox.shrink();

    final savedAmount = originalPrice - currentPrice;
    final savedPercent = ((savedAmount / originalPrice) * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.successFill.withValues(alpha: isDark ? 0.2 : 0.1),
            ColorsManager.successFill.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorsManager.successFill.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: ColorsManager.successFill, size: 18),
          const SizedBox(width: 6),
          Text(
            'product.price.saved_amount'.tr(args: [savedAmount.toStringAsFixed(0), savedPercent.toString()]),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ColorsManager.successFill,
            ),
          ),
        ],
      ),
    );
  }
}

// ── الأكورديون المشترك (للموبايل والويب) ──
class ProductAccordion extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  const ProductAccordion({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<ProductAccordion> createState() => _ProductAccordionState();
}

class _ProductAccordionState extends State<ProductAccordion> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _ctrl;
  late final Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: widget.initiallyExpanded ? 1.0 : 0.0);
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        // BoxShadow removed — 6 accordions × GPU blur = 6 paint ops per frame.
        // Border gives the same visual separation at zero GPU cost.
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Container(
                  //   width: 36, height: 36,
                  //   decoration: BoxDecoration(color: ColorsManager.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  //   child: Icon(widget.icon, size: 18, color: ColorsManager.primaryColor),
                  // ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expand,
            axisAlignment: -1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── جدول القيم الغذائية (Premium Nutrition Table) ──
class ProductNutritionWidget extends StatelessWidget {
  final dynamic facts; // بيمثل NutritionFacts

  const ProductNutritionWidget({super.key, required this.facts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // استخراج القيم بأمان
    final calories = facts.calories?.toString() ?? '-';
    final servingSize = facts.servingSize?.toString() ?? '-';
    final servingUnit = facts.servingUnit?.toString() ?? 'g';
    final protein = facts.protein?.toString() ?? '0';
    final carbs = facts.carbs?.toString() ?? '0';
    final fats = facts.fats?.toString() ?? '0';

    // ── دالة لبناء صفوف الجدول بشياكة ──
    Widget buildRow(String label, String value, {bool isHeader = false, bool isOdd = false, bool isLast = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          // خلفية متبادلة (Zebra Striping) لراحة العين
          color: isHeader
              ? ColorsManager.primaryColor.withValues(alpha: isDark ? 0.15 : 0.06)
              : (isOdd ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50) : Colors.transparent),
          // فاصل سفلي لكل صف ما عدا الأخير
          border: isLast ? null : Border(
            bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isHeader ? 14 : 13,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
                color: isHeader ? ColorsManager.primaryColor : cs.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isHeader ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: isHeader ? ColorsManager.primaryColor : cs.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // ── الإطار الخارجي للجدول ──
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // الهيدر (حجم الحصة)
            buildRow('product.nutrition.serving_size'.tr(), '$servingSize $servingUnit', isHeader: true),

            // باقي القيم متوزعة كجدول نظيف
            buildRow('product.nutrition.calories'.tr(), '$calories kcal', isOdd: false),
            buildRow('product.nutrition.protein'.tr(), '$protein g', isOdd: true),
            buildRow('product.nutrition.carbs'.tr(), '$carbs g', isOdd: false),
            buildRow('product.nutrition.fats'.tr(), '$fats g', isOdd: true, isLast: true),
          ],
        ),
      ),
    );
  }
}

// ── قسم التقييمات النظيف والفخم (Clean & Minimalist Reviews) ──
class ProductReviewsWidget extends StatefulWidget {
  final List<dynamic> reviews;

  const ProductReviewsWidget({super.key, required this.reviews});

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  int _visibleCount = 3; // البداية 3 تقييمات

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('product.no_reviews_yet'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // حساب متوسط التقييم
    double totalRating = 0;
    for (var r in widget.reviews) {
      totalRating += num.tryParse(r.rating?.toString() ?? '0')?.toDouble() ?? 0.0;
    }
    final average = totalRating / widget.reviews.length;

    // التقييمات اللي ظاهرة حالياً
    final displayedReviews = widget.reviews.take(_visibleCount).toList();
    final hasMore = _visibleCount < widget.reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. الهيدر (رقم كبير ونجوم بدون أي حواف أو خلفيات) ──
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < average.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'product.reviews.count'.tr(args: [widget.reviews.length.toString()]),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 2. اللستة (بدون كروت، فواصل ناعمة فقط) ──
        Column(
          children: displayedReviews.asMap().entries.map((entry) {
              final review = entry.value;
              final isLast = entry.key == displayedReviews.length - 1;

              return Column(
                children: [
                  _CleanReviewItem(review: review),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                        height: 1,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                      ),
                    ),
                ],
              );
            }).toList(),
        ),

        // ── 3. زرار "عرض المزيد" (باجنيشن 3 بـ 3) ──
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _visibleCount += 3; // بيزود 3 تقييمات كل ضغطة
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'product.show_more'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── عنصر التقييم النظيف (بدون Borders نهائياً) ──
class _CleanReviewItem extends StatelessWidget {
  final dynamic review;

  const _CleanReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rating = num.tryParse(review.rating?.toString() ?? '0')?.toDouble() ?? 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الأفاتار (بسيط جداً وبلون هادي)
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.onSurface.withValues(alpha: 0.05),
          child: Text(
            review.userName?.isNotEmpty == true ? review.userName![0].toUpperCase() : 'U',
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 14),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الاسم والتاريخ في سطر واحد
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.userName ?? 'product.user'.tr(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  if (review.date != null)
                    Text(
                      '${review.date.day}/${review.date.month}/${review.date.year}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // النجوم + شارة "مشتري موثق"
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                  if (review.isVerifiedPurchase) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 10, color: Colors.green),
                          const SizedBox(width: 3),
                          Text('product.verified_buyer'.tr(), style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ]
                ],
              ),

              // التعليق
              if (review.comment != null && review.comment.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  review.comment,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.8), // لون أفتح سِنة من الأسود الصريح لراحة العين
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

// ── Product Q&A Widget ───────────────────────────────────────────────────────
class ProductQAWidget extends StatefulWidget {
  final List<ProductQuestion> questions;
  final String productId;
  final bool isAuthenticated;
  final Future<void> Function(String question)? onSubmitQuestion;

  const ProductQAWidget({
    super.key,
    required this.questions,
    required this.productId,
    this.isAuthenticated = false,
    this.onSubmitQuestion,
  });

  @override
  State<ProductQAWidget> createState() => _ProductQAWidgetState();
}

class _ProductQAWidgetState extends State<ProductQAWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final q = _controller.text.trim();
    if (q.length < 5) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmitQuestion?.call(q);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('product.qa.question_sent'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Submit question box ──
        if (widget.isAuthenticated)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('product.ask_question'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'product.question_hint'.tr(),
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      'product.submit_question'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Q&A list ──
        if (widget.questions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('product.qa.no_questions'.tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          )
        else
          ...widget.questions.map((q) => _QAItem(question: q)),
      ],
    );
  }
}

class _QAItem extends StatelessWidget {
  final ProductQuestion question;
  const _QAItem({required this.question});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline_rounded, size: 16, color: ColorsManager.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.question,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(question.userName,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          // Answer
          if (question.answer != null && question.answer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 18, color: ColorsManager.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(question.answer!,
                        style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
