import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../di/injection_container.dart' as di;

class AppInitializer {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    /// Initialize services
    await _initLanguages();
    /// Initialize dependencies
    await di.init();

  }

  static Future<void> _initLanguages() async {
    initializeDateFormatting('ar', null);
    initializeDateFormatting('en_US', null);
  }
}