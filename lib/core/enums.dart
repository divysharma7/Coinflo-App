import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum TransactionCategory {
  foodAndDrink,
  transport,
  shopping,
  billsAndUtilities,
  healthAndWellness,
  entertainment,
  personalCare,
  education,
  travel,
  income,
  cash,
  investments,
  insurance,
  other,
  settlement,

  // Legacy subcategory values kept for backward compatibility.
  streaming,
  gymFitness,
  productivityTools;

  /// Maps subcategory values to their parent group.
  TransactionCategory get group {
    switch (this) {
      case streaming:
        return entertainment;
      case gymFitness:
        return healthAndWellness;
      case productivityTools:
        return education;
      default:
        return this;
    }
  }

  /// The 14 top-level category groups (excludes legacy subcategories).
  static List<TransactionCategory> get groups => [
        foodAndDrink,
        transport,
        shopping,
        billsAndUtilities,
        healthAndWellness,
        entertainment,
        personalCare,
        education,
        travel,
        income,
        cash,
        investments,
        insurance,
        other,
        settlement,
      ];

  /// Categories available for manual expense/income entry (excludes settlement).
  static List<TransactionCategory> get pickableGroups =>
      groups.where((c) => c != settlement).toList();

  String get label {
    switch (this) {
      case foodAndDrink:
        return 'Food & Drink';
      case transport:
        return 'Transport';
      case shopping:
        return 'Shopping';
      case billsAndUtilities:
        return 'Bills & Utilities';
      case healthAndWellness:
        return 'Health & Wellness';
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
      case travel:
        return 'Travel';
      case income:
        return 'Income';
      case cash:
        return 'Cash';
      case investments:
        return 'Investments';
      case insurance:
        return 'Insurance';
      case other:
        return 'Other';
      case settlement:
        return 'Settlement';
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
        return PhosphorIcons.shoppingCart();
      case billsAndUtilities:
        return PhosphorIcons.house();
      case healthAndWellness:
        return PhosphorIcons.heartbeat();
      case entertainment:
        return PhosphorIcons.filmSlate();
      case streaming:
        return PhosphorIcons.play();
      case gymFitness:
        return PhosphorIcons.barbell();
      case productivityTools:
        return PhosphorIcons.wrench();
      case personalCare:
        return PhosphorIcons.heart();
      case education:
        return PhosphorIcons.graduationCap();
      case travel:
        return PhosphorIcons.airplane();
      case income:
        return PhosphorIcons.trendUp();
      case cash:
        return PhosphorIcons.wallet();
      case investments:
        return PhosphorIcons.chartLineUp();
      case insurance:
        return PhosphorIcons.shieldCheck();
      case other:
        return PhosphorIcons.dotsThreeCircle();
      case settlement:
        return PhosphorIcons.handshake();
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
        return PhosphorIconsFill.shoppingCart;
      case billsAndUtilities:
        return PhosphorIconsFill.house;
      case healthAndWellness:
        return PhosphorIconsFill.heartbeat;
      case entertainment:
        return PhosphorIconsFill.filmSlate;
      case streaming:
        return PhosphorIconsFill.play;
      case gymFitness:
        return PhosphorIconsFill.barbell;
      case productivityTools:
        return PhosphorIconsFill.wrench;
      case personalCare:
        return PhosphorIconsFill.heart;
      case education:
        return PhosphorIconsFill.graduationCap;
      case travel:
        return PhosphorIconsFill.airplane;
      case income:
        return PhosphorIconsFill.trendUp;
      case cash:
        return PhosphorIconsFill.wallet;
      case investments:
        return PhosphorIconsFill.chartLineUp;
      case insurance:
        return PhosphorIconsFill.shieldCheck;
      case other:
        return PhosphorIconsFill.dotsThreeCircle;
      case settlement:
        return PhosphorIconsFill.handshake;
    }
  }
}


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

enum Currency {
  inr;

  String get symbol => '₹';
  String get label => 'Indian Rupee';
  String get code => 'INR';
}

enum AccountType {
  cash,
  bank,
  creditCard,
  digitalWallet;

  String get label {
    switch (this) {
      case cash:
        return 'Cash';
      case bank:
        return 'Bank';
      case creditCard:
        return 'Credit Card';
      case digitalWallet:
        return 'Digital Wallet';
    }
  }

  IconData get icon {
    switch (this) {
      case cash:
        return PhosphorIcons.currencyDollar();
      case bank:
        return PhosphorIcons.bank();
      case creditCard:
        return PhosphorIcons.creditCard();
      case digitalWallet:
        return PhosphorIcons.deviceMobile();
    }
  }
}

