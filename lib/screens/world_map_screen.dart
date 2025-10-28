import 'dart:io';
import 'package:flutter/material.dart';

import '../data/banknote_store.dart';
import '../data/country_data.dart';
import 'country_detail_screen.dart';

class WorldMapScreen extends StatefulWidget {
  static const routeName = '/';

  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // data
  Map<String, List<CountryData>> _grouped = {};
  Map<String, bool> _hasImage = {};
  Map<String, int> _imageCounts = {};
  Map<String, int> _monoCounts = {};

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // continent tint colors (main hue)
  static const Map<String, Color> _regionMainColor = {
    'Africa': Color(0xFFF57C00), // orange
    'Asia': Color(0xFF1976D2), // blue
    'Europe': Color(0xFF388E3C), // green
    'North America': Color(0xFF7B1FA2), // purple
    'South America': Color(0xFFD32F2F), // red
    'Oceania': Color(0xFF0288D1), // light blue
    'Antarctica': Color(0xFF90A4AE), // gray
    'Europe/Asia': Color(0xFF5D4037), // brown
  };

  // dark palette tokens for the whole page
  // You can centralize these later in ThemeData.
  final Color _bgColor = const Color(0xFF0B1220); // page background
  final Color _cardColor = const Color(0xFF1A2438); // cards/search surface
  final Color _borderColor = Colors.white24; // will apply with .withOpacity(0.05)
  final Color _textMain = Colors.white;
  final Color _textSub = Colors.white70;

