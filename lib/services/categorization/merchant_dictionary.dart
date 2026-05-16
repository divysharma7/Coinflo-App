import 'dart:convert';

import 'package:flutter/services.dart';

/// Entry in the shipped merchant dictionary.
class MerchantEntry {
  final String token;
  final String category;
  final double confidence;
  final List<String> aliases;

  const MerchantEntry({
    required this.token,
    required this.category,
    required this.confidence,
    this.aliases = const [],
  });

  factory MerchantEntry.fromJson(Map<String, dynamic> json) {
    return MerchantEntry(
      token: json['token'] as String,
      category: json['category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Loads and serves the shipped Indian merchant dictionary from
/// assets/data/indian_merchants.json.
///
/// Designed to be loaded once and cached in memory. Safe for isolate use
/// when pre-loaded data is passed in as a Map.
class MerchantDictionary {
  /// Exact token → entry map.
  final Map<String, MerchantEntry> _exactMap = {};

  /// All entries for contains-based fallback matching.
  final List<MerchantEntry> _allEntries = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load dictionary from the bundled JSON asset.
  /// Call once at app startup. Safe to call multiple times (no-op if loaded).
  Future<void> load() async {
    if (_loaded) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/indian_merchants.json');
      loadFromString(jsonStr);
    } on Exception {
      // Gracefully handle missing file — dictionary is empty, cascade continues.
      _loaded = true;
    }
  }

  /// Load from a raw JSON string. Useful for testing and isolate pre-loading.
  void loadFromString(String jsonStr) {
    final list = json.decode(jsonStr) as List<dynamic>;
    for (final item in list) {
      final entry = MerchantEntry.fromJson(item as Map<String, dynamic>);
      _exactMap[entry.token] = entry;
      for (final alias in entry.aliases) {
        _exactMap[alias] = entry;
      }
      _allEntries.add(entry);
    }
    _loaded = true;
  }

  /// Load from pre-parsed data (for isolate use without rootBundle).
  void loadFromEntries(List<MerchantEntry> entries) {
    for (final entry in entries) {
      _exactMap[entry.token] = entry;
      for (final alias in entry.aliases) {
        _exactMap[alias] = entry;
      }
      _allEntries.add(entry);
    }
    _loaded = true;
  }

  /// Stage 2 lookup: exact match on merchantToken, then contains fallback.
  MerchantEntry? lookup(String merchantToken) {
    // Exact match.
    final exact = _exactMap[merchantToken];
    if (exact != null) return exact;

    // Contains fallback: check if any dictionary token is contained in the input.
    for (final entry in _allEntries) {
      if (merchantToken.contains(entry.token) && entry.token.length >= 3) {
        return entry;
      }
    }

    return null;
  }

  /// Export all entries for passing to an isolate.
  List<MerchantEntry> get allEntries => List.unmodifiable(_allEntries);
}
