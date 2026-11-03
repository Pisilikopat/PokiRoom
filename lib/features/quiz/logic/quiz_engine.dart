// lib/features/quiz/logic/quiz_engine.dart
import '../models/quiz_mode.dart';
import '../models/quiz_question.dart';
import '../models/quiz_side.dart';
import 'quiz_deck.dart';

enum QuizPhase {
  /// Mod A: seçen kişi gerçeğini işaretliyor
  choosing,

  /// Mod A: seçim kilitlendi (gizli), tahmin eden işaretliyor
  guessing,

  /// Mod B: iki taraf da kendi tercihini işaretliyor
  answering,

  /// Sonuç açıldı (tepki animasyonu burada gösterilir, sonra otomatik ilerler)
  revealed,

  /// Tüm sorular bitti
  finished,
}

class QuizRuleException implements Exception {
  const QuizRuleException(this.message);
  final String message;

  @override
  String toString() => 'QuizRuleException: $message';
}

/// Tek bir sorunun sonucu.
class QuizRoundRecord {
  const QuizRoundRecord({
    required this.questionIndex,
    required this.questionId,
    required this.myPick,
    required this.partnerPick,
    required this.matched,
    this.chooser,
    this.pointsAwarded = 0,
  });

  final int questionIndex;
  final String questionId;
  final int myPick;
  final int partnerPick;

  /// Mod A: tahmin doğru mu? Mod B: aynı şıkkı mı seçtiler (Ruh İkizi)?
  final bool matched;

  /// Sadece Mod A: gerçeği seçen taraf
  final QuizSide? chooser;
  final int pointsAwarded;
}

/// Oyun sonu özeti.
class QuizResult {
  const QuizResult({
    required this.mode,
    required this.total,
    required this.matches,
    required this.myPoints,
    required this.partnerPoints,
    required this.records,
  });

  final QuizMode mode;
  final int total;

  /// Mod A: doğru tahmin sayısı. Mod B: Ruh İkizi sayısı.
  final int matches;
  final int myPoints;
  final int partnerPoints;
  final List<QuizRoundRecord> records;

  /// Uyum yüzdesi (0-100)
  int get percent => total == 0 ? 0 : (matches * 100 / total).round();
  int get patiPoints => myPoints + partnerPoints;
  int get soulmates => matches;
  int get opposites => total - matches;
}

/// Saf Dart oyun kuralları (Flutter'a bağımlı değil, test edilebilir).
///
/// Gizli bilgi desteği: Gerçek iki cihazlı oyunda karşı tarafın seçimi, sonuç açılana kadar
/// bilinmez. Bu yüzden kilitleme olayları `option` OLMADAN da uygulanabilir
/// (örn. `lockChoice(partner)`), seçim sonradan `reveal` / `revealPick` ile gelir.
/// Tek cihazlı simülasyonda `option` baştan verilir ve sonuç hemen çözülür.
class QuizEngine {
  QuizEngine({
    required this.mode,
    required this.deck,
    QuizSide starter = QuizSide.me,
  })  : _chooser = starter,
        _phase = mode == QuizMode.readMyMind
            ? QuizPhase.choosing
            : QuizPhase.answering;

  /// Doğru tahmin başına verilen Pati Puanı
  static const int pointsPerHit = 10;

  final QuizMode mode;
  final QuizDeck deck;

  QuizPhase _phase;
  int _index = 0;
  QuizSide _chooser;

  // Mod A (soru başına)
  bool _choiceLocked = false;
  int? _chooserPick;
  int? _guessPick;

  // Mod B (soru başına)
  bool _myLocked = false;
  bool _partnerLocked = false;
  int? _myPick;
  int? _partnerPick;

  final List<QuizRoundRecord> _records = [];
  QuizRoundRecord? _lastRecord;
  int _myPoints = 0;
  int _partnerPoints = 0;

  // ------------------------------------------------------------- okuma

