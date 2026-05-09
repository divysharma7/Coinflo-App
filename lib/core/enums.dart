import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum TransactionCategory {
  rent,
  transport,
  food,
  family,
  social,
  other;

  String get label {
    switch (this) {
      case rent:
        return 'Rent';
      case transport:
        return 'Transport';
      case food:
        return 'Food';
      case family:
        return 'Family';
      case social:
        return 'Social';
      case other:
        return 'Other';
    }
  }

  /// Regular weight — for lists, unselected states.
  IconData get icon {
    switch (this) {
      case rent:
        return PhosphorIcons.house();
      case transport:
        return PhosphorIcons.car();
      case food:
        return PhosphorIcons.bowlFood();
      case family:
        return PhosphorIcons.heartbeat();
      case social:
        return PhosphorIcons.usersThree();
      case other:
        return PhosphorIcons.dotsThreeCircle();
    }
  }

  /// Fill weight — for selected states, category avatars.
  IconData get iconFill {
    switch (this) {
      case rent:
        return PhosphorIconsFill.house;
      case transport:
        return PhosphorIconsFill.car;
      case food:
        return PhosphorIconsFill.bowlFood;
      case family:
        return PhosphorIconsFill.heartbeat;
      case social:
        return PhosphorIconsFill.usersThree;
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
