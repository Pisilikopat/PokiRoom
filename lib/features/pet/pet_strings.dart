// lib/features/pet/pet_strings.dart

class PetStrings {
  const PetStrings._();

  static const title = 'Ortak Kedi · Mırnav';
  static const defaultPetName = 'Mırnav';
  static String subtitle(String user1, String user2) => '$user1 & $user2 ortak kedi odası';
  static const defaultSubtitle = 'İkinizin ortak sanal kedi odası';

  // Butonlar
  static const feedButton = 'Besle';
  static const petButton = 'Sev';
  static const sleepButton = 'Uyut';
  static const wakeButton = 'Uyandır';
  static const historyButton = 'İşlem Geçmişi';

  // Stat başlıkları
  static const hunger = 'Tokluk';
  static const affection = 'Mutluluk';
  static const energy = 'Enerji';

  // Eylem devam ediyor (Progress Bar)
  static const feedingProgress = '🍖 Besleniyor... Hapur hupur!';
  static const pettingProgress = '🤚 Seviliyor... Mrrr~ 💕';
  static const sleepingNotice = 'Şşşt, mışıl mışıl uyuyor...';

  // Balonlar & Tepkiler
  static const meowIdle = 'Miyav~ 🐾';
  static const meowWake = 'Miyav~ ☀️';
  static const hungryRumble = 'gurr... 😿';
  static const sleepyYawn = 'Haaauvv 💤';
  static const purr = 'Mrrr~ 💖';

  // Başucu Notu
  static const sleepDialogTitle = 'Kediyi Uyut 🌙';
  static const sleepDialogHint = 'İyi geceler canım, kediyi uyuttum...';
  static const sleepDialogConfirm = 'Mışıl Mışıl Uyut 💤';
  static const cancel = 'Vazgeç';
  static const bedsideNotePrefix = '🌙 Başucu Notu:';

  // Son işlem formatı
  static String lastActionBy(String actor, String action, String timeAgo) {
    return 'Son işlem: $actor $timeAgo onu $action 🤍';
  }
}
