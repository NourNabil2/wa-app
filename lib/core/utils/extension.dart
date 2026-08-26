// lib/core/utils/date_extensions.dart
import 'package:fastway/core/widgets/error_state_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../errors/failures.dart';

/// Arabic plural rules (simplified for UI)
String _arPlural(int n, String one, String two, String few, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}

extension DateTimeX on DateTime {
  String timeAgo({String locale = 'ar', DateTime? now}) {
    final now0 = now ?? DateTime.now();
    Duration diff = now0.difference(this);
    final isFuture = diff.isNegative;
    if (isFuture) diff = diff.abs();

    if (diff.inSeconds < 45) {
      return locale.startsWith('ar') ? 'الآن' : 'just now';
    }

    String arPhrase(int n, String one, String two, String few, String many) {
      final core = _arPlural(n, one, two, few, many);
      return isFuture ? 'بعد $core' : 'قبل $core';
    }

    if (diff.inMinutes < 1) {
      final s = diff.inSeconds;
      return locale.startsWith('ar')
          ? arPhrase(s, 'ثانية', 'ثانيتين', 'ثوانٍ', 'ثانية')
          : isFuture ? 'in ${s}s' : '${s}s ago';
    }

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return locale.startsWith('ar')
          ? arPhrase(m, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة')
          : isFuture ? 'in ${m}m' : '${m}m ago';
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      return locale.startsWith('ar')
          ? arPhrase(h, 'ساعة', 'ساعتين', 'ساعات', 'ساعة')
          : isFuture ? 'in ${h}h' : '${h}h ago';
    }

    if (diff.inDays < 7) {
      final d = diff.inDays;
      return locale.startsWith('ar')
          ? arPhrase(d, 'يوم', 'يومين', 'أيام', 'يوم')
          : isFuture ? 'in ${d}d' : '${d}d ago';
    }

    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return locale.startsWith('ar')
          ? arPhrase(w, 'أسبوع', 'أسبوعين', 'أسابيع', 'أسبوع')
          : isFuture ? 'in ${w}w' : '${w}w ago';
    }

    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return locale.startsWith('ar')
          ? arPhrase(mo, 'شهر', 'شهرين', 'أشهر', 'شهر')
          : isFuture ? 'in ${mo}mo' : '${mo}mo ago';
    }

    final y = (diff.inDays / 365).floor();
    return locale.startsWith('ar')
        ? arPhrase(y, 'سنة', 'سنتين', 'سنوات', 'سنة')
        : isFuture ? 'in ${y}y' : '${y}y ago';
  }

  String timeAgoCtx(BuildContext context, {DateTime? now}) {
    final locale = Localizations.localeOf(context).languageCode;
    return timeAgo(locale: locale, now: now);
  }

  String yMd([String sep = '-']) =>
      '${year.toString().padLeft(4, '0')}$sep${month.toString().padLeft(2, '0')}$sep${day.toString().padLeft(2, '0')}';

  String dMy([String sep = '/']) =>
      '${day.toString().padLeft(2, '0')}$sep${month.toString().padLeft(2, '0')}$sep${year.toString().padLeft(4, '0')}';

  String hhmm() => '${_two(hour)}:${_two(minute)}';

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
  bool get isToday => isSameDay(DateTime.now());
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  int daysSince([DateTime? from]) => (from ?? DateTime.now()).difference(this).inDays;
  int daysUntil([DateTime? to]) => difference(to ?? DateTime.now()).inDays;
}

String _two(int n) => n.toString().padLeft(2, '0');

extension FailureExtensions on Failure {
  /// Convert failure to error widget
  Widget toErrorWidget({
    required VoidCallback onRetry,
    bool showAppBar = false,
  }) {
    return ErrorStateWidget(
      failure: this,
      onRetry: onRetry,
      showAppBar: showAppBar,
    );
  }

  /// Get localized title
  String getTitle() {
    return errorKey.tr();
  }

  /// Get localized message
  String getMessage() {
    return message;
  }

  /// Get error icon
  IconData getIcon() {
    if (this is NetworkFailure) {
      return Icons.wifi_off;
    } else if (this is UnauthorizedFailure) {
      return Icons.lock_outline;
    } else if (this is CacheFailure) {
      return Icons.storage;
    } else {
      return Icons.error_outline;
    }
  }

  /// Get error color
  Color getColor() {
    if (this is NetworkFailure) {
      return Colors.orange;
    } else if (this is UnauthorizedFailure) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}

extension DateTimeDayExtension on DateTime {
  /// Convert DateTime to day name (lowercase)
  /// Example: Sunday -> 'sunday'
  String get dayName {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  /// Convert DateTime to Arabic day name (lowercase)
  /// Example: Sunday -> 'الأحد'
  String get arabicDayName {
    const arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return arabicDays[weekday - 1];
  }
}

extension DoubleFormatX on double {
  /// Formats the price to remove .00 if it's a whole number
  String toPriceFormat() {
    if (this == truncateToDouble()) {
      return toStringAsFixed(0);
    }
    return toStringAsFixed(2);
  }
}
