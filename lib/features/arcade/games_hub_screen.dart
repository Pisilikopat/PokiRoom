import '../canvas/poki_canvas_screen.dart';
// lib/features/arcade/games_hub_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/game_lobby_service.dart';
import '../../data/services/room_presence.dart';
import '../../shared/widgets/poki_card.dart';
import '../puzzle/models/puzzle_config.dart';
import '../puzzle/puzzle_game_screen.dart';
import '../puzzle/puzzle_setup_screen.dart';
import '../quiz/logic/quiz_deck.dart';
import '../quiz/quiz_game_screen.dart';
import '../quiz/quiz_lobby_screen.dart';

/// Poki Oyun Odası (Poki Arcade): Aktif oyunları görme ve yeni lobi oluşturma merkezi.
class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  @override
  void initState() {
    super.initState();
    GameLobbyService.instance.init(widget.roomId);
    RoomPresence.current?.setActivity(PokiActivity.gamesHub);
  }

  @override
  void dispose() {
    RoomPresence.current?.setActivity(PokiActivity.inApp);
    super.dispose();
  }

  void _joinQuiz(QuizInvite invite) {
    GameLobbyService.instance.clearQuizInvite();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizGameScreen(
          roomId: widget.roomId,
          config: invite.config,
          deck: QuizDeck(invite.questions),
          isHost: false,
        ),
      ),
    );
  }

  void _joinCanvas(CanvasInvite invite) {
    GameLobbyService.instance.clearCanvasInvite();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PokiCanvasScreen(
          roomId: widget.roomId,
          isCoop: true,
        ),
      ),
    );
  }

  void _openSoloCanvas() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PokiCanvasScreen(
          roomId: widget.roomId,
          isCoop: false,
        ),
      ),
    );
  }

  void _openCoopCanvas() {
    final nick = Supabase.instance.client.auth.currentUser?.userMetadata?['nickname'] as String? ?? 'Partnerin';
    GameLobbyService.instance.sendCanvasInvite(nick);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PokiCanvasScreen(
          roomId: widget.roomId,
          isCoop: true,
        ),
      ),
    );
  }

  void _joinPuzzle(PuzzleInvite invite) {
    GameLobbyService.instance.clearPuzzleInvite();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleGameScreen(
          roomId: widget.roomId,
          config: invite.config,
        ),
      ),
    );
  }

  void _openQuizLobby() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizLobbyScreen(roomId: widget.roomId),
      ),
    );
  }

  void _openPuzzleSetup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleSetupScreen(roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: PokiColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: PokiColors.backgroundOf(context),
        foregroundColor: PokiColors.textOf(context),
        elevation: 0,
        title: Text(
          'Oyun Odası 🎮',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: GameLobbyService.instance,
          builder: (context, _) {
            final activeQuiz = GameLobbyService.instance.activeQuizInvite;
            final activePuzzle = GameLobbyService.instance.activePuzzleInvite;
            final hasActive = activeQuiz != null || activePuzzle != null || activeCanvas != null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // ─── 1. Bölüm: Aktif / Bekleyen Oyunlar ───
                Row(
                  children: [
                    Text(
                      'Aktif Oyunlar',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CANLI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (activeQuiz != null) ...[
                  _ActiveInviteCard(
                    invite: activeQuiz,
                    onJoin: () => _joinQuiz(activeQuiz),
                  ),
                  const SizedBox(height: 12),
                ],

                if (activePuzzle != null) ...[
                  _ActivePuzzleInviteCard(
                    invite: activePuzzle,
                    onJoin: () => _joinPuzzle(activePuzzle),
                  ),
                  const SizedBox(height: 12),
                ],
                if (activeCanvas != null) ...[
                  _ActiveCanvasInviteCard(
                    invite: activeCanvas,
                    onJoin: () => _joinCanvas(activeCanvas),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!hasActive)
                  PokiCard(
                    color: PokiColors.surfaceOf(context),
                    child: Row(
                      children: [
                        const Text('💤', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Şu an bekleyen oyun yok',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Aşağıdan bir oyun seçip ilk sen başlatabilirsin 🐾',
                                style: textTheme.bodySmall?.copyWith(
                                  color: PokiColors.textOf(context)
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // ─── 2. Bölüm: Yeni Oyun Başlat ───
                Text(
                  'Yeni Oyun Başlat',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // Kart A: Poki Quiz
                _GameLauncherCard(
                  emoji: '🧠',
                  title: 'Poki Quiz',
                  badge: '2 Kişilik',
                  subtitle:
                      'Aklımı Oku veya Ruh İkizi modunda partnerini ne kadar tanıdığını test et.',
                  buttonLabel: 'Quiz Başlat',
                  color: PokiColors.primary.withOpacity(0.3),
                  onTap: _openQuizLobby,
                ),

                const SizedBox(height: 14),

                // Kart B: Poki Puzzle
                _GameLauncherCard(
                  emoji: '🧩',
                  title: 'Poki Puzzle',
                  badge: 'Birlikte / Yarış',
                  subtitle:
                      'Tatlı kedi resimlerini veya özel bir anınızı birlikte birleştirin.',
                  buttonLabel: 'Puzzle Başlat',
                  color: PokiColors.incomingBubble.withOpacity(0.5),
                  onTap: _openPuzzleSetup,
                ),

                const SizedBox(height: 14),

                // Kart C: İki Pati Bir Tuval (Co-op)
                _GameLauncherCard(
                  emoji: '🐾🎨',
                  title: 'İki Pati Bir Tuval',
                  badge: 'Canlı Birlikte',
                  subtitle:
                      'Partnerinle aynı anda, canlı ve eş zamanlı resim çiz. Fırçalar, renkler ve pati damgaları!',
                  buttonLabel: 'Birlikte Çiz',
                  color: const Color(0xFFE88A9A).withOpacity(0.25),
                  onTap: _openCoopCanvas,
                ),

                const SizedBox(height: 14),

                // Kart D: Poki Tuval (Solo)
                _GameLauncherCard(
                  emoji: '🎨',
                  title: 'Poki Tuval',
                  badge: 'Tek Kişilik',
                  subtitle:
                      'Sessiz, huzurlu ve profesyonel kişisel çizim tuvalin. Zoomlanabilir yüksek çözünürlüklü defter.',
                  buttonLabel: 'Tuvali Aç',
                  color: const Color(0xFFF6D186).withOpacity(0.35),
                  onTap: _openSoloCanvas,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActiveInviteCard extends StatelessWidget {
  const _ActiveInviteCard({
    required this.invite,
    required this.onJoin,
  });

  final QuizInvite invite;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PokiColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PokiColors.primaryButton.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PokiColors.primaryButton.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PokiColors.primaryButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🎮', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${invite.hostNickname} Seni Bekliyor!',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mod: ${invite.config.mode.label} · ${invite.questions.length} Soru',
                      style: textTheme.bodySmall?.copyWith(
                        color: PokiColors.textOf(context).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Hemen Katıl 🚀'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PokiColors.primaryButton,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePuzzleInviteCard extends StatelessWidget {
  const _ActivePuzzleInviteCard({
    required this.invite,
    required this.onJoin,
  });

  final PuzzleInvite invite;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = invite.config.difficulty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧩', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${invite.hostNickname} Puzzle Başlattı!',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.pieceCount} Parça · Mod: ${invite.config.mode.label}',
                      style: textTheme.bodySmall?.copyWith(
                        color: PokiColors.textOf(context).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.extension_rounded),
              label: const Text('Katıl ve Çözmeye Başla 🧩'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameLauncherCard extends StatelessWidget {
  const _GameLauncherCard({
    required this.emoji,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String badge;
  final String subtitle;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PokiCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PokiColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: PokiColors.textOf(context).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: PokiColors.surfaceOf(context),
                foregroundColor: PokiColors.textOf(context),
                elevation: 0,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCanvasInviteCard extends StatelessWidget {
  const _ActiveCanvasInviteCard({
    required this.invite,
    required this.onJoin,
  });

  final CanvasInvite invite;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF48FB1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🎨', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İki Pati Bir Tuval Daveti',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFC2185B),
                      ),
                    ),
                    Text(
                      '${invite.hostNickname} seni birlikte resim çizmeye bekliyor!',
                      style: textTheme.bodySmall?.copyWith(
                        color: PokiColors.textOf(context).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.brush_rounded, size: 18),
              label: const Text('Tuvale Katıl 🐾'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
