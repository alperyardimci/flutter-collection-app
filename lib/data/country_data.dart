import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Represents a country's display information and metadata
class CountryData {
  final String isoCode; // e.g. "US", "TR", "AF"
  final String name;    // e.g. "United States", "Türkiye", "Afghanistan"
  final String region;  // e.g. "North America", "Asia", "Europe", ...

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
/// set is provided so synchronous callers still work if `loadFromAsset()`
/// hasn't completed yet.
class Countries {
  static Map<String, CountryData> all = {
    'US': CountryData(
      isoCode: 'US',
      name: 'United States',
      region: 'North America',
    ),
    'GB': CountryData(
      isoCode: 'GB',
      name: 'United Kingdom',
      region: 'Europe',
    ),
    'DE': CountryData(
      isoCode: 'DE',
      name: 'Germany',
      region: 'Europe',
    ),
    'FR': CountryData(
      isoCode: 'FR',
      name: 'France',
      region: 'Europe',
    ),
    'CN': CountryData(
      isoCode: 'CN',
      name: 'China',
      region: 'Asia',
    ),
    'IN': CountryData(
      isoCode: 'IN',
      name: 'India',
      region: 'Asia',
    ),
    'BR': CountryData(
      isoCode: 'BR',
      name: 'Brazil',
      region: 'South America',
    ),
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
      debugPrint('Failed to load countries.json: $e');
    }
  }

  /// Get a country's display name from its ISO code.
  /// If not found, returns the code itself.
  static String nameForCode(String code) {
    return all[code.toUpperCase()]?.name ?? code;
  }

  /// Get a country's region from its ISO code.
  /// If not found, returns null.
  static String? regionForCode(String code) {
    return all[code.toUpperCase()]?.region;
  }

  /// Get all countries in a specific region (e.g. "Asia", "Europe").
  static List<CountryData> inRegion(String region) {
    return all.values.where((c) => c.region == region).toList();
  }

  /// --- NEW ---
  /// Get the flag asset path for a given country code.
  ///
  /// This is what both:
  ///  - AddBanknoteScreen (small flag next to dropdown/label)
  ///  - CountryDetailScreen (header circle, card chip, empty state)
  /// should call.
  ///
  /// Convention:
  ///   assets/flags/<ISO2>.png
  ///
  /// Example:
  ///   flagAssetForCode("AF") -> assets/flags/AF.png
  ///   flagAssetForCode("tr") -> assets/flags/TR.png
  ///
  /// If the flag image doesn't exist yet, you can add a placeholder
  /// like assets/flags/unknown.png and we'll fall back to that.
  static String flagAssetForCode(String code) {
    final upper = code.toUpperCase();
    return 'assets/flags/$upper.png';
  }
}