  QuizPhase get phase => _phase;
  int get index => _index;
  int get total => deck.length;
  QuizQuestion get question => deck.questions[_index];

  /// Sadece Mod A: bu sorunun gerçeğini seçen taraf (Mod B'de null).
  QuizSide? get chooser => mode == QuizMode.readMyMind ? _chooser : null;
  QuizSide? get guesser => chooser?.other;

  QuizRoundRecord? get lastRecord => _lastRecord;
  List<QuizRoundRecord> get records => List.unmodifiable(_records);

  int get myPoints => _myPoints;
  int get partnerPoints => _partnerPoints;
  int get patiPoints => _myPoints + _partnerPoints;

  /// Şimdiye kadar tutan tahmin / Ruh İkizi sayısı
  int get matchesSoFar => _records.where((r) => r.matched).length;
  int get opposesSoFar => _records.length - matchesSoFar;

  /// [side] bu soruda kilitleme yaptı mı?
  bool hasLocked(QuizSide side) {
    if (mode == QuizMode.readMyMind) {
      return side == _chooser ? _choiceLocked : _guessPick != null;
    }
    return side == QuizSide.me ? _myLocked : _partnerLocked;
  }

  /// Şu an [side]'ın hamle yapması bekleniyor mu?
  bool canAct(QuizSide side) {
    switch (_phase) {
      case QuizPhase.choosing:
        return mode == QuizMode.readMyMind && side == _chooser;
      case QuizPhase.guessing:
        return mode == QuizMode.readMyMind &&
            side == _chooser.other &&
            _guessPick == null;
      case QuizPhase.answering:
        return mode == QuizMode.soulmates && !hasLocked(side);
      case QuizPhase.revealed:
      case QuizPhase.finished:
        return false;
    }
  }

  QuizResult? get result {
    if (_phase != QuizPhase.finished) return null;
    return QuizResult(
      mode: mode,
      total: total,
      matches: matchesSoFar,
      myPoints: _myPoints,
      partnerPoints: _partnerPoints,
      records: records,
    );
  }

  // --------------------------------------------------------- Mod A hamleleri

  /// Seçen taraf gerçeğini kilitler. [option] yalnızca kendi cihazında/simülasyonda verilir.
  void lockChoice(QuizSide side, {int? option}) {
    _requireMode(QuizMode.readMyMind);
    _requirePhase(QuizPhase.choosing, 'Şu an seçim aşaması değil');
    if (side != _chooser) throw const QuizRuleException('Sıra bu oyuncuda değil');
    if (option != null) _checkOption(option);
    _chooserPick = option;
    _choiceLocked = true;
    _phase = QuizPhase.guessing;
  }

  /// Tahmin eden taraf tahminini kilitler. Seçilen gerçek biliniyorsa sonuç hemen çözülür.
  void lockGuess(QuizSide side, int option) {
    _requireMode(QuizMode.readMyMind);
    _requirePhase(QuizPhase.guessing, 'Şu an tahmin aşaması değil');
    if (side != _chooser.other) {
      throw const QuizRuleException('Sıra bu oyuncuda değil');
    }
    if (_guessPick != null) {
      throw const QuizRuleException('Tahmin zaten kilitlendi');
    }
    _checkOption(option);
    _guessPick = option;
    if (_chooserPick != null) _resolveMind();
  }

  /// Seçen tarafın gizli gerçeği açıklanır (tahmin kilitlendikten sonra).
  void reveal(int chooserPick) {
    _requireMode(QuizMode.readMyMind);
    _requirePhase(QuizPhase.guessing, 'Açıklanacak bir tahmin yok');
    if (_guessPick == null) {
      throw const QuizRuleException('Tahmin henüz kilitlenmedi');
    }
    if (_chooserPick != null) {
      throw const QuizRuleException('Gerçek zaten biliniyor');
    }
    _checkOption(chooserPick);
    _chooserPick = chooserPick;
    _resolveMind();
  }

