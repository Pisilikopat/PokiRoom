// lib/features/empty_pocket/widgets/knock_form_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/poki_exception.dart';
import '../../../core/utils/poki_code_validator.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../shared/widgets/poki_card.dart';

/// Başka birinin PokiCode'unu girip kısa notla "Odaya Tıklat" gönderme alanı.
class KnockFormCard extends StatefulWidget {
  const KnockFormCard({super.key, required this.repository});

  final RequestRepository repository;

  @override
  State<KnockFormCard> createState() => _KnockFormCardState();
}

class _KnockFormCardState extends State<KnockFormCard> {
  final _codeController = TextEditingController();
  final _noteController = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _codeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _knock() async {
    final suffix = PokiCodeValidator.extractSuffix(_codeController.text);
    if (!PokiCodeValidator.isValidSuffix(suffix)) {
      setState(() => _error = 'Geçerli bir PokiCode gir, örn. #POKI-4829');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.sendKnock(
        suffix: suffix,
        message: _noteController.text,
      );
      if (!mounted) return;
      _codeController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Tık tık! 🐾 Cevabı bekliyoruz...'),
        ));
    } on PokiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PokiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Birinin cebine tıklat', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            enabled: !_sending,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              TextInputFormatter.withFunction(
                (old, next) => next.copyWith(text: next.text.toUpperCase()),
              ),
            ],
            decoration: InputDecoration(
              hintText: '#POKI-0000',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            enabled: !_sending,
            maxLength: 140,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Kısa bir not bırak (isteğe bağlı)',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _knock,
              icon: _sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.pets_rounded),
              label: const Text('Odaya Tıklat'),
            ),
          ),
        ],
      ),
    );
  }
}