class Subcategory {
  final String name;
  final TransactionCategory group;
  final IconData icon;

  const Subcategory({
    required this.name,
    required this.group,
    required this.icon,
  });

  static const List<Subcategory> all = [
    // Food & Drink
    Subcategory(
      name: 'Groceries',
      group: TransactionCategory.foodAndDrink,
      icon: PhosphorIconsRegular.shoppingCart,
    ),
    Subcategory(
      name: 'Restaurants',
      group: TransactionCategory.foodAndDrink,
      icon: PhosphorIconsRegular.forkKnife,
    ),
    Subcategory(
      name: 'Coffee & Cafes',
      group: TransactionCategory.foodAndDrink,
      icon: PhosphorIconsRegular.coffee,
    ),
    Subcategory(
      name: 'Takeaway & Delivery',
      group: TransactionCategory.foodAndDrink,
      icon: PhosphorIconsRegular.package,
    ),
    Subcategory(
      name: 'Alcohol & Bars',
      group: TransactionCategory.foodAndDrink,
      icon: PhosphorIconsRegular.beerStein,
    ),

    // Transport
    Subcategory(
      name: 'Fuel',
      group: TransactionCategory.transport,
      icon: PhosphorIconsRegular.gasPump,
    ),
    Subcategory(
      name: 'Public Transport',
      group: TransactionCategory.transport,
      icon: PhosphorIconsRegular.train,
    ),
    Subcategory(
      name: 'Taxi & Ride Share',
      group: TransactionCategory.transport,
      icon: PhosphorIconsRegular.taxi,
    ),
    Subcategory(
      name: 'Parking',
      group: TransactionCategory.transport,
      icon: PhosphorIconsRegular.car,
    ),
    Subcategory(
      name: 'Car Maintenance',
      group: TransactionCategory.transport,
      icon: PhosphorIconsRegular.wrench,
    ),

    // Shopping
    Subcategory(
      name: 'Clothing & Fashion',
      group: TransactionCategory.shopping,
      icon: PhosphorIconsRegular.tShirt,
    ),
    Subcategory(
      name: 'Electronics',
      group: TransactionCategory.shopping,
      icon: PhosphorIconsRegular.laptop,
    ),
    Subcategory(
      name: 'Home & Furniture',
      group: TransactionCategory.shopping,
      icon: PhosphorIconsRegular.armchair,
    ),
    Subcategory(
      name: 'Books & Stationery',
      group: TransactionCategory.shopping,
      icon: PhosphorIconsRegular.book,
    ),
    Subcategory(
      name: 'Gifts & Donations',
      group: TransactionCategory.shopping,
      icon: PhosphorIconsRegular.gift,
    ),

    // Bills & Utilities
    Subcategory(
      name: 'Rent & Mortgage',
      group: TransactionCategory.billsAndUtilities,
      icon: PhosphorIconsRegular.house,
    ),
    Subcategory(
      name: 'Electricity & Gas',
      group: TransactionCategory.billsAndUtilities,
      icon: PhosphorIconsRegular.lightning,
    ),
    Subcategory(
      name: 'Internet & Phone',
      group: TransactionCategory.billsAndUtilities,
      icon: PhosphorIconsRegular.wifiHigh,
    ),
    Subcategory(
      name: 'Water',
      group: TransactionCategory.billsAndUtilities,
      icon: PhosphorIconsRegular.drop,
    ),
    Subcategory(
      name: 'Insurance',
      group: TransactionCategory.billsAndUtilities,
      icon: PhosphorIconsRegular.shield,
    ),

    // Health & Wellness
    Subcategory(
      name: 'Gym & Fitness',
      group: TransactionCategory.healthAndWellness,
      icon: PhosphorIconsRegular.barbell,
    ),
    Subcategory(
      name: 'Doctor & Medical',
      group: TransactionCategory.healthAndWellness,
      icon: PhosphorIconsRegular.heartbeat,
    ),
    Subcategory(
      name: 'Pharmacy',
      group: TransactionCategory.healthAndWellness,
      icon: PhosphorIconsRegular.pill,
    ),
    Subcategory(
      name: 'Mental Health',
      group: TransactionCategory.healthAndWellness,
      icon: PhosphorIconsRegular.brain,
    ),

    // Entertainment
    Subcategory(
      name: 'Movies & Cinema',
      group: TransactionCategory.entertainment,
      icon: PhosphorIconsRegular.filmSlate,
    ),
    Subcategory(
      name: 'Streaming Services',
      group: TransactionCategory.entertainment,
      icon: PhosphorIconsRegular.play,
    ),
    Subcategory(
      name: 'Games & Apps',
      group: TransactionCategory.entertainment,
      icon: PhosphorIconsRegular.gameController,
    ),
    Subcategory(
      name: 'Hobbies & Sports',
      group: TransactionCategory.entertainment,
      icon: PhosphorIconsRegular.soccerBall,
    ),

    // Personal Care
    Subcategory(
      name: 'Haircut & Salon',
      group: TransactionCategory.personalCare,
      icon: PhosphorIconsRegular.scissors,
    ),
    Subcategory(
      name: 'Skincare & Beauty',
      group: TransactionCategory.personalCare,
      icon: PhosphorIconsRegular.sparkle,
    ),
    Subcategory(
      name: 'Spa & Wellness',
      group: TransactionCategory.personalCare,
      icon: PhosphorIconsRegular.flower,
    ),

    // Education
    Subcategory(
      name: 'Courses & Training',
      group: TransactionCategory.education,
      icon: PhosphorIconsRegular.graduationCap,
    ),
    Subcategory(
      name: 'Tuition & School',
      group: TransactionCategory.education,
      icon: PhosphorIconsRegular.bookOpen,
    ),
    Subcategory(
      name: 'Kids & Childcare',
      group: TransactionCategory.education,
      icon: PhosphorIconsRegular.baby,
    ),
    Subcategory(
      name: 'Productivity Tools',
      group: TransactionCategory.education,
      icon: PhosphorIconsRegular.wrench,
    ),

    // Travel
    Subcategory(
      name: 'Flights',
      group: TransactionCategory.travel,
      icon: PhosphorIconsRegular.airplaneTakeoff,
    ),
    Subcategory(
      name: 'Hotels & Stays',
      group: TransactionCategory.travel,
      icon: PhosphorIconsRegular.buildings,
    ),
    Subcategory(
      name: 'Activities & Tours',
      group: TransactionCategory.travel,
      icon: PhosphorIconsRegular.mapTrifold,
    ),
    Subcategory(
      name: 'Travel Essentials',
      group: TransactionCategory.travel,
      icon: PhosphorIconsRegular.suitcase,
    ),

    // Other
    Subcategory(
      name: 'Pets',
      group: TransactionCategory.other,
      icon: PhosphorIconsRegular.dog,
    ),
    Subcategory(
      name: 'Miscellaneous',
      group: TransactionCategory.other,
      icon: PhosphorIconsRegular.dotsThreeCircle,
    ),
  ];

