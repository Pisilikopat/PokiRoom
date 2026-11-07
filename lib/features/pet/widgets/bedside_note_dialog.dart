// lib/features/pet/widgets/bedside_note_dialog.dart

import 'package:flutter/material.dart';
import '../pet_strings.dart';

class BedsideNoteDialog extends StatefulWidget {
  const BedsideNoteDialog({super.key});

  @override
  State<BedsideNoteDialog> createState() => _BedsideNoteDialogState();
}

class _BedsideNoteDialogState extends State<BedsideNoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Text('🌙', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text(PetStrings.sleepDialogTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partnerin için başucuna tatlı bir iyi geceler notu bırakabilirsin:',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 120,
            decoration: InputDecoration(
              hintText: PetStrings.sleepDialogHint,
              hintStyle: const TextStyle(fontSize: 12.5),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(PetStrings.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text(PetStrings.sleepDialogConfirm),
        ),
      ],
    );
  }
}
