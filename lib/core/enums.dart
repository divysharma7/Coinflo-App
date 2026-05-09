import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum TransactionCategory {
  foodAndDrink,
  transport,
  shopping,
  entertainment,
  streaming,
  gymFitness,
  productivityTools,
  personalCare,
  education;

  String get label {
    switch (this) {
      case foodAndDrink:
        return 'Food & Drink';
      case transport:
        return 'Transport';
      case shopping:
        return 'Shopping';
      case entertainment:
        return 'Entertainment';
      case streaming:
        return 'Streaming';
      case gymFitness:
        return 'Gym & Fitness';
      case productivityTools:
        return 'Productivity';
      case personalCare:
        return 'Personal Care';
      case education:
        return 'Education';
    }
  }

  /// Regular weight — for lists, unselected states.
  IconData get icon {
    switch (this) {
      case foodAndDrink:
        return PhosphorIcons.bowlFood();
      case transport:
        return PhosphorIcons.car();
      case shopping:
        return PhosphorIcons.shoppingBag();
      case entertainment:
        return PhosphorIcons.filmStrip();
      case streaming:
        return PhosphorIcons.play();
      case gymFitness:
        return PhosphorIcons.barbell();
      case productivityTools:
        return PhosphorIcons.wrench();
      case personalCare:
        return PhosphorIcons.sparkle();
      case education:
        return PhosphorIcons.graduationCap();
    }
  }

  /// Fill weight — for selected states, category avatars.
  IconData get iconFill {
    switch (this) {
      case foodAndDrink:
        return PhosphorIconsFill.bowlFood;
      case transport:
        return PhosphorIconsFill.car;
      case shopping:
        return PhosphorIconsFill.shoppingBag;
      case entertainment:
        return PhosphorIconsFill.filmStrip;
      case streaming:
        return PhosphorIconsFill.play;
      case gymFitness:
        return PhosphorIconsFill.barbell;
      case productivityTools:
        return PhosphorIconsFill.wrench;
      case personalCare:
        return PhosphorIconsFill.sparkle;
      case education:
        return PhosphorIconsFill.graduationCap;
    }
  }
}

enum TransactionSource { smsAuto, manual }

enum TransactionStatus { unconfirmed, confirmed }

enum LedgerType { personal, family }

enum FamilyEntryType { inflow, investment }

enum InvestmentType { mf, stocks, fd, other }
