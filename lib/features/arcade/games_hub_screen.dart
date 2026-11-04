// lib/features/arcade/games_hub_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/poki_theme.dart';
import '../../data/services/game_lobby_service.dart';
import '../../data/services/room_presence.dart';
import '../../shared/widgets/poki_card.dart';
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
    GameLobbyService.instance.clearInvite();
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
            final activeInvite = GameLobbyService.instance.activeQuizInvite;

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
                    if (activeInvite != null)
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

                if (activeInvite != null)
                  _ActiveInviteCard(
                    invite: activeInvite,
                    onJoin: () => _joinQuiz(activeInvite),
                  )
                else
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

                // Poki Quiz Kartı
                _GameLauncherCard(
                  emoji: '🎯',
                  title: 'Poki Quiz',
                  badge: '2 Mod',
                  subtitle:
                      'Aklımı Oku & Ruh İkizi modlarıyla birbirinizi ne kadar iyi tanıdığınızı test edin.',
                  buttonLabel: 'Quiz Başlat ➔',
                  color: PokiColors.primary.withOpacity(0.25),
                  onTap: _openQuizLobby,
                ),

                const SizedBox(height: 16),

                // Poki Puzzle Kartı
                _GameLauncherCard(
                  emoji: '🧩',
                  title: 'Poki Puzzle',
                  badge: 'Co-Op',
                  subtitle:
                      'Fotoğraflarınızı parçalara bölün ve anılarınızı birlikte birleştirin.',
                  buttonLabel: 'Puzzle Başlat ➔',
                  color: PokiColors.incomingBubbleOf(context).withOpacity(0.4),
                  onTap: _openPuzzleSetup,
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
  const _ActiveInviteCard({required this.invite, required this.onJoin});

  final QuizInvite invite;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PokiCard(
      color: PokiColors.primaryButton.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${invite.hostNickname} Poki Quiz başlattı!',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
