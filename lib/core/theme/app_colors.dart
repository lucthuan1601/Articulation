import 'package:flutter/material.dart';

/// Bảng màu chính của ứng dụng Articulation
/// Sử dụng color palette: neon purple + cyan trên nền trắng/xám nhạt
class AppColors {
  AppColors._();

  // ── Primary Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);        // Vivid Purple
  static const Color primaryLight = Color(0xFFA78BFA);    // Light Purple
  static const Color primaryDark = Color(0xFF5B21B6);     // Dark Purple
  static const Color primarySurface = Color(0xFFF5F3FF);  // Very Light Purple

  // ── Secondary / Accent Colors ───────────────────────────────────
  static const Color secondary = Color(0xFF06B6D4);       // Cyan
  static const Color secondaryLight = Color(0xFF67E8F9);  // Light Cyan
  static const Color secondaryDark = Color(0xFF0891B2);   // Dark Cyan
  static const Color secondarySurface = Color(0xFFECFEFF); // Very Light Cyan

  // ── Semantic Colors ─────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);         // Green - Phát âm đúng
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);           // Red - Phát âm sai
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);         // Amber - Cần cải thiện
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);            // Blue - Thông tin

  // ── Neutral Colors ──────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);      // Nền chính
  static const Color surface = Color(0xFFFFFFFF);          // Card/Surface
  static const Color surfaceVariant = Color(0xFFF1F5F9);   // Surface phụ
  static const Color border = Color(0xFFE2E8F0);           // Viền
  static const Color divider = Color(0xFFE2E8F0);

  // ── Text Colors ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);      // Text chính
  static const Color textSecondary = Color(0xFF64748B);    // Text phụ
  static const Color textHint = Color(0xFF94A3B8);         // Placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF);    // Text trên nền primary
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Streak / Gamification Colors ────────────────────────────────
  static const Color streakFlame = Color(0xFFFF6B35);      // Màu lửa streak
  static const Color streakGold = Color(0xFFFBBF24);       // Vàng gold
  static const Color streakBronze = Color(0xFFCD7F32);     // Đồng

  // ── Gradient Presets ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [streakFlame, streakGold],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Heatmap Colors (Calendar) ───────────────────────────────────
  static const List<Color> heatmapLevels = [
    Color(0xFFEDE9FE), // Level 0 - Không học
    Color(0xFFC4B5FD), // Level 1 - Ít
    Color(0xFFA78BFA), // Level 2 - Vừa
    Color(0xFF8B5CF6), // Level 3 - Nhiều
    Color(0xFF7C3AED), // Level 4 - Rất nhiều
  ];
}
