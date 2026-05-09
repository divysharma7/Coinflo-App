import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum TransactionCategory {
  housing,
  transport,
  food,
  shopping,
  entertainment,
  health,
  education,
  utilities,
  other;

  String get label {
    switch (this) {
      case housing:
        return 'Housing';
      case transport:
        return 'Transport';
      case food:
        return 'Food';
      case shopping:
        return 'Shopping';
      case entertainment:
        return 'Entertainment';
      case health:
        return 'Health';
      case education:
        return 'Education';
      case utilities:
        return 'Utilities';
      case other:
        return 'Other';
    }
  }

  /// Regular weight — for lists, unselected states.
  IconData get icon {
    switch (this) {
      case housing:
        return PhosphorIcons.house();
      case transport:
        return PhosphorIcons.car();
      case food:
        return PhosphorIcons.bowlFood();
      case shopping:
        return PhosphorIcons.shoppingCart();
      case entertainment:
        return PhosphorIcons.filmSlate();
      case health:
        return PhosphorIcons.heartbeat();
      case education:
        return PhosphorIcons.graduationCap();
      case utilities:
        return PhosphorIcons.lightning();
      case other:
        return PhosphorIcons.dotsThreeCircle();
    }
  }

  /// Fill weight — for selected states, category avatars.
  IconData get iconFill {
    switch (this) {
      case housing:
        return PhosphorIconsFill.house;
      case transport:
        return PhosphorIconsFill.car;
      case food:
        return PhosphorIconsFill.bowlFood;
      case shopping:
        return PhosphorIconsFill.shoppingCart;
      case entertainment:
        return PhosphorIconsFill.filmSlate;
      case health:
        return PhosphorIconsFill.heartbeat;
      case education:
        return PhosphorIconsFill.graduationCap;
      case utilities:
        return PhosphorIconsFill.lightning;
      case other:
        return PhosphorIconsFill.dotsThreeCircle;
    }
  }
}

enum TransactionSource { smsAuto, manual }

enum TransactionStatus { unconfirmed, confirmed }

enum LedgerType { personal, family }

enum FamilyEntryType { inflow, investment }

enum InvestmentType { mf, stocks, fd, other }

enum BillingCycle {
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case weekly:
        return 'Weekly';
      case monthly:
        return 'Monthly';
      case yearly:
        return 'Yearly';
    }
  }

  String get shortLabel {
    switch (this) {
      case weekly:
        return '/wk';
      case monthly:
        return '/mo';
      case yearly:
        return '/yr';
    }
  }
}
