// lib/core/utils/app_size.dart
//
// ALL sizes are now fixed pixel values — no flutter_screenutil scaling.
// .sp/.w/.h cause text and layout to appear tiny on web viewports because
// screenutil scales relative to a 375px design width, shrinking everything
// on larger screens. Fixed values are consistent across all platforms.

class SizeApp {
  static const double radius = 16.0;
  static const double radiusMed = 16.0;
  static const double radiusSmall = 8.0;
  static const double padding = 16.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s5 = 5.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s30 = 30.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s44 = 44.0;
  static const double s48 = 48.0;
  static const double s50 = 50.0;
  static const double s60 = 60.0;
  static const double s70 = 70.0;
  static const double s110 = 110.0;

  static const double expandedHeight = 240.0;
  static const double collapsedHeight = 80.0;
}

abstract class AppSizeBase {
  double get s1;
  double get s2;
  double get s3;
  double get s4;
  double get s5;
  double get s6;
  double get s7;
  double get s8;
  double get s9;
  double get s10;
  double get s12;
  double get s14;
  double get s16;
  double get s18;
  double get s20;
  double get s24;
  double get s32;
  double get s40;
  double get s50;
  double get s60;
  double get s70;
  double get s80;
  double get s85;
  double get s90;
  double get s100;
  double get s230;
}

class AppSizeVertical extends AppSizeBase {
  AppSizeVertical._();
  static final AppSizeVertical instance = AppSizeVertical._();

  @override double get s1   => 1;
  @override double get s2   => 2;
  @override double get s3   => 3;
  @override double get s4   => 4;
  @override double get s5   => 5;
  @override double get s6   => 6;
  @override double get s7   => 7;
  @override double get s8   => 8;
  @override double get s9   => 9;
  @override double get s10  => 10;
  @override double get s12  => 12;
  @override double get s14  => 14;
  @override double get s16  => 16;
  @override double get s18  => 18;
  @override double get s20  => 20;
  @override double get s24  => 24;
  @override double get s32  => 32;
  @override double get s40  => 40;
  @override double get s50  => 50;
  @override double get s60  => 60;
  @override double get s70  => 70;
  @override double get s80  => 80;
  @override double get s85  => 85;
  @override double get s90  => 90;
  @override double get s100 => 100;
  @override double get s230 => 230;
}

class AppSizeHorizontal extends AppSizeBase {
  AppSizeHorizontal._();
  static final AppSizeHorizontal instance = AppSizeHorizontal._();

  @override double get s1   => 1;
  @override double get s2   => 2;
  @override double get s3   => 3;
  @override double get s4   => 4;
  @override double get s5   => 5;
  @override double get s6   => 6;
  @override double get s7   => 7;
  @override double get s8   => 8;
  @override double get s9   => 9;
  @override double get s10  => 10;
  @override double get s12  => 12;
  @override double get s14  => 14;
  @override double get s16  => 16;
  @override double get s18  => 18;
  @override double get s20  => 20;
  @override double get s24  => 24;
  @override double get s32  => 32;
  @override double get s40  => 40;
  @override double get s50  => 50;
  @override double get s60  => 60;
  @override double get s70  => 70;
  @override double get s80  => 80;
  @override double get s85  => 85;
  @override double get s90  => 90;
  @override double get s100 => 100;
  @override double get s230 => 230;
}

class TextSizeApp extends AppSizeBase {
  TextSizeApp._();
  static final TextSizeApp instance = TextSizeApp._();

  @override double get s1   => 1;
  @override double get s2   => 2;
  @override double get s3   => 3;
  @override double get s4   => 4;
  @override double get s5   => 5;
  @override double get s6   => 6;
  @override double get s7   => 7;
  @override double get s8   => 8;
  @override double get s9   => 9;
  @override double get s10  => 10;
  @override double get s12  => 12;
  @override double get s14  => 14;
  @override double get s16  => 16;
  @override double get s18  => 18;
  @override double get s20  => 20;
  @override double get s24  => 24;
  @override double get s32  => 32;
  @override double get s40  => 40;
  @override double get s50  => 50;
  @override double get s60  => 60;
  @override double get s70  => 70;
  @override double get s80  => 80;
  @override double get s85  => 85;
  @override double get s90  => 90;
  @override double get s100 => 100;
  @override double get s230 => 230;
}