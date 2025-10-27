import 'dart:io';
import 'package:flutter/material.dart';
import '../data/banknote_store.dart';
import '../data/banknote_entry.dart';
import 'add_banknote_screen.dart'; // Import for navigation

class BanknoteDetailArgs {
  final String banknoteId;
  BanknoteDetailArgs({required this.banknoteId});
}

class BanknoteDetailScreen extends StatefulWidget {
  static const routeName = '/detail';

  final BanknoteDetailArgs args;
  const BanknoteDetailScreen({super.key, required this.args});

  @override
  State<BanknoteDetailScreen> createState() => _BanknoteDetailScreenState();
}

class _BanknoteDetailScreenState extends State<BanknoteDetailScreen> {
  BanknoteEntry? _entry;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  void _loadEntry() {
    _entry = BanknoteStore.getById(widget.args.banknoteId);
  }

  Future<void> _delete() async {
    if (_entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this banknote?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BanknoteStore.delete(_entry!.id);
      if (mounted) {
        // Return true to parent screen (CountryDetailScreen) to indicate refresh is needed
        Navigator.pop(context, true); 
      }
    }
  }
  
  // New: Edit handler
  Future<void> _edit() async {
    if (_entry == null) return;
    final bool? shouldRefresh = await Navigator.pushNamed(
      context,
      AddBanknoteScreen.routeName,
      arguments: AddBanknoteArgs(
        countryCode: _entry!.countryCode,
        banknoteId: _entry!.id,
      ),
    ) as bool?;

    if (shouldRefresh == true) {
      // Reload entry after successful edit
      setState(() {
        _loadEntry();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    _loadEntry(); // Re-load to ensure latest data on rebuild (after edit/delete)
    final e = _entry;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Banknote not found.")),
      );
    }
    
    final String dateLabel =
        '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(e.denomination.isNotEmpty ? e.denomination : "Banknote"), // Display denomination in title
        actions: [
          // New: Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: e.imagePath.isEmpty
                  ? const Center(
                      child: Icon(Icons.photo, size: 64),
                    )
                  : Image.file(
                      File(e.imagePath),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // New: Denomination display
          if (e.denomination.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Denomination"),
                  subtitle: Text(e.denomination),
                ),
                const Divider(height: 1),
              ],
            ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Date"),
            subtitle: Text(dateLabel),
          ),
          const Divider(height: 32),
          const Text(
            "Details / Notes",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            e.notes.isEmpty ? "—" : e.notes,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}