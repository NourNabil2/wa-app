
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum ClinicCardLayout {
  list,
  carousel,
  featured,
}

/// Error Type
enum ErrorType {
  network,
  server,
  auth,
  cache,
  validation,
  unknown;

  String get translationKey {
    switch (this) {
      case ErrorType.network:
        return 'errors.network';
      case ErrorType.server:
        return 'errors.server';
      case ErrorType.auth:
        return 'errors.auth';
      case ErrorType.cache:
        return 'errors.cache';
      case ErrorType.unknown:
        return 'errors.unknown';
        case ErrorType.validation:
        return 'errors.validation';
    }
  }
}

/// Medication Filter Types
enum MedicationFilter {
  all('all', 'core.enums.all', Icons.grid_view_rounded),
  daily('daily', 'core.enums.daily', Icons.calendar_today),
  alternateDays('alternate_days', 'core.enums.alternate_days', Icons.event_repeat),
  weekly('weekly', 'core.enums.weekly', Icons.calendar_month),
  asNeeded('as_needed', 'core.enums.as_needed', Icons.notifications_active);

  final String value;
  final String labelKey;
  final IconData icon;

  const MedicationFilter(this.value, this.labelKey, this.icon);

  String get label => labelKey.tr();

  static MedicationFilter fromValue(String value) {
    return MedicationFilter.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MedicationFilter.all,
    );
  }
}