  void _resolveMind() {
    final hit = _chooserPick == _guessPick;
    final guesser = _chooser.other;
    if (hit) {
      if (guesser == QuizSide.me) {
        _myPoints += pointsPerHit;
      } else {
        _partnerPoints += pointsPerHit;
      }
    }
    final myPick = _chooser == QuizSide.me ? _chooserPick! : _guessPick!;
    final partnerPick = _chooser == QuizSide.me ? _guessPick! : _chooserPick!;
    _finishRound(QuizRoundRecord(
      questionIndex: _index,
      questionId: question.id,
      myPick: myPick,
      partnerPick: partnerPick,
      matched: hit,
      chooser: _chooser,
      pointsAwarded: hit ? pointsPerHit : 0,
    ));
  }

  // --------------------------------------------------------- Mod B hamleleri

  /// Taraf kendi cevabını kilitler. [option] yalnızca kendi cihazında/simülasyonda verilir.
  void lockAnswer(QuizSide side, {int? option}) {
    _requireMode(QuizMode.soulmates);
    _requirePhase(QuizPhase.answering, 'Şu an cevap aşaması değil');
    if (hasLocked(side)) throw const QuizRuleException('Cevap zaten kilitlendi');
    if (option != null) _checkOption(option);
    if (side == QuizSide.me) {
      _myLocked = true;
      _myPick = option;
    } else {
      _partnerLocked = true;
      _partnerPick = option;
    }
    _tryResolveSoulmates();
  }

  /// Daha önce seçimsiz kilitlenen tarafın seçimi açıklanır.
  void revealPick(QuizSide side, int option) {
    _requireMode(QuizMode.soulmates);
    _requirePhase(QuizPhase.answering, 'Açıklanacak bir cevap yok');
    if (!hasLocked(side)) {
      throw const QuizRuleException('Bu taraf henüz kilitlemedi');
    }
    _checkOption(option);
    if (side == QuizSide.me) {
      _myPick ??= option;
    } else {
      _partnerPick ??= option;
    }
    _tryResolveSoulmates();
  }

  void _tryResolveSoulmates() {
    if (!(_myLocked && _partnerLocked)) return;
    final mine = _myPick;
    final theirs = _partnerPick;
    if (mine == null || theirs == null) return;
    _finishRound(QuizRoundRecord(
      questionIndex: _index,
      questionId: question.id,
      myPick: mine,
      partnerPick: theirs,
      matched: mine == theirs,
    ));
  }

  // ------------------------------------------------------------- akış

  /// Sonuç gösterildikten sonra sıradaki soruya (ya da bitişe) geçer.
  void advance() {
    _requirePhase(QuizPhase.revealed, 'Henüz sonuç açılmadı');
    if (_index + 1 >= deck.length) {
      _phase = QuizPhase.finished;
      return;
    }
    _index++;
    if (mode == QuizMode.readMyMind) _chooser = _chooser.other; // roller değişir
    _choiceLocked = false;
    _chooserPick = null;
    _guessPick = null;
    _myLocked = false;
    _partnerLocked = false;
    _myPick = null;
    _partnerPick = null;
    _phase = mode == QuizMode.readMyMind
        ? QuizPhase.choosing
        : QuizPhase.answering;
  }

  void _finishRound(QuizRoundRecord record) {
    _records.add(record);
    _lastRecord = record;
    _phase = QuizPhase.revealed;
  }

  // ------------------------------------------------------------ doğrulama

  void _requireMode(QuizMode expected) {
    if (mode != expected) {
      throw const QuizRuleException('Bu hamle bu oyun modunda geçersiz');
    }
  }

  void _requirePhase(QuizPhase expected, String message) {
    if (_phase != expected) throw QuizRuleException(message);
  }

  void _checkOption(int option) {
    if (option < 0 || option >= question.options.length) {
      throw const QuizRuleException('Geçersiz şık');
    }
  }
}
