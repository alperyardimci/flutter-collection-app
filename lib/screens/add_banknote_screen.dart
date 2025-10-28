// ignore_for_file: deprecated_member_use

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
  final String? banknoteId;
  AddBanknoteArgs({required this.countryCode, this.banknoteId});
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

  BanknoteEntry? _existingEntry;

  File? _selectedImage;
  String? _originalImagePath;

  DateTime _selectedDate = DateTime.now();
  String _circStart = '';
  String _circEnd = '';
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _denominationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // edit mode preload
    if (widget.args.banknoteId != null) {
      _existingEntry = BanknoteStore.getById(widget.args.banknoteId!);
      if (_existingEntry != null) {
        _selectedDate = _existingEntry!.date;
        _circStart = _existingEntry!.circulationStart;
        _circEnd = _existingEntry!.circulationEnd;
        _notesCtrl.text = _existingEntry!.notes;
        _denominationCtrl.text = _existingEntry!.denomination;
        _originalImagePath = _existingEntry!.imagePath;
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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickYear({required bool isStart}) async {
    final current = DateTime.now().year;
    final years = List<int>.generate(current - 1799, (i) => current - i);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Present'),
                onTap: () => Navigator.pop(ctx, 'Present'),
              ),
              const Divider(height: 1),
              Expanded(
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
          ),
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

  Future<void> _saveBanknote() async {
    // validation: needs photo in add mode
    final hasExistingImg = _originalImagePath != null && _originalImagePath!.isNotEmpty;
    if (_existingEntry == null && _selectedImage == null && !hasExistingImg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo.')),
      );
      return;
    }

    // persist image if new selected
    String finalImagePath = _originalImagePath ?? '';
    if (_selectedImage != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = const Uuid().v4();
      final newPath = '${appDir.path}/$fileName.jpg';

      try {
        await _selectedImage!.copy(newPath);
        finalImagePath = newPath;

        // cleanup old file if changed
        if (_existingEntry != null &&
            _originalImagePath != null &&
            _originalImagePath != finalImagePath) {
          try {
            await File(_originalImagePath!).delete();
          } catch (e) {
            debugPrint('Error deleting old image file: $e');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving image: $e')),
          );
        }
        return;
      }
    }

    final newEntry = BanknoteEntry(
      id: _existingEntry?.id ?? const Uuid().v4(),
      countryCode: widget.args.countryCode,
      imagePath: finalImagePath,
      date: _selectedDate,
      circulationStart: _circStart,
      circulationEnd: _circEnd,
      notes: _notesCtrl.text.trim(),
      denomination: _denominationCtrl.text.trim(),
    );

    if (_existingEntry != null) {
      await BanknoteStore.update(newEntry);
    } else {
      await BanknoteStore.add(newEntry);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingEntry != null;

    // THEME SHORTCUTS
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // build preview image widget
    Widget buildImagePreview() {
      if (_selectedImage != null) {
        return Image.file(_selectedImage!, fit: BoxFit.cover);
      } else if (isEditing &&
          _originalImagePath != null &&
          _originalImagePath!.isNotEmpty) {
        return Image.file(File(_originalImagePath!), fit: BoxFit.cover);
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined,
                  size: 48, color: cs.onSurface.withOpacity(0.4)),
              const SizedBox(height: 8),
              Text(
                "Tap camera or gallery",
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    // ----- PAGE BODY -----
    final body = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top card with country + form
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COUNTRY ROW
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                _flagEmoji(widget.args.countryCode),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Countries.nameForCode(
                                        widget.args.countryCode),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.args.countryCode.toUpperCase(),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface
                                          .withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // PHOTO AREA
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: buildImagePreview(),
                                ),

                                // delete button (top-left) if we have any image
                                if (_selectedImage != null ||
                                    (isEditing &&
                                        _originalImagePath != null &&
                                        _originalImagePath!.isNotEmpty))
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    child: _CircleActionButton(
                                      icon: Icons.delete_outline,
                                      bgColor: cs.surface,
                                      fgColor: Colors.redAccent,
                                      onTap: () {
                                        setState(() {
                                          _selectedImage = null;
                                          _originalImagePath = '';
                                        });
                                      },
                                    ),
                                  ),

                                // camera / gallery (top-right stack)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Column(
                                    children: [
                                      _CircleActionButton(
                                        icon: Icons.camera_alt_outlined,
                                        onTap: () =>
                                            _pickImage(ImageSource.camera),
                                        bgColor: cs.surface,
                                        fgColor: cs.onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      _CircleActionButton(
                                        icon: Icons.photo_library_outlined,
                                        onTap: () =>
                                            _pickImage(ImageSource.gallery),
                                        bgColor: cs.surface,
                                        fgColor: cs.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // DENOMINATION FIELD (card style row)
                        _LabeledTextFieldRow(
                          label: 'Denomination',
                          hint: 'e.g., 20 TL or 1000 Yen',
                          icon: Icons.payments_outlined,
                          controller: _denominationCtrl,
                        ),

                        const SizedBox(height: 12),

                        // CIRCULATION START
                        _TapRow(
                          title: 'Circulation start',
                          valueText:
                              _circStart.isEmpty ? 'Select…' : _circStart,
                          onTap: () => _pickYear(isStart: true),
                        ),

                        const SizedBox(height: 8),

                        // CIRCULATION END
                        _TapRow(
                          title: 'Circulation end',
                          valueText: _circEnd.isEmpty ? 'Select…' : _circEnd,
                          onTap: () => _pickYear(isStart: false),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Details / Notes",
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _notesCtrl,
                            maxLines: 4,
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText:
                                  "Where did you get it?\nCondition? Serial?",
                              hintStyle: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // ----- SAVE BAR -----
    final bottomBar = SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saveBanknote,
          icon: const Icon(Icons.check),
          label: const Text("Save"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Banknote' : 'Add Banknote'),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Small circular icon button floating on the image
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? fgColor;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.bgColor,
    this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: bgColor ?? cs.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: fgColor ?? cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A text field row with label + rounded container like in mockup
class _LabeledTextFieldRow extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _LabeledTextFieldRow({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Icon(
                  icon,
                  size: 20,
                  color: cs.onSurface.withOpacity(0.65),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(
                      top: 14,
                      bottom: 14,
                      right: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tappable row that looks like iOS/Material list cell with value + chevron
class _TapRow extends StatelessWidget {
  final String title;
  final String valueText;
  final VoidCallback onTap;

  const _TapRow({
    required this.title,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                valueText,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
