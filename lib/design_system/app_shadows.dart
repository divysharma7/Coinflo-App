import 'package:flutter/material.dart';

/// Layered, soft elevation system from the CoinFlo Hi-Fi pass.
/// Each level stacks a tight contact shadow with a wider ambient one.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A0A0A0A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D0A0A0A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0A0A0A0A), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x120A0A0A), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x0F0A0A0A), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A0A0A0A), blurRadius: 48, offset: Offset(0, 24)),
  ];

  /// Deep elevation for the near-black hero cards.
  static const List<BoxShadow> hero = [
    BoxShadow(color: Color(0x2E0A0A0A), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x470A0A0A), blurRadius: 64, offset: Offset(0, 32)),
  ];
}
