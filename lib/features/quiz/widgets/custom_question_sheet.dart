// lib/features/quiz/widgets/custom_question_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/utils/uuid.dart';
import '../models/quiz_question.dart';
import '../theme/quiz_palette.dart';

/// Kendi merak ettiğin 4 şıklı soruyu yaz. Başarılıysa [QuizQuestion] ile kapanır.
class CustomQuestionSheet extends StatefulWidget {
  const CustomQuestionSheet({super.key});

  static Future<QuizQuestion?> show(BuildContext context) {
    return showModalBottomSheet<QuizQuestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: QuizPalette.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CustomQuestionSheet(),
    );
  }

  @override
  State<CustomQuestionSheet> createState() => _CustomQuestionSheetState();
}

class _CustomQuestionSheetState extends State<CustomQuestionSheet> {
  final _question = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());

  bool get _valid =>
      _question.text.trim().isNotEmpty &&
      _options.every((c) => c.text.trim().isNotEmpty);

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(
      QuizQuestion(
        id: generateUuidV4(),
        text: _question.text.trim(),
        options: [for (final c in _options) c.text.trim()],
        isCustom: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const letters = ['A', 'B', 'C', 'D'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kendi sorunu ekle ✍️', style: QuizPalette.title(context)),
            const SizedBox(height: 4),
            Text('Partnerine merak ettiğin bir şeyi sor.',
                style: QuizPalette.caption(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _question,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Sorun nedir?'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _options[i],
                  maxLength: 60,
                  buildCounter: (_,
                          {required currentLength, required isFocused, maxLength}) =>
                      null,
                  decoration: InputDecoration(hintText: '${letters[i]} şıkkı'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _valid ? _submit : null,
                child: const Text('Soruyu ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