  @override
  void initState() {
    super.initState();
    _groupCountries();

    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _groupCountries() {
    final map = <String, List<CountryData>>{};
    for (final c in Countries.all.values) {
      final region = c.region;
      map.putIfAbsent(region, () => []).add(c);
    }

    // sort countries in each region by name
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
    // monoCounts[region] = how many countries in that region have 0 images
    final Map<String, int> m = {};
    for (final entry in _grouped.entries) {
      final region = entry.key;
      final countries = entry.value;
      int cntNoImages = 0;
      for (final c in countries) {
        final imgNum = _imageCounts[c.isoCode] ?? 0;
        if (imgNum == 0) {
          cntNoImages++;
        }
      }
      m[region] = cntNoImages;
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
    ).then((_) {
      // refresh counts after possible edits
      _computeHasImages();
    });
  }

  // sum total banknotes in a region
  int _totalBanknotesForRegion(String region) {
    final countries = _grouped[region] ?? [];
    int sum = 0;
    for (final c in countries) {
      sum += _imageCounts[c.isoCode] ?? 0;
    }
    return sum;
  }

  // #region --- UI parts ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Banknotes",
          style: TextStyle(
            color: _textMain,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Your collection by continent",
          style: TextStyle(
            color: _textSub.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(
                color: _textMain.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _textMain,
              decoration: InputDecoration(
                hintText: 'Search a country…',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
              },
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinentCard(String region) {
    final countries = _grouped[region] ?? [];
    final totalCountries = countries.length;

    // Countries that ALREADY have at least 1 banknote = collectedCount
    final noImg = _monoCounts[region] ?? 0;
    final collectedCount = totalCountries - noImg;

    final banknotesInRegion = _totalBanknotesForRegion(region);

    final mainColor = _regionMainColor[region] ?? Colors.blueGrey;
    final badgeBg = mainColor.withOpacity(0.18);
    final badgeTextColor = mainColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showRegionBottomSheet(region, countries);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // left circular badge with 2-letter code
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _regionCode(region),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // middle text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$collectedCount / $totalCountries collected",
                    style: TextStyle(
                      color: _textSub.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // right side: pill + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _BanknotePill(
                  text: "$banknotesInRegion notes",
                  bgColor: Colors.white.withOpacity(0.07),
                  textColor: _textMain.withOpacity(0.8),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryResultCard(CountryData c) {
    final imgCount = _imageCounts[c.isoCode] ?? 0;

    // We'll tint badge based on whether it has any notes
    final bool hasAny = imgCount > 0;
    final Color badgeMain = hasAny ? Colors.greenAccent : Colors.white;
    final Color badgeBg = hasAny
        ? Colors.greenAccent.withOpacity(0.16)
        : Colors.white.withOpacity(0.08);
  // badgeTextColor was previously used for ISO-code text; now we render flags so it's unused.

    // pluralize
    final noteLabel = imgCount == 1 ? "1 banknote" : "$imgCount banknotes";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openCountry(c),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // left badge: country flag (emoji) with small count badge
            SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: badgeBg,
                      child: _imageCounts[c.isoCode] != null && (_imageCounts[c.isoCode] ?? 0) > 0
                          ? Text(
                              _flagEmoji(c.isoCode),
                              style: const TextStyle(fontSize: 20),
                            )
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0, 0, 0, 1, 0,
                              ]),
                              child: Text(
                                _flagEmoji(c.isoCode),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                    ),
                    // small count badge
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: imgCount > 0 ? Colors.redAccent : Colors.grey[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            imgCount > 99 ? '9+' : imgCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // middle text: country name & count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noteLabel,
                    style: TextStyle(
                      color: _textSub.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // chevron only
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegionBottomSheet(String region, List<CountryData> countries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      barrierColor: Colors.black.withOpacity(0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: _RegionSheetContent(
              region: region,
              countries: countries,
              imageCounts: _imageCounts,
              openCountry: _openCountry,
              bgColor: _bgColor,
              cardColor: _cardColor,
              textMain: _textMain,
              textSub: _textSub,
            ),
          ),
        );
      },
    );
  }

  // build continent list (default mode)
  Widget _buildContinentList() {
    final regions = _grouped.keys.toList()..sort();

    return Column(
      children: [
        for (final region in regions) ...[
          _buildContinentCard(region),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // build search results (when query is not empty)
  Widget _buildSearchResults() {
    final q = _searchQuery.toLowerCase();

    final matches = Countries.all.values
        .where((c) => c.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'No matches',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final c in matches) ...[
          _buildCountryResultCard(c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // short helper for continent badge text
  String _regionCode(String region) {
    // You can customize mappings for "North America" -> "NA", etc.
    final words = region.split(' ');
    if (words.length == 1) {
      // "Africa" -> AF, "Europe" -> EU
      if (region.length >= 2) {
        return region.substring(0, 2).toUpperCase();
      }
      return region.toUpperCase();
    } else {
      // "South America" -> SA, "North America" -> NA
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          "Banknotes",
          style: TextStyle(
            color: _textMain,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Header under app bar (subtitle etc.)
            // If you don't want duplicate title here, you can comment out.
            Text(
              "Your collection by continent",
              style: TextStyle(
                color: _textSub.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),

            _buildSearchBar(),
            const SizedBox(height: 20),

            if (_searchQuery.isEmpty)
              _buildContinentList()
            else
              _buildSearchResults(),
          ],
        ),
      ),
    );
  }
}

// pill like "38 notes"
class _BanknotePill extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _BanknotePill({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// bottom sheet content for a single region
class _RegionSheetContent extends StatelessWidget {
  final String region;
  final List<CountryData> countries;
  final Map<String, int> imageCounts;
  final void Function(CountryData) openCountry;

  // styling from parent
  final Color bgColor;
  final Color cardColor;
  final Color textMain;
  final Color textSub;

  const _RegionSheetContent({
    required this.region,
    required this.countries,
    required this.imageCounts,
    required this.openCountry,
    required this.bgColor,
    required this.cardColor,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...countries]..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // drag handle / header
        Row(
          children: [
            Expanded(
              child: Text(
                region,
                style: TextStyle(
                  color: textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded,
                  color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final c in sorted) ...[
                  _CountryRowCard(
                    c: c,
                    imgCount: imageCounts[c.isoCode] ?? 0,
                    openCountry: openCountry,
                    cardColor: cardColor,
                    textMain: textMain,
                    textSub: textSub,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// card used INSIDE region sheet list
class _CountryRowCard extends StatelessWidget {
  final CountryData c;
  final int imgCount;
  final void Function(CountryData) openCountry;

  final Color cardColor;
  final Color textMain;
  final Color textSub;

  const _CountryRowCard({
    required this.c,
    required this.imgCount,
    required this.openCountry,
    required this.cardColor,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAny = imgCount > 0;
    final Color badgeBg = hasAny
        ? Colors.greenAccent.withOpacity(0.16)
        : Colors.white.withOpacity(0.08);
    final Color badgeTextColor = hasAny
        ? Colors.greenAccent
        : Colors.white.withOpacity(0.9);

    final noteLabel =
        imgCount == 1 ? "1 banknote" : "$imgCount banknotes";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context); // close sheet
        openCountry(c); // go to detail
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ISO badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  c.isoCode.toUpperCase(),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noteLabel,
                    style: TextStyle(
                      color: textSub.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
