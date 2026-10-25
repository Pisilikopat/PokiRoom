// lib/features/empty_pocket/widgets/edit_poki_code_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/poki_exception.dart';
import '../../../core/theme/poki_theme.dart';
import '../../../core/utils/poki_code_validator.dart';
import '../../../data/models/poki_user.dart';
import '../../../data/repositories/user_repository.dart';

/// PokiCode değiştirme alt paneli. Başarılıysa güncel [PokiUser] ile kapanır.
class EditPokiCodeSheet extends StatefulWidget {
  const EditPokiCodeSheet({
    super.key,
    required this.currentTag,
    required this.repository,
  });

  final String currentTag;
  final UserRepository repository;

  static Future<PokiUser?> show(
    BuildContext context, {
    required String currentTag,
    required UserRepository repository,
  }) {
    return showModalBottomSheet<PokiUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PokiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PokiRadius.card)),
      ),
      builder: (_) => EditPokiCodeSheet(
        currentTag: currentTag,
        repository: repository,
      ),
    );
  }

  @override
  State<EditPokiCodeSheet> createState() => _EditPokiCodeSheetState();
}

class _EditPokiCodeSheetState extends State<EditPokiCodeSheet> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: PokiCodeValidator.extractSuffix(widget.currentTag),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final suffix = PokiCodeValidator.extractSuffix(_controller.text);
    if (!PokiCodeValidator.isValidSuffix(suffix)) {
      setState(() => _error = '4-12 karakter, sadece harf ve rakam kullan 🐾');
      return;
    }
    if (PokiCodeValidator.toFullTag(suffix) == widget.currentTag) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.updateCustomTag(suffix);
      if (mounted) Navigator.of(context).pop(updated);
    } on PokiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PokiCode\'unu değiştir', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Eski kodun serbest kalır. Mevcut odaların etkilenmez.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(12),
              TextInputFormatter.withFunction(
                (old, next) => next.copyWith(text: next.text.toUpperCase()),
              ),
            ],
            decoration: InputDecoration(
              prefixText: PokiCodeValidator.prefix,
              prefixStyle: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
              hintText: '4829',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
