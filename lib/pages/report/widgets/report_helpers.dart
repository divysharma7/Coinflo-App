import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

// ---------------------------------------------------------------------------
// Colors & helpers
// ---------------------------------------------------------------------------

String reportSym(String code) {
  switch (code.toLowerCase()) {
    case 'inr': return '\u20B9';
    case 'usd': return '\$';
    case 'eur': return '\u20AC';
    case 'gbp': return '\u00A3';
    default: return '\$';
  }
}

String reportFmt(double v) {
  if (v >= 100000) return NumberFormat('#,##,###', 'en_IN').format(v.toInt());
  return NumberFormat('#,###').format(v.toInt());
}

// ---------------------------------------------------------------------------
// Card decoration helper
// ---------------------------------------------------------------------------

BoxDecoration reportCardDecor() => const BoxDecoration(
      color: AppColors.white,
      borderRadius: AppRadius.lg,
      boxShadow: AppShadows.lg,
    );
