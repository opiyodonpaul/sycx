import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: AppColors.primaryButtonColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryButtonColor,
        secondary: AppColors.secondaryButtonColor,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingStyleNoShadow
            .copyWith(color: AppColors.primaryTextColorDark),
        bodyLarge: AppTextStyles.bodyTextStyle
            .copyWith(color: AppColors.primaryTextColorDark),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: AppColors.primaryButtonColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryButtonColor,
        secondary: AppColors.secondaryButtonColor,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingStyleNoShadow,
        bodyLarge: AppTextStyles.bodyTextStyle,
      ),
    );
  }
}
