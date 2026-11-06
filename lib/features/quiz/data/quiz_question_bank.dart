// lib/features/quiz/data/quiz_question_bank.dart
import '../models/quiz_category.dart';
import '../models/quiz_question.dart';

/// Soru kütüphanesi İSKELETİ: kategori başına birkaç örnek soru.
/// Zengin kütüphane (kategori başına ~20 soru) bir sonraki adımda eklenecek.
class QuizQuestionBank {
  QuizQuestionBank._();

  /// Telepati / Ortak Frekans modu soru havuzu (2 seçenekli anlık durumlar ve ikilemler)
  static const List<QuizQuestion> telepathyPool = [
    QuizQuestion(
      id: 't1',
      text: "Şu an canın ne çekiyor?",
      options: ["Kahve & battaniye altında dizi keyfi ☕🛋️", "Temiz havada gece yürüyüşü 🌙🚶"],
    ),
    QuizQuestion(
      id: 't2',
      text: "Poki bir kedi olsa ilk ne yapardı?",
      options: ["Kutunun içine girip mırıldardı 📦🐾", "Eline vurup masadaki bardağı devirirdi 🥛😼"],
    ),
    QuizQuestion(
      id: 't3',
      text: "Hafta sonu sabahı için mükemmel plan:",
      options: ["Öğlene kadar yatakta tembellik 🛏️😴", "Erken kalkıp güzel bir kahvaltı hazırlamak 🍳🥞"],
    ),
    QuizQuestion(
      id: 't4',
      text: "Birlikte tatile çıksanız nereyi seçerdiniz?",
      options: ["Orman içinde izole ve huzurlu bir dağ evi 🌲🏡", "Dalga sesleriyle uyanılan deniz kenarı 🌊🏖️"],
    ),
    QuizQuestion(
      id: 't5',
      text: "Film izlerken partnerin uyuyakalırsa:",
      options: ["Üstünü örtüp sessizce izlemeye devam etmek 🛋️🤫", "Hafifçe dürtüp 'Uyumadın değil mi!' diye sataşmak 😜"],
    ),
    QuizQuestion(
      id: 't6',
      text: "Tek bir süper gücünüz olsa:",
      options: ["İstediğin yere anında ışınlanmak ⚡✨", "Zamanı durdurup anın tadını çıkarmak ⏳⏸️"],
    ),
    QuizQuestion(
      id: 't7',
      text: "Gece yarısı gelen ani açlık krizi:",
      options: ["Gece 2'de makarna / noodle haşlamak 🍜😋", "Çikolata & cips zulalarını patlatmak 🍫🍿"],
    ),
    QuizQuestion(
      id: 't8',
      text: "Birlikte yemek yaparken kim şef?",
      options: ["Ben şef olurum, sen tarifleri & malzemeleri hazırlarsın 👨‍🍳", "Birlikte doğrar, birlikte karıştırırız! 🥗👩‍🍳"],
    ),
    QuizQuestion(
      id: 't9',
      text: "Kusursuz bir akşam randevusu:",
      options: ["Evde loş ışıkta pijama partisi & derin sohbet 🕯️🍕", "Şık giyinip dışarıda tatlı bir restorana gitmek 🍷✨"],
    ),
    QuizQuestion(
      id: 't10',
      text: "Birbirinize hediye seçecek olsanız:",
      options: ["Kendi ellerinle yaptığın manevi bir hatıra 🎨💌", "Uzun zamandır çok istediği o özel eşya 🎁🛍️"],
    ),
    QuizQuestion(
      id: 't11',
      text: "Yağmurlu bir pazar günü:",
      options: ["Sıcak çikolatayla kitap & oyun keyfi ☕🎮", "Yağmur altında şemsiyesiz romantik bir yürüyüş ☔🌧️"],
    ),
    QuizQuestion(
      id: 't12',
      text: "Tatlı bir inatlaşma çıktığında:",
      options: ["Sarılıp hemen konuyu tatlıya bağlamak 🤗💕", "Sonuna kadar 'Ben haklıydım!' diye şakalaşmak 😼👅"],
    ),
    QuizQuestion(
      id: 't13',
      text: "Telefonunun şarjı %5 kalsa:",
      options: ["Umursamayıp son ana kadar kullanmaya devam etmek 📱💀", "Hemen panikle prize & şarj aletine koşmak 🔌🏃"],
    ),
    QuizQuestion(
      id: 't14',
      text: "Birlikte oyun oynarken tarzınız:",
      options: ["Kazanmak için tatlı bir hırs & taktik! 🏆🔥", "Sadece eğlenmek ve birbirine takılmak 🎲😹"],
    ),
    QuizQuestion(
      id: 't15',
      text: "Yolda pofuduk bir sokak kedisi görseniz:",
      options: ["Hemen çömelip sevmek ve mırıldatmak 🐈😻", "Fotoğrafını çekip 'Bunu sahiplenelim mi!' demek 📸🐾"],
    ),
    QuizQuestion(
      id: 't16',
      text: "Yolculukta müzik çalma listesi:",
      options: ["Akustik, sakin ve huzurlu melodiler 🎶🌿", "Enerjik, bağıra çağıra eşlik edilecek şarkılar 🎤🚗"],
    ),
    QuizQuestion(
      id: 't17',
      text: "Sabah alarmı çaldığında tepkin:",
      options: ["İlk çalışta fırlayıp güne enerjik başlamak ⏰⚡", "'5 dakika daha' diyerek 4 kez ertelemek 🛌😴"],
    ),
    QuizQuestion(
      id: 't18',
      text: "Lunaparkta ilk bineceğiniz şey:",
      options: ["Roller coaster / en çılgın hızlı tren! 🎢😱", "Dönme dolap / manzarayı izleyip sarılmak 🎡💖"],
    ),
    QuizQuestion(
      id: 't19',
      text: "Ani bir tatlı krizinde hangisi?",
      options: ["Sıcak ve bol çikolatalı sufle / brownie 🍫🌋", "Hafif ve ferahlatıcı dondurma / cheesecake 🍦🍓"],
    ),
    QuizQuestion(
      id: 't20',
      text: "Birbirinize sarılırken nasıl olmalı?",
      options: ["Sımsıkı ve nefesi kesilecek kadar içten! 🫂💞", "Yumuşacık, saatlerce öyle kalacak gibi huzurlu ☁️🌸"],
    ),
    QuizQuestion(
      id: 't21',
      text: "Gelecekteki hayal evinizin olmazsa olmazı:",
      options: ["Geniş bir teras & rengarenk çiçekler 🌿🌺", "Dev bir kütüphane & cozy okuma/oyun köşesi 📚🛋️"],
    ),
    QuizQuestion(
      id: 't22',
      text: "Partnerinizin çocukluk fotoğrafını görseniz:",
      options: ["Yanaklarını sıkıp 'Ayy ne tatlıymışsın!' demek 🥺🤏", "Komik saç modeline kahkahalarla gülmek 😂📸"],
    ),
    QuizQuestion(
      id: 't23',
      text: "Market alışverişine çıktığınızda:",
      options: ["Listeye sadık kalıp 10 dakikada çıkmak 📝🛒", "Abur cubur reyonunda yarım saat oyalanmak 🍪🤤"],
    ),
    QuizQuestion(
      id: 't24',
      text: "İkinizden kim daha unutkan?",
      options: ["Kesinlikle ben, bazen aklım beş karış havada! 🙈💭", "Sensin tabii ki, anahtarlarını bile zor buluyorsun! 🔑😹"],
    ),
    QuizQuestion(
      id: 't25',
      text: "Birlikte uzun bir araba yolculuğunda:",
      options: ["DJ olup bütün şarkılara avaz avaz eşlik etmek 🎵🕺", "Pencereden manzarayı izleyip derin sohbetlere dalmak 🛣️🌅"],
    ),
    QuizQuestion(
      id: 't26',
      text: "Issız bir adaya düşseniz yanınıza hangisi?",
      options: ["Sınırsız lezzetli atıştırmalık & çikolata deposu 🍫🍕", "Yumuşacık dev bir yatak & cozy yastıklar 🛏️😴"],
    ),
    QuizQuestion(
      id: 't27',
      text: "Birbirinizi özlediğinizde ilk yapılan:",
      options: ["Hemen arayıp sesini duymak 📞🥰", "Fotoğraflara bakıp tatlı mesajlar atmak 💌📸"],
    ),
    QuizQuestion(
      id: 't28',
      text: "Yemek siparişi vereceksiniz:",
      options: ["Pizza & çıtır patates & kola 🍕🍟", "Hamburger & soğan halkası & tatlı 🍔🍩"],
    ),
    QuizQuestion(
      id: 't29',
      text: "Biri sizi sinirlendirdiğinde:",
      options: ["Sessizce somurtup sıcacık bir sarılma beklemek 😾🥺", "Hararetli hararetli anlatıp dedikodusunu yapmak 🗣️🔥"],
    ),
    QuizQuestion(
      id: 't30',
      text: "Günün en sevdiğiniz anı:",
      options: ["Güneşin doğduğu taze sabah saatleri 🌅☕", "Gecenin sessizliği ve ikinizin vakti 🌌🕯️"],
    ),
  ];

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
