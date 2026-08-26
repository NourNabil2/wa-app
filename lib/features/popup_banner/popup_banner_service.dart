import 'package:dio/dio.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/features/popup_banner/data/models/popup_banner_model.dart';
import 'package:fastway/features/popup_banner/presentation/widgets/popup_banner_dialog.dart';
import 'package:flutter/material.dart';

/// Fetches the active popup banner once per session and shows it.
/// Call [PopupBannerService.showIfNeeded] from home screen initState.
class PopupBannerService {
  static bool _shownThisSession = false;

  static Future<void> showIfNeeded(BuildContext context, Dio dio) async {
    if (_shownThisSession) return;
    _shownThisSession = true; // Mark immediately so re-entrant calls don't double-show

    try {
      final response = await dio.get(Endpoints.popupBanner);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) return; // No active popup configured
        final banner = PopupBannerModel.fromJson(data);
        if (!context.mounted) return;
        await showPopupBannerDialog(context, banner);
      }
    } catch (_) {
      // Silently ignore — popup is non-critical
    }
  }
}
