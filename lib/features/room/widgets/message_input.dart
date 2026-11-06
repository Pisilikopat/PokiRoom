// lib/features/room/widgets/message_input.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/poki_theme.dart';
import '../../../data/models/poki_message.dart';
import '../services/voice_recorder_service.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    required this.onTypingChanged,
    required this.onOpenMenu,
    this.onSendVoice,
    this.replyInfo,
    this.onCancelReply,
    this.focusNode,
  });

  final void Function(String text) onSend;
  final void Function(bool typing) onTypingChanged;
  final void Function(VoiceRecordResult result)? onSendVoice;

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
  final _recorder = VoiceRecorderService();
  Timer? _typingTimer;

  bool _isDraggingCancel = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _recorder.dispose();
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

  Future<void> _startVoiceRecord() async {
    HapticFeedback.mediumImpact();
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli 🎙️🐾'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final ok = await _recorder.startRecording();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses kaydı başlatılamadı 🎙️🐾'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopAndSendVoiceRecord() async {
    HapticFeedback.lightImpact();
    final result = await _recorder.stopRecording();
    if (result != null) {
      widget.onSendVoice?.call(result);
    }
    setState(() => _isDraggingCancel = false);
  }

  Future<void> _cancelVoiceRecord() async {
    HapticFeedback.selectionClick();
    await _recorder.cancelRecording();
    setState(() => _isDraggingCancel = false);
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
                  left: BorderSide(
                    color: PokiColors.primaryButtonOf(context),
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
                  Icon(
                    Icons.reply_rounded,
                    color: PokiColors.primaryButtonOf(context),
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
                            color: PokiColors.primaryButtonOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reply.cleanSnippet,
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

          // ─── Mesaj Yazma / Ses Kayıt Alanı ───
          ValueListenableBuilder<VoiceRecorderState>(
            valueListenable: _recorder.state,
            builder: (context, recState, _) {
              final isRecording = recState.isRecording;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isRecording) ...[
                      IconButton(
                        tooltip: 'Poki-Poke',
                        iconSize: 28,
                        color: PokiColors.primaryButtonOf(context),
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
                          decoration: const InputDecoration(
                              hintText: 'Bir şeyler fısılda...'),
                        ),
                      ),
                    ] else ...[
                      // Ses Kayıt Çubuğu
                      Expanded(
                        child: _RecordingBar(
                          state: recState,
                          isCanceling: _isDraggingCancel,
                          onTrash: _cancelVoiceRecord,
                        ),
                      ),
                    ],

                    const SizedBox(width: 8),

                    // Sağ Buton: Metin varsa Gönder / Yoksa Mikrofon
                    if (canSend)
                      Material(
                        color: PokiColors.primaryButtonOf(context),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _send,
                          child: const Padding(
                            padding: EdgeInsets.all(13),
                            child: Icon(Icons.send_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      )
                    else if (isRecording)
                      // Kayıt modundayken gönderme butonu
                      Material(
                        color: const Color(0xFF4CAF50),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _stopAndSendVoiceRecord,
                          child: const Padding(
                            padding: EdgeInsets.all(13),
                            child: Icon(Icons.arrow_upward_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      )
                    else
                      // Mikrofon butonu (Basılı tut kaydet / Kilitle)
                      GestureDetector(
                        onLongPressStart: (_) => _startVoiceRecord(),
                        onLongPressMoveUpdate: (details) {
                          if (details.offsetFromOrigin.dx < -70) {
                            if (!_isDraggingCancel) {
                              setState(() => _isDraggingCancel = true);
                              HapticFeedback.lightImpact();
                            }
                          } else if (details.offsetFromOrigin.dy < -50) {
                            _recorder.lockRecording();
                            HapticFeedback.mediumImpact();
                          } else {
                            if (_isDraggingCancel) {
                              setState(() => _isDraggingCancel = false);
                            }
                          }
                        },
                        onLongPressEnd: (details) {
                          if (_isDraggingCancel) {
                            _cancelVoiceRecord();
                          } else if (!_recorder.state.value.isLocked) {
                            _stopAndSendVoiceRecord();
                          }
                        },
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Sesli mesaj göndermek için basılı tut 🎙️🐾'),
                              duration: Duration(milliseconds: 1400),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Material(
                          color: PokiColors.primaryButtonOf(context),
                          shape: const CircleBorder(),
                          elevation: 1,
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecordingBar extends StatefulWidget {
  const _RecordingBar({
    required this.state,
    required this.isCanceling,
    required this.onTrash,
  });

  final VoiceRecorderState state;
  final bool isCanceling;
  final VoidCallback onTrash;

  @override
  State<_RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<_RecordingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: widget.isCanceling
            ? Colors.red.shade50
            : PokiColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isCanceling
              ? Colors.red.shade300
              : PokiColors.primaryButtonOf(context).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: PokiShadows.softOf(context),
      ),
      child: Row(
        children: [
          // Kırmızı Yanıp Sönen Kayıt Noktası
          FadeTransition(
            opacity: _pulseController,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sayaç (0:04)
          Text(
            widget.state.formattedDuration,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: widget.isCanceling
                  ? Colors.red.shade700
                  : PokiColors.textOf(context),
            ),
          ),

          const SizedBox(width: 12),

          // Canlı ses seviyesi dalgalanması
          Expanded(
            child: widget.isCanceling
                ? Text(
                    'İptal ediliyor...',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.state.isLocked
                            ? 'Kaydediliyor 🎙️'
                            : '◀ İptal için kaydır 🐾',
                        style: textTheme.labelSmall?.copyWith(
                          color: PokiColors.textOf(context).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
          ),

          // Çöp Kutusu (İptal Butonu)
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: Colors.red.shade400,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'İptal Et',
            onPressed: widget.onTrash,
          ),
        ],
      ),
    );
  }
}
