import 'dart:io';

import 'package:flutter/material.dart';
import '../data/banknote_store.dart';
import '../data/country_data.dart';
import 'country_detail_screen.dart';

/// Home screen showing countries grouped by continent as circular flag badges.
class WorldMapScreen extends StatefulWidget {
  static const routeName = '/';

  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  Map<String, List<CountryData>> _grouped = {};
  Map<String, bool> _hasImage = {};
  Map<String, int> _imageCounts = {};
  Map<String, int> _monoCounts = {};

  // Simple color mapping for continents/regions
  static const Map<String, Color> _regionColors = {
    'Africa': Color(0xFFF57C00), // orange
    'Asia': Color(0xFF1976D2), // blue
    'Europe': Color(0xFF388E3C), // green
    'North America': Color(0xFF7B1FA2), // purple
    'South America': Color(0xFFD32F2F), // red
    'Oceania': Color(0xFF0288D1), // light blue
    'Antarctica': Color(0xFF90A4AE), // gray
    'Europe/Asia': Color(0xFF5D4037), // brown
  };

  @override
  void initState() {
    super.initState();
    _groupCountries();
  }

  void _groupCountries() {
    final map = <String, List<CountryData>>{};
    for (final c in Countries.all.values) {
      final region = c.region;
      map.putIfAbsent(region, () => []).add(c);
    }

    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {
      _grouped = map;
    });
    _computeHasImages();
  }

  void _computeHasImages() {
    final Map<String, bool> hasMap = {};
    final Map<String, int> countMap = {};

    for (final c in Countries.all.values) {
      final list = BanknoteStore.getByCountry(c.isoCode);
      int cnt = 0;
      for (final e in list) {
        if (e.imagePath.isNotEmpty) {
          try {
            if (File(e.imagePath).existsSync()) {
              cnt++;
            }
          } catch (_) {
            // ignore IO errors
          }
        }
      }
      hasMap[c.isoCode] = cnt > 0;
      countMap[c.isoCode] = cnt;
    }

    setState(() {
      _hasImage = hasMap;
      _imageCounts = countMap;
    });
    _computeMonoCounts();
  }

  void _computeMonoCounts() {
    final Map<String, int> m = {};
    for (final entry in _grouped.entries) {
      final region = entry.key;
      final countries = entry.value;
      int cnt = 0;
      for (final c in countries) {
        final num = _imageCounts[c.isoCode] ?? 0;
        if (num == 0) cnt++;
      }
      m[region] = cnt;
    }

    setState(() {
      _monoCounts = m;
    });
  }

  String _flagEmoji(String iso) {
    if (iso.length != 2) return iso;
    final up = iso.toUpperCase();
    final int base = 0x1F1E6;
    final codeUnits = up.codeUnits;
    final first = String.fromCharCode(base + (codeUnits[0] - 65));
    final second = String.fromCharCode(base + (codeUnits[1] - 65));
    return '$first$second';
  }

  void _openCountry(CountryData c) {
    Navigator.pushNamed(
      context,
      CountryDetailScreen.routeName,
      arguments: CountryDetailArgs(
        countryCode: c.isoCode,
        countryName: c.name,
      ),
    ).then((result) {
      // Recompute image presence/counts after returning from country details
      // (e.g., when a banknote was added/edited). _computeHasImages calls setState.
      _computeHasImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final regions = _grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countries by Continent'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: regions.length,
        itemBuilder: (ctx, idx) {
          final region = regions[idx];
          final countries = _grouped[region]!;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _regionColors[region] ?? Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text(
                        region.isNotEmpty ? region[0] : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(region, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          '${_monoCounts[region] ?? 0}/${countries.length}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final width = constraints.maxWidth;
                      final int columns = width < 420 ? 3 : (width < 720 ? 4 : 6);
                      final double aspect = columns <= 3 ? 0.9 : 0.72;

                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: aspect,
                        children: countries.map((c) {
                          final hasImage = _hasImage[c.isoCode] ?? false;
                          final imageCount = _imageCounts[c.isoCode] ?? 0;

                          return InkWell(
                            onTap: () => _openCountry(c),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // flag with corner badge
                                  Center(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Material(
                                          elevation: 2,
                                          shape: const CircleBorder(),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.white,
                                            child: hasImage
                                                ? Text(_flagEmoji(c.isoCode), style: const TextStyle(fontSize: 16))
                                                : ColorFiltered(
                                                    colorFilter: const ColorFilter.matrix([
                                                      0.2126, 0.7152, 0.0722, 0, 0,
                                                      0.2126, 0.7152, 0.0722, 0, 0,
                                                      0.2126, 0.7152, 0.0722, 0, 0,
                                                      0, 0, 0, 1, 0,
                                                    ]),
                                                    child: Text(_flagEmoji(c.isoCode), style: const TextStyle(fontSize: 16)),
                                                  ),
                                          ),
                                        ),
                                        // badge on top-right
                                        Positioned(
                                          right: -6,
                                          top: -6,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: imageCount > 0 ? Colors.redAccent : Colors.grey[300],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                imageCount > 99 ? '9+' : imageCount.toString(),
                                                style: TextStyle(color: imageCount > 0 ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // name under the flag
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      c.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

