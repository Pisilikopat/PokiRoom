// lib/features/quiz/logic/quiz_verdict.dart
import '../models/quiz_mode.dart';
import 'quiz_engine.dart';

/// Uyum yüzdesine göre sertifika başlığı ve yorumu.
/// (Adım 6'da daha zengin/komik yorum havuzuyla genişletilecek.)
class QuizVerdict {
  const QuizVerdict(this.title, this.comment);

  final String title;
  final String comment;

  static QuizVerdict of(QuizResult r) {
    final p = r.percent;
    if (r.mode == QuizMode.readMyMind) {
      if (p >= 90) {
        return const QuizVerdict('Zihin Okuyucular 🔮',
            'Birbirinizin aklını okuyorsunuz, sanki aynı beyni paylaşıyorsunuz!');
      }
      if (p >= 70) {
        return const QuizVerdict('Neredeyse Telepati 💫',
            'Çok iyi tanıyorsunuz birbirinizi, ufak sürprizler hâlâ var.');
      }
      if (p >= 40) {
        return const QuizVerdict('İyi Gidiyorsunuz 🌱',
            'Temel sağlam! Birbirinizi keşfetmeye devam edin.');
      }
      return const QuizVerdict('Keşfedilecek Çok Şey Var 🧭',
          'Hiç sorun değil, yeni sorular yeni sohbetler demek!');
    }
    if (p >= 80) {
      return const QuizVerdict('Ruh İkizisiniz 💖',
          'Neredeyse her şeyde aynı şıkkı seçtiniz. Bu uyum nadir!');
    }
    if (p >= 50) {
      return const QuizVerdict('Uyumlu Bir İkili 🌿',
          'Ortak noktalarınız çok, farklarınız da tatlı.');
    }
    if (p >= 20) {
      return const QuizVerdict('Zıt Kutuplar Çeker 🧲',
          'Farklı seçimler, ilginç sohbetlerin başlangıcı.');
    }
    return const QuizVerdict('Tamamen Zıt Kutuplar 🐱',
        'Bu kadar farklı olup bu kadar iyi anlaşmak da bir yetenek!');
  }
}
