import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../data/banknote_store.dart';
import '../data/banknote_entry.dart';
import '../data/country_data.dart';

class AddBanknoteArgs {
  final String countryCode;
  final String? banknoteId; // Added for edit mode
  AddBanknoteArgs({required this.countryCode, this.banknoteId}); // Updated constructor
}

class AddBanknoteScreen extends StatefulWidget {
  static const routeName = '/add';

  final AddBanknoteArgs args;
  const AddBanknoteScreen({super.key, required this.args});

  @override
  State<AddBanknoteScreen> createState() => _AddBanknoteScreenState();
}

class _AddBanknoteScreenState extends State<AddBanknoteScreen> {
  final ImagePicker _picker = ImagePicker();
  BanknoteEntry? _existingEntry; // Track existing entry for edit mode

  File? _selectedImage;
  String? _originalImagePath; // Store original path for file deletion on update

  DateTime _selectedDate = DateTime.now();
  String _circStart = '';
  String _circEnd = '';
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _denominationCtrl = TextEditingController(); // New

  @override
  void initState() {
    super.initState();
    // Load existing entry if in edit mode
    if (widget.args.banknoteId != null) {
      _existingEntry = BanknoteStore.getById(widget.args.banknoteId!);
      if (_existingEntry != null) {
        _selectedDate = _existingEntry!.date;
        _circStart = _existingEntry!.circulationStart;
        _circEnd = _existingEntry!.circulationEnd;
        _notesCtrl.text = _existingEntry!.notes;
        _denominationCtrl.text = _existingEntry!.denomination; // Set initial value
        _originalImagePath = _existingEntry!.imagePath;
        // _selectedImage is not set here; we show the original image if no new one is picked.
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _denominationCtrl.dispose();
    super.dispose();
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

  // Collection date (_selectedDate) remains available but we no longer show a full date picker here.

  // STEP 2: choose image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickYear({required bool isStart}) async {
    // Build a list of years from 1800..currentYear
    final current = DateTime.now().year;
    final years = List<int>.generate(current - 1799, (i) => current - i);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Present'),
              onTap: () => Navigator.pop(ctx, 'Present'),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (c, i) {
                  final y = years[i];
                  return ListTile(
                    title: Text(y.toString()),
                    onTap: () => Navigator.pop(ctx, y.toString()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (chosen != null) {
      setState(() {
        if (isStart) {
          _circStart = chosen;
        } else {
          _circEnd = chosen;
        }
      });
    }
  }

  // STEP 3: save to disk and Hive
  Future<void> _saveBanknote() async {
    if (_existingEntry == null && _selectedImage == null && (_originalImagePath == null || _originalImagePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo.')),
      );
      return;
    }

    // Determine the image path
    String finalImagePath = _originalImagePath ?? '';
    if (_selectedImage != null) {
      // If a new image is selected (either in add or edit mode)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = const Uuid().v4();
      final newPath = '${appDir.path}/$fileName.jpg';

      try {
        await _selectedImage!.copy(newPath);
        finalImagePath = newPath;

        // If in edit mode and image has changed, delete the old file
        if (_existingEntry != null && _originalImagePath != null && _originalImagePath != finalImagePath) {
          try {
            await File(_originalImagePath!).delete();
          } catch (e) {
            print('Error deleting old image file: $e');
          }
        }
      } catch (e) {
        // Handle file saving error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving image: $e')),
          );
        }
        return;
      }
    }

    final newEntry = BanknoteEntry(
      // Use existing ID for update, or generate a new one for add
      id: _existingEntry?.id ?? const Uuid().v4(),
      countryCode: widget.args.countryCode,
      imagePath: finalImagePath,
      date: _selectedDate,
      circulationStart: _circStart,
      circulationEnd: _circEnd,
      notes: _notesCtrl.text.trim(),
      denomination: _denominationCtrl.text.trim(), // Added
    );

    if (_existingEntry != null) {
      await BanknoteStore.update(newEntry);
    } else {
      await BanknoteStore.add(newEntry);
    }

    if (mounted) {
      Navigator.pop(context, true); // Pop and indicate success to parent screen
    }
  }

  @override
  Widget build(BuildContext context) {
  final isEditing = _existingEntry != null;
    
    // Determine the image source to display in the preview
    Widget imagePreview;
    if (_selectedImage != null) {
      // Newly selected image
      imagePreview = Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (isEditing && _originalImagePath != null && _originalImagePath!.isNotEmpty) {
      // Existing image for editing
      imagePreview = Image.file(
        File(_originalImagePath!),
        fit: BoxFit.cover,
      );
    } else {
      // No image selected
      imagePreview = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 48, color: Colors.black54),
            SizedBox(height: 8),
            Text("Tap to select photo", style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Banknote' : 'Add Banknote'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveBanknote,
        label: const Text('Save'),
        icon: const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with country
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(_flagEmoji(widget.args.countryCode), style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Countries.nameForCode(widget.args.countryCode),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.args.countryCode.toUpperCase(), style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // IMAGE (improved): preview with overlay actions
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: imagePreview),
                ),

                // actions
                Positioned(
                  right: 8,
                  top: 8,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'camera',
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: const Icon(Icons.camera_alt, size: 18),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'gallery',
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: const Icon(Icons.photo_library, size: 18),
                      ),
                    ],
                  ),
                ),

                if (_selectedImage != null || (isEditing && _originalImagePath != null && _originalImagePath!.isNotEmpty))
                  Positioned(
                    left: 8,
                    top: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'remove',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _originalImagePath = '';
                        });
                      },
                      child: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // DENOMINATION (New)
          const Text(
            "Denomination",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _denominationCtrl,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: "e.g., 20 TL or 1000 Yen",
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // CIRCULATION YEARS (start / end)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Circulation start", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () => _pickYear(isStart: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_circStart.isEmpty ? 'Select year or Present' : _circStart),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Circulation end", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () => _pickYear(isStart: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_circEnd.isEmpty ? 'Select year or Present' : _circEnd),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(height: 32),

          // NOTES
          const Text(
            "Details / Notes",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Where did you get it? Condition? Serial?",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}