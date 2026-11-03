import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';

/// Typography styles cho ứng dụng Articulation
/// Sử dụng Google Fonts (Inter cho body, Poppins cho heading)
class AppTextStyles {
  AppTextStyles._();

  // ── Headings ────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Labels ──────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    letterSpacing: 0.5,
  );

  // ── Special ─────────────────────────────────────────────────────
  /// Hiển thị điểm số lớn (VD: 85/100)
  static const TextStyle scoreDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -1,
  );

  /// Hiển thị streak count
  static const TextStyle streakCount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.streakFlame,
    letterSpacing: -0.5,
  );

  /// IPA phonetic text
  static const TextStyle ipaText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
    height: 1.6,
  );

  /// Từ phát âm đúng (xanh)
  static const TextStyle correctWord = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
    height: 1.5,
  );

  /// Từ phát âm sai (đỏ)
  static const TextStyle wrongWord = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.error,
    height: 1.5,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
