import 'dart:io';
import 'package:flutter/material.dart';

import '../data/banknote_store.dart';
import '../data/banknote_entry.dart';
import '../data/country_data.dart';
import 'add_banknote_screen.dart';
import 'banknote_detail_screen.dart';

class CountryDetailArgs {
  final String countryCode; // e.g. "AZ", "TR", "US"
  final String countryName; // e.g. "Azerbaijan", "Türkiye"
  CountryDetailArgs({required this.countryCode, required this.countryName});
}

class CountryDetailScreen extends StatefulWidget {
  static const routeName = '/country';
  final CountryDetailArgs args;

  const CountryDetailScreen({super.key, required this.args});

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

/// Helper that turns "AZ" -> 🇦🇿, "TR" -> 🇹🇷, etc.
/// Same logic you already use in AddBanknoteScreen.
String _flagEmoji(String iso) {
  if (iso.length != 2) return iso;
  final up = iso.toUpperCase();
  const int base = 0x1F1E6; // Regional Indicator Symbol Letter A
  final codeUnits = up.codeUnits;
  final first = String.fromCharCode(base + (codeUnits[0] - 65));
  final second = String.fromCharCode(base + (codeUnits[1] - 65));
  return '$first$second';
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  List<BanknoteEntry> _entries = [];

  void _load() {
    _entries = BanknoteStore.getByCountry(widget.args.countryCode);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    _load(); // refresh list when returning from other screens

    final countryCode = widget.args.countryCode;
    final countryName = widget.args.countryName;
    final totalCount = _entries.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(
              countryCode: countryCode,
              countryName: countryName,
              totalCount: totalCount,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: totalCount == 0
                  ? _EmptyState(
                      countryCode: countryCode,
                      countryName: countryName,
                      onAdd: () async {
                        final bool? shouldRefresh =
                            await Navigator.pushNamed(
                          context,
                          AddBanknoteScreen.routeName,
                          arguments:
                              AddBanknoteArgs(countryCode: countryCode),
                        ) as bool?;
                        if (shouldRefresh == true) {
                          setState(_load);
                        }
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) {
                        final e = _entries[i];
                        final imageFile = File(e.imagePath);
                        final hasImage = imageFile.existsSync();

                        return _BanknoteCard(
                          entry: e,
                          hasImage: hasImage,
                          imageFile: imageFile,
                          countryCode: countryCode,
                          onTap: () async {
                            final bool? shouldRefresh =
                                await Navigator.pushNamed(
                              context,
                              BanknoteDetailScreen.routeName,
                              arguments:
                                  BanknoteDetailArgs(banknoteId: e.id),
                            ) as bool?;
                            if (shouldRefresh == true) {
                              setState(_load);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _entries.isEmpty
          ? null
          : _AddFAB(
              onPressed: () async {
                final bool? shouldRefresh = await Navigator.pushNamed(
                  context,
                  AddBanknoteScreen.routeName,
                  arguments:
                      AddBanknoteArgs(countryCode: widget.args.countryCode),
                ) as bool?;
                if (shouldRefresh == true) {
                  setState(_load);
                }
              },
            ),
    );
  }
}

/// ------------------------------------------------------
/// HEADER (back button, flag, country name, stats)
/// ------------------------------------------------------
class _HeaderSection extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final int totalCount;

  const _HeaderSection({
    required this.countryCode,
    required this.countryName,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1D), Color(0x00000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Row(
              children: [
                _FlagCircle(countryCode: countryCode, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.museum_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$totalCount banknote${totalCount == 1 ? '' : 's'}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------
/// BANKNOTE CARD UI
/// ------------------------------------------------------
class _BanknoteCard extends StatelessWidget {
  final BanknoteEntry entry;
  final bool hasImage;
  final File imageFile;
  final String countryCode;
  final VoidCallback onTap;

  const _BanknoteCard({
    required this.entry,
    required this.hasImage,
    required this.imageFile,
    required this.countryCode,
    required this.onTap,
  });

  String _shortDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  String _notesOrFallback(String n) {
    if (n.trim().isEmpty) return "No description";
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                          )
                        : const _PlaceholderImage(),
                  ),

                  // FLAG CHIP (top-left overlay)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FlagCircle(countryCode: countryCode, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            countryCode.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // META
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A1D), Color(0x00000000)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.denomination.isNotEmpty)
                    Text(
                      entry.denomination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    "${_shortDate(entry.date)} • ${_notesOrFallback(entry.notes)}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: entry.denomination.isNotEmpty ? 12 : 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------
/// ADD BUTTON (FAB)
/// ------------------------------------------------------
class _AddFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF2F2F33),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        "Add banknote",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// ------------------------------------------------------
/// EMPTY STATE
/// ------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.countryCode,
    required this.countryName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.2,
              child: _FlagCircle(countryCode: countryCode, size: 72),
            ),
            const SizedBox(height: 24),
            const Text(
              "No banknotes yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You haven't added any $countryName banknotes yet. Let's add your first one.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Add banknote",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F2F33),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white10, width: 1),
                ),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------
/// PLACEHOLDER (shown when no image yet)
/// ------------------------------------------------------
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2F), Color(0xFF1A1A1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Opacity(
          opacity: 0.4,
          child: Icon(
            Icons.style_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------
/// FLAG CIRCLE (emoji style, same as AddBanknoteScreen)
/// ------------------------------------------------------
class _FlagCircle extends StatelessWidget {
  final String countryCode;
  final double size;
  const _FlagCircle({
    required this.countryCode,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: size * 0.06,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _flagEmoji(countryCode),
        style: TextStyle(
          fontSize: size * 0.55,
          height: 1.0,
        ),
      ),
    );
  }
}
