import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seeds the database with real expense data on first launch.
/// Only runs once — sets a flag in SharedPreferences.
class SeedData {
  static const _seededKey = 'db_seeded_v2'; // v2: real data

  static Future<void> seedIfNeeded(PaisaDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    await _seedTransactions(db);
    await _seedFamilyEntries(db);

    await prefs.setBool(_seededKey, true);
  }

  static Future<void> _seedTransactions(PaisaDatabase db) async {
    // Real expense data — March 30 to April 21, 2026
    final txns = <PaisaTransactionsCompanion>[
      // ── March 30 ──
      _t(2026, 3, 30, 9, 0, -64.06, 'transport', 'Uber', 'Auto'),
      _t(2026, 3, 30, 9, 30, -55.94, 'transport', 'Uber', 'Driver'),
      _t(2026, 3, 30, 13, 0, -222, 'food', 'Swiggy', 'Leons Paneer Biryani'),

      // ── March 31 ──
      _t(2026, 3, 31, 9, 0, -86, 'transport', 'Uber', 'Auto'),
      // Uber Bike Rs 0 — skipped
      _t(2026, 3, 31, 13, 0, -248, 'food', 'Zomato', 'Burrito Bowl Paneer'),

      // ── April 1 ──
      _t(2026, 4, 1, 9, 0, -56.55, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 1, 10, 0, -190, 'transport', 'Uber', 'Cab'),
      _t(2026, 4, 1, 20, 0, -8892, 'entertainment', 'Roast CCX', 'Birthday party'),

      // ── April 2 ──
      _t(2026, 4, 2, 9, 0, -54.5, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 2, 18, 0, -45.26, 'transport', 'Uber', 'Bike'),

      // ── April 3 ──
      _t(2026, 4, 3, 9, 0, -54.12, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 3, 14, 0, -328, 'other', 'District', 'Project Hail Mary'),

      // ── April 4 ──
      _t(2026, 4, 4, 8, 0, -51.2, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 4, 8, 30, -34.8, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 4, 13, 0, -200, 'food', 'Zomato', 'Burrito'),
      _t(2026, 4, 4, 10, 0, -19136, 'housing', 'Vasu', 'Rent'),
      _t(2026, 4, 4, 10, 30, -75, 'housing', 'Aryan', 'Maid'),
      _t(2026, 4, 4, 18, 0, -43, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 4, 11, 0, -15634, 'housing', 'Sai Dixit', 'Rent + electricity + Maid'),

      // ── April 5 ──
      _t(2026, 4, 5, 10, 0, -58000, 'housing', 'Owner', 'Rent'),
      _t(2026, 4, 5, 10, 30, -6461, 'housing', 'Maintenance', 'Rent'),
      _t(2026, 4, 5, 11, 0, -5284, 'housing', 'Electricity', 'House'),
      _t(2026, 4, 5, 13, 0, -314, 'food', 'Zomato', 'Lunch (7 Sisters)'),
      _t(2026, 4, 5, 20, 0, -155, 'food', 'Punch Kattu', 'Dinner'),

      // ── April 6 ──
      _t(2026, 4, 6, 11, 0, -267, 'other', 'Zepto', 'Washing soap and Harpic'),
      _t(2026, 4, 6, 10, 0, -3500, 'housing', 'Maid', 'Salary'),
      _t(2026, 4, 6, 9, 0, -70, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 6, 18, 0, -44, 'transport', 'Uber', 'Bike'),

      // ── April 7 ──
      _t(2026, 4, 7, 9, 0, -58.63, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 7, 18, 0, -34, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 7, 11, 0, -165, 'food', 'Grocery', 'Torai, Curd'),
      _t(2026, 4, 7, 15, 0, -50, 'food', 'Amul Ice Cream', 'Ice cream'),

      // ── April 8 ──
      _t(2026, 4, 8, 9, 0, -73, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 8, 13, 0, -256, 'food', 'Swiggy', 'Burrito'),

      // ── April 9 ──
      _t(2026, 4, 9, 9, 0, -67, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 9, 10, 0, -3500, 'other', 'Ram', 'Sent back'),
      _t(2026, 4, 9, 18, 0, -48, 'transport', 'Uber', 'Bike'),

      // ── April 10 ──
      _t(2026, 4, 10, 9, 0, -47, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 10, 18, 0, -46, 'transport', 'Uber', 'Bike'),

      // ── April 11 ──
      _t(2026, 4, 11, 9, 0, -207, 'transport', 'Co-karma', 'Auto'),
      _t(2026, 4, 11, 13, 0, -252, 'food', 'Zomato', 'Lunch'),
      _t(2026, 4, 11, 18, 0, -138, 'transport', 'Uber', 'Auto'),
      _t(2026, 4, 11, 18, 30, -48, 'transport', 'Uber', 'Bike'),

      // ── April 12 ──
      _t(2026, 4, 12, 20, 0, -195, 'food', 'Zomato', 'Dinner'),
      _t(2026, 4, 12, 21, 0, -302, 'food', 'Swiggy', 'Food'),

      // ── April 13 ──
      _t(2026, 4, 13, 9, 0, -77, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 13, 18, 0, -45, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 13, 22, 0, -130, 'other', 'Unknown', 'Not sure 10 pm'),

      // ── April 14 ──
      _t(2026, 4, 14, 10, 0, -355, 'other', 'Jio', 'Mobile Recharge'),
      _t(2026, 4, 14, 9, 0, -100, 'transport', 'Uber', 'Auto'),
      _t(2026, 4, 14, 18, 0, -46.44, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 14, 15, 0, -447, 'food', 'Blinkit', null),

      // ── April 15 ──
      _t(2026, 4, 15, 9, 0, -121, 'transport', 'Uber', 'Auto'),
      _t(2026, 4, 15, 14, 0, -236, 'other', 'Delhivery', 'Headphone Parcel'),
      _t(2026, 4, 15, 13, 0, -354, 'food', 'Zomato', "Ram's Food"),
      _t(2026, 4, 15, 18, 0, -65, 'transport', 'Uber', 'Bike'),

      // ── April 16 ──
      _t(2026, 4, 16, 9, 0, -102, 'transport', 'Uber', 'Auto'),
      _t(2026, 4, 16, 18, 0, -32, 'transport', 'Uber', 'Bike'),

      // ── April 17 ──
      _t(2026, 4, 17, 9, 0, -96, 'transport', 'Uber', 'Auto'),
      _t(2026, 4, 17, 18, 0, -44, 'transport', 'Uber', 'Bike'),

      // ── April 18 ──
      _t(2026, 4, 18, 9, 0, -48.73, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 18, 18, 0, -34, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 18, 12, 0, -590, 'entertainment', 'Flatmate Split', 'Vasu'),

      // ── April 19 ──
      _t(2026, 4, 19, 9, 0, -286, 'food', 'Swiggy Insta', 'Sunday Morning (Juice)'),
      _t(2026, 4, 19, 10, 0, -30, 'other', 'Toothbrush', 'Vasu'),
      _t(2026, 4, 19, 13, 0, -254, 'food', 'Swiggy', 'Lunch'),
      _t(2026, 4, 19, 20, 0, -419, 'food', 'Dominos', 'Dinner'),

      // ── April 20 ──
      _t(2026, 4, 20, 13, 0, -242.28, 'food', 'Zomato', 'Lunch'),
      _t(2026, 4, 20, 7, 0, -1800, 'entertainment', 'NMDC Marathon', 'Running 10K'),

      // ── April 21 ──
      _t(2026, 4, 21, 9, 0, -51.8, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 21, 18, 0, -43, 'transport', 'Uber', 'Bike'),
      _t(2026, 4, 21, 11, 0, -155, 'food', 'Grocery', 'Aloo + Banana + Curd'),
    ];

    for (final txn in txns) {
      await db.into(db.paisaTransactions).insert(txn);
    }
  }

