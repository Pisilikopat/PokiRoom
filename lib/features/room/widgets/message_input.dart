// lib/features/room/widgets/message_input.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    required this.onTypingChanged,
    required this.onOpenMenu,
  });

  final void Function(String text) onSend;
  final void Function(bool typing) onTypingChanged;

  /// Poki-Poke menüsünü açar.
  final VoidCallback onOpenMenu;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  Timer? _typingTimer;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    if (value.trim().isEmpty) {
      _typingTimer?.cancel();
      widget.onTypingChanged(false);
      return;
    }
    widget.onTypingChanged(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(
      const Duration(seconds: 2),
      () => widget.onTypingChanged(false),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _typingTimer?.cancel();
    widget.onTypingChanged(false);
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Poki-Poke',
              iconSize: 28,
              color: PokiColors.primaryButton,
              icon: const Icon(Icons.pets_rounded),
              onPressed: widget.onOpenMenu,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(hintText: 'Bir şeyler fısılda...'),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canSend ? 1 : 0.5,
              child: Material(
                color: PokiColors.primaryButton,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend ? _send : null,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.send_rounded,
                        color: PokiColors.background, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
