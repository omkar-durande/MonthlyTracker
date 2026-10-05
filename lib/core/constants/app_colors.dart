import 'package:flutter/material.dart';

/// Central color palette for MonthlyGoals.
/// Uses a deep violet-indigo gradient with warm amber accents.
class AppColors {
  AppColors._();

  // --- Brand ---
  static const Color primary = Color(0xFF6366F1);       // Indigo-500
  static const Color primaryDark = Color(0xFF4F46E5);   // Indigo-600
  static const Color primaryLight = Color(0xFF818CF8);  // Indigo-400
  static const Color secondary = Color(0xFFF59E0B);     // Amber-500
  static const Color accent = Color(0xFF06B6D4);        // Cyan-500

  // --- Semantic ---
  static const Color success = Color(0xFF10B981);   // Emerald-500
  static const Color warning = Color(0xFFF59E0B);   // Amber-500
  static const Color error = Color(0xFFEF4444);     // Red-500
  static const Color info = Color(0xFF3B82F6);      // Blue-500

  // --- Priority ---
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);

  // --- Status ---
  static const Color statusPending = Color(0xFF94A3B8);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF10B981);

  // --- Light theme surfaces ---
  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color onSurfaceLight = Color(0xFF1E293B);
  static const Color subtleLight = Color(0xFF64748B);

  // --- Dark theme surfaces ---
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceVariantDark = Color(0xFF16213E);
  static const Color onSurfaceDark = Color(0xFFE2E8F0);
  static const Color subtleDark = Color(0xFF94A3B8);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Goal color palette ---
  static const List<String> goalColors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#F59E0B',
    '#10B981', '#3B82F6', '#06B6D4', '#EF4444',
    '#84CC16', '#F97316',
  ];

  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
