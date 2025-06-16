import 'dart:convert'; // For base64Decode
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// Siguraduhing mayroon ka ng mga import na ito sa iyong proyekto.
// import 'package:sk_connect/borrow_request_class.dart';
// import 'package:sk_connect/database_helper.dart';
// import 'package:sk_connect/utils.dart';

// This class represents the bottom sheet form for borrowing an item.
class BorrowFormSheet extends StatefulWidget {
  final Color accentColor;
  final List<String> controlNumbers;
  final Map<String, String> controlNumberImages; // NEW: Pass the images map
  final int maxAvailable;
  // Callback function when the form is submitted successfully.
  final Future<void> Function(Set<String>, String, DateTime) onSubmit;

  const BorrowFormSheet({
    super.key,
    required this.accentColor,
    required this.controlNumbers,
    required this.controlNumberImages, // NEW: Make it required in the constructor
    required this.maxAvailable,
    required this.onSubmit,
  });

  @override
  State<BorrowFormSheet> createState() => _BorrowFormSheetState();
}

class _BorrowFormSheetState extends State<BorrowFormSheet> {
  // Set to store the selected control numbers.
  final _selected = <String>{};
  // Controller for the purpose text field.
  final _purposeCtrl = TextEditingController();
  // Variables to store the selected return date and time.
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  // Field-specific error messages for better UX.
  String? _selectionError;
  String? _purposeError;
  String? _dateTimeError;

  @override
  void dispose() {
    _purposeCtrl.dispose(); // Dispose the controller to prevent memory leaks.
    super.dispose();
  }

  // Function to show date and time pickers for return date.
  Future<void> _pickReturn() async {
    final now = DateTime.now();
    // Show date picker.
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5), // A reasonable future date limit.
    );
    if (d == null || !mounted) return; // If no date is selected, do nothing.

    // Show time picker.
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return; // If no time is selected, do nothing.

    // Update state with selected date and time, clear any previous error.
    setState(() {
      _returnDate = d;
      _returnTime = t;
      _dateTimeError = null; // Clear error on selection.
    });
  }

  // Validates the form and sets error messages. Returns true if valid.
  bool _validateForm() {
    // Reset previous errors
    _selectionError = null;
    _purposeError = null;
    _dateTimeError = null;
    bool isValid = true;

    if (_selected.isEmpty) {
      _selectionError = 'Pumili ng kahit isang item.';
      isValid = false;
    }
    if (_selected.length > widget.maxAvailable) {
      _selectionError = 'Lumagpas sa dami ng available na items.';
      isValid = false;
    }
    if (_purposeCtrl.text.trim().isEmpty) {
      _purposeError = 'Kailangan ilagay ang pakay (purpose).';
      isValid = false;
    }
    if (_returnDate == null || _returnTime == null) {
      _dateTimeError = 'Pumili ng petsa at oras ng pagbabalik.';
      isValid = false;
    }

    // Update the UI with all error messages at once.
    setState(() {});
    return isValid;
  }

  // Function to handle form submission.
  Future<void> _handleSubmit() async {
    if (!_validateForm()) {
      return; // Stop if form is not valid.
    }

    // Combine date and time into a single DateTime object.
    final returnDateTime = DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
      _returnTime!.hour,
      _returnTime!.minute,
    );

    // Call the onSubmit callback with the selected values.
    await widget.onSubmit(_selected, _purposeCtrl.text.trim(), returnDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: theme.cardColor.withOpacity(0.9),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                top: 8,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Borrow Request Form', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Control Number Selection ---
                  Text('Select Item(s)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    height: 180, // Fixed height for the scrollable list.
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: widget.controlNumbers.map((cn) {
                        final String? imageBase64 = widget.controlNumberImages[cn];
                        final bool hasImage = imageBase64 != null && imageBase64.isNotEmpty;

                        return CheckboxListTile(
                          // CHANGED: 'leading' to 'secondary'
                          secondary: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(
                                    base64Decode(imageBase64!),
                                    width: 40, // Adjust size as needed
                                    height: 40, // Adjust size as needed
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.inventory, color: Colors.grey.shade500),
                                ),
                          title: Text(cn, style: textTheme.bodyLarge),
                          value: _selected.contains(cn),
                          onChanged: (chk) => setState(() {
                            chk! ? _selected.add(cn) : _selected.remove(cn);
                            _selectionError = null; // Clear error on change.
                          }),
                          controlAffinity: ListTileControlAffinity.trailing, // Keep checkbox on the right
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8), // Adjust padding
                          activeColor: widget.accentColor,
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectionError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(_selectionError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity Selected', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${_selected.length}', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: widget.accentColor)),
                    ],
                  ),

                  const Divider(height: 32, thickness: 1),

                  // --- Purpose Text Field ---
                  Text('Purpose', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _purposeCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g., For school project presentation',
                      errorText: _purposeError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (_) => setState(() => _purposeError = null),
                  ),

                  const SizedBox(height: 20),

                  // --- Return Date & Time Picker ---
                  Text('Return Schedule', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickReturn,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _returnDate != null && _returnTime != null
                          ? 'Return by: ${DateFormat.yMMMd().format(_returnDate!)} at ${_returnTime!.format(context)}'
                          : 'Select Return Date & Time',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: _dateTimeError != null ? theme.colorScheme.error : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_dateTimeError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(_dateTimeError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // --- Submit Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _handleSubmit,
                      label: const Text('Submit Request', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}