  /// Returns the subcategories belonging to the given [group].
  static List<Subcategory> forGroup(TransactionCategory group) =>
      all.where((s) => s.group == group).toList();
}

// ─── Categorization Enums ────────────────────────────────

enum MappingSource {
  userCorrected,
  shippedDictionary,
  rule,
  smartRule,
  ml;

  String get label {
    switch (this) {
      case userCorrected:
        return 'User Corrected';
      case shippedDictionary:
        return 'Dictionary';
      case rule:
        return 'Rule';
      case smartRule:
        return 'Smart Rule';
      case ml:
        return 'ML';
    }
  }
}

enum CategorizationSource {
  user,
  smartRule,
  dictionary,
  rule,
  upi,
  ml,
  uncategorized;

  String get label {
    switch (this) {
      case user:
        return 'User';
      case smartRule:
        return 'Smart Rule';
      case dictionary:
        return 'Dictionary';
      case rule:
        return 'Rule';
      case upi:
        return 'UPI';
      case ml:
        return 'ML';
      case uncategorized:
        return 'Uncategorized';
    }
  }
}

enum BankType {
  hdfc,
  icici,
  sbi,
  axis,
  kotak,
  unknown;

  String get label {
    switch (this) {
      case hdfc:
        return 'HDFC Bank';
      case icici:
        return 'ICICI Bank';
      case sbi:
        return 'State Bank of India';
      case axis:
        return 'Axis Bank';
      case kotak:
        return 'Kotak Mahindra Bank';
      case unknown:
        return 'Other Bank';
    }
  }

  String get shortLabel {
    switch (this) {
      case hdfc:
        return 'HDFC';
      case icici:
        return 'ICICI';
      case sbi:
        return 'SBI';
      case axis:
        return 'Axis';
      case kotak:
        return 'Kotak';
      case unknown:
        return 'Other';
    }
  }
}

