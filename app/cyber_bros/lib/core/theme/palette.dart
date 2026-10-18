import 'package:flutter/material.dart';

abstract final class Palette {
  // Backgrounds & Surfaces (Clean Slate / Tech White)
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);

  // Inks & Typography
  static const ink = Color(0xFF0F172A);
  static const inkMuted = Color(0xFF64748B);

  // Primaries (Electric Blue & Deep Tech Navy)
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E3A8A);
  static const primaryLight = Color(0xFFEFF6FF);

  // Accents
  static const accent = Color(0xFF0284C7);
  static const accentCyan = Color(0xFF06B6D4);

  // Semantics & Transport Indicators
  static const taxi = Color(0xFFEA580C);
  static const taxiBg = Color(0xFFFFF7ED);
  static const confirmed = Color(0xFF10B981);
  static const confirmedBg = Color(0xFFECFDF5);
  static const estimated = Color(0xFFD97706);
  static const estimatedBg = Color(0xFFFFFBEB);
  static const inferred = Color(0xFF7C3AED);
  static const inferredBg = Color(0xFFF5F3FF);
  static const simulatedBg = Color(0xFFF1F5F9);
}
