import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'banknote_entry.dart';

class BanknoteStore {
  static const String boxName = 'banknotes';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  static List<BanknoteEntry> getByCountry(String countryCode) {
    final all = _box.values.toList().cast<Map>();
    return all
        .map((m) => BanknoteEntry.fromMap(m))
        .where((e) => e.countryCode == countryCode)
        .toList();
  }

  static BanknoteEntry? getById(String id) {
    final all = _box.values.toList().cast<Map>();
    for (final m in all) {
      final e = BanknoteEntry.fromMap(m);
      if (e.id == id) return e;
    }
    return null;
  }

  static Future<void> add(BanknoteEntry entry) async {
    await _box.add(entry.toMap());
  }

  static Future<void> update(BanknoteEntry entry) async { // New: Updates an existing entry by ID
    final keys = _box.keys.toList();
    final vals = _box.values.toList().cast<Map>();

    for (int i = 0; i < vals.length; i++) {
      final m = vals[i];
      if (m['id'] == entry.id) {
        // Use put to replace the existing entry at the specific key
        await _box.put(keys[i], entry.toMap());
        return;
      }
    }
  }

  static Future<void> delete(String id) async {
    final keys = _box.keys.toList();
    final vals = _box.values.toList().cast<Map>();

    for (int i = 0; i < vals.length; i++) {
      final m = vals[i];
      if (m['id'] == id) {
        // Attempt to delete the image file first
        try {
          if (m['imagePath'] != null && (m['imagePath'] as String).isNotEmpty) {
            await File(m['imagePath']).delete();
          }
        } catch (e) {
          // Log error but proceed with Hive deletion
          // use debugPrint to avoid lint warnings
          debugPrint('Error deleting image file: $e');
        }
        await _box.delete(keys[i]);
        return;
      }
    }
  }
  
  static Set<String> getCollectedCountryCodes() {
    final all = _box.values.toList().cast<Map>();
    return all
        .map((m) => BanknoteEntry.fromMap(m).countryCode)
        .toSet();
  }
}