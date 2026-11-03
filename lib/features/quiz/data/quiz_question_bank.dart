// lib/features/quiz/data/quiz_question_bank.dart
import '../models/quiz_category.dart';
import '../models/quiz_question.dart';

/// Soru kütüphanesi İSKELETİ: kategori başına birkaç örnek soru.
/// Zengin kütüphane (kategori başına ~20 soru) bir sonraki adımda eklenecek.
class QuizQuestionBank {
  QuizQuestionBank._();

  static const List<QuizQuestion> sample = [
    // Günlük Alışkanlıklar
    QuizQuestion(
      id: 'd1',
      category: QuizCategory.daily,
      text: 'Sabah uyanınca ilk yaptığım şey hangisi?',
      options: ['Telefona bakmak', 'Kahve/çay yapmak', 'Bir süre daha uyumak', 'Duş almak'],
    ),
    QuizQuestion(
      id: 'd2',
      category: QuizCategory.daily,
      text: 'Hafta sonu en çok nasıl dinlenirim?',
      options: ['Dizi/film maratonu', 'Dışarıda yürüyüş', 'Arkadaşlarla buluşma', 'Evde hiçbir şey yapmamak'],
    ),
    QuizQuestion(
      id: 'd3',
      category: QuizCategory.daily,
      text: 'Gece en çok hangi saatte uyanığım?',
      options: ['23:00 öncesi uyurum', '00:00 civarı', '02:00 gibi', 'Sabaha kadar!'],
    ),
    // Anılar & Geçmiş
    QuizQuestion(
      id: 'm1',
      category: QuizCategory.memories,
      text: 'Çocukken en çok hangisini yapmayı severdim?',
      options: ['Dışarıda oyun oynamak', 'Çizgi film izlemek', 'Kitap okumak', 'Bir şeyler çizmek'],
    ),
    QuizQuestion(
      id: 'm2',
      category: QuizCategory.memories,
      text: 'Bugüne kadarki en güzel tatilim nasıldı?',
      options: ['Deniz kenarı', 'Doğa/kamp', 'Şehir turu', 'Ailemle bir hafta sonu'],
    ),
    QuizQuestion(
      id: 'm3',
      category: QuizCategory.memories,
      text: 'Okul yıllarımda en çok hangi dersi severdim?',
      options: ['Matematik/Fen', 'Edebiyat/Dil', 'Resim/Müzik', 'Beden eğitimi'],
    ),
    // Hayaller & Eğlenceli İkilemler
    QuizQuestion(
      id: 'h1',
      category: QuizCategory.dreams,
      text: 'Bir süper gücüm olsaydı hangisini seçerdim?',
      options: ['Uçmak', 'Zamanı durdurmak', 'Zihin okumak', 'Görünmez olmak'],
    ),
    QuizQuestion(
      id: 'h2',
      category: QuizCategory.dreams,
      text: 'Bir yıl boyunca sadece birini yiyebilsem?',
      options: ['Pizza', 'Makarna', 'Tatlı', 'Kebap'],
    ),
    QuizQuestion(
      id: 'h3',
      category: QuizCategory.dreams,
      text: 'Hayalimdeki yaşam yeri neresi?',
      options: ['Büyük şehir', 'Deniz kenarı', 'Dağ evi', 'Başka bir ülke'],
    ),
  ];
}
