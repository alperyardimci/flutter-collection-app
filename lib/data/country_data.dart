import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Represents a country's display information and metadata
class CountryData {
  final String isoCode;
  final String name;
  final String region;

  const CountryData({
    required this.isoCode,
    required this.name,
    required this.region,
  });

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      isoCode: (json['isoCode'] as String).toUpperCase(),
      name: json['name'] as String,
      region: json['region'] as String,
    );
  }
}

/// Global mapping of country data. This will be populated from the
/// bundled `assets/countries.json` at app startup. A small fallback
/// set is provided so synchronous callers still work if `load()` hasn't
/// completed yet.
class Countries {
  static Map<String, CountryData> all = {
    'US': CountryData(isoCode: 'US', name: 'United States', region: 'North America'),
    'GB': CountryData(isoCode: 'GB', name: 'United Kingdom', region: 'Europe'),
    'DE': CountryData(isoCode: 'DE', name: 'Germany', region: 'Europe'),
    'FR': CountryData(isoCode: 'FR', name: 'France', region: 'Europe'),
    'CN': CountryData(isoCode: 'CN', name: 'China', region: 'Asia'),
    'IN': CountryData(isoCode: 'IN', name: 'India', region: 'Asia'),
    'BR': CountryData(isoCode: 'BR', name: 'Brazil', region: 'South America'),
  };

  /// Loads the full country list from `assets/countries.json` and
  /// replaces the in-memory map. Call this during app startup (before
  /// runApp) to ensure the complete dataset is available.
  static Future<void> loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/countries.json');
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      final Map<String, CountryData> map = {};
      for (final item in list) {
        final cd = CountryData.fromJson(item as Map<String, dynamic>);
        map[cd.isoCode] = cd;
      }
      all = map;
    } catch (e) {
      // If loading fails, keep the small fallback map and log the error.
      // The app will continue to function.
      // Use debugPrint to avoid lint warnings
      // ignore: avoid_print
      debugPrint('Failed to load countries.json: $e');
    }
  }

  /// Get a country's display name from its ISO code
  static String nameForCode(String code) {
    return all[code.toUpperCase()]?.name ?? code;
  }

  /// Get a country's region from its ISO code
  static String? regionForCode(String code) {
    return all[code.toUpperCase()]?.region;
  }

  /// Get all countries in a specific region
  static List<CountryData> inRegion(String region) {
    return all.values.where((c) => c.region == region).toList();
  }
}