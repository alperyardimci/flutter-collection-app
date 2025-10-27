import 'package:flutter/material.dart';
import '../data/banknote_store.dart';
import '../data/banknote_entry.dart';
import 'add_banknote_screen.dart';
import 'banknote_detail_screen.dart';
import 'dart:io';

class CountryDetailArgs {
  final String countryCode;
  final String countryName;
  CountryDetailArgs({required this.countryCode, required this.countryName});
}

class CountryDetailScreen extends StatefulWidget {
  static const routeName = '/country';
  final CountryDetailArgs args;

  const CountryDetailScreen({super.key, required this.args});

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
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
    _load(); // Re-load before build to catch changes from pop/refresh.
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.args.countryName)),
      body:
          _entries.isEmpty
              ? Center(
                child: Text(
                  "No banknotes added for ${widget.args.countryName} yet. Tap + to add your first one!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75, // Adjusted for better aspect ratio
                  ),
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) {
                    final e = _entries[i];
                    final imageFile = File(e.imagePath);
                    final bool imageExists = imageFile.existsSync();

                    return GestureDetector(
                      onTap: () async { // Changed to async to await result
                        // Detail screen will return true if delete/edit caused a change
                        final bool? shouldRefresh = await Navigator.pushNamed(
                          context,
                          BanknoteDetailScreen.routeName,
                          arguments: BanknoteDetailArgs(banknoteId: e.id),
                        ) as bool?;
                        
                        if (shouldRefresh == true) {
                          // Refresh the list and implicitly the map highlight
                          setState(_load); 
                        }
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.grey.shade300,
                                child: imageExists
                                    ? Image.file(
                                        imageFile,
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: Icon(Icons.photo, size: 48),
                                      ),
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display Denomination if present
                                  if (e.denomination.isNotEmpty) 
                                    Text(
                                      e.denomination,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  
                                  Text(
                                    // Combine date and notes
                                    "${_shortDate(e.date)} • ${_shortNotes(e.notes)}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: e.denomination.isNotEmpty ? 12 : 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // AddBanknoteScreen will return true if saved successfully
          final bool? shouldRefresh = await Navigator.pushNamed(
            context,
            AddBanknoteScreen.routeName,
            arguments: AddBanknoteArgs(countryCode: widget.args.countryCode),
          ) as bool?;
          
          if (shouldRefresh == true) {
            setState(_load);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _shortDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  String _shortNotes(String n) {
    if (n.trim().isEmpty) return "No description";
    return n;
  }
}