  /// Helper to build a transaction companion.
  static PaisaTransactionsCompanion _t(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double amount,
    String category,
    String merchant,
    String? note,
  ) {
    return PaisaTransactionsCompanion.insert(
      amount: amount,
      category: category,
      merchant: Value(merchant),
      note: note != null ? Value(note) : const Value(null),
      happenedAt: Value(DateTime(year, month, day, hour, minute)),
      source: const Value('manual'),
      status: const Value('confirmed'),
    );
  }

  static Future<void> _seedFamilyEntries(PaisaDatabase db) async {
    final entries = <FamilyEntriesCompanion>[
      FamilyEntriesCompanion.insert(
        type: 'inflow',
        amount: 15000,
        fromPerson: 'Mom',
        note: const Value('Monthly pocket money'),
        happenedAt: Value(DateTime(2026, 4, 1)),
      ),
      FamilyEntriesCompanion.insert(
        type: 'inflow',
        amount: 25000,
        fromPerson: 'Dad',
        note: const Value('Rent help'),
        happenedAt: Value(DateTime(2026, 4, 5)),
      ),
      FamilyEntriesCompanion.insert(
        type: 'investment',
        amount: 50000,
        fromPerson: 'Dad',
        note: const Value('SIP - HDFC Flexi Cap'),
        investmentType: const Value('MF'),
        happenedAt: Value(DateTime(2026, 3, 15)),
      ),
      FamilyEntriesCompanion.insert(
        type: 'investment',
        amount: 25000,
        fromPerson: 'Self',
        note: const Value('Reliance shares'),
        investmentType: const Value('stocks'),
        happenedAt: Value(DateTime(2026, 4, 10)),
      ),
    ];

    for (final entry in entries) {
      await db.into(db.familyEntries).insert(entry);
    }
  }
}
