// lib/features/room/widgets/message_input.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_message.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    required this.onTypingChanged,
    required this.onOpenMenu,
    this.replyInfo,
    this.onCancelReply,
    this.focusNode,
  });

  final void Function(String text) onSend;
  final void Function(bool typing) onTypingChanged;

  /// Poki-Poke menüsünü açar.
  final VoidCallback onOpenMenu;

  /// Yanıtlanan mesaj bilgisi
  final PokiReplyInfo? replyInfo;
  final VoidCallback? onCancelReply;
  final FocusNode? focusNode;

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
    final reply = widget.replyInfo;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Yanıtlama Önizleme Çubuğu ───
          if (reply != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: PokiColors.surfaceOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  left: const BorderSide(
                    color: PokiColors.primaryButton,
                    width: 4,
                  ),
                  top: BorderSide(color: Colors.black.withOpacity(0.05)),
                  right: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    color: PokiColors.primaryButton,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${reply.senderNickname} yanıtlanıyor',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: PokiColors.primaryButton,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reply.snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: PokiColors.textOf(context).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Yanıtı İptal Et',
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),

          // ─── Mesaj Yazma Alanı ───
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
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
                    focusNode: widget.focusNode,
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
        ],
      ),
    );
  }
}
