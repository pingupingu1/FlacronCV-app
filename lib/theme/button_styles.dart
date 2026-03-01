import 'package:flutter/material.dart';
import 'colors.dart';

class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryOrange,
    foregroundColor: AppColors.textLight,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: 20,
    ),
  );
}
