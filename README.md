# PokiRoom 🐾

İki kişilik, sevimli kedi temalı, 1'e 1 kilitli özel sohbet ve oda uygulaması.

---

## 🌟 Özellikler
- **Boş Cep (Empty Pocket):** Bağlantı yokken bekleyen istekleri ve PokiCode'u gösteren sakin ekran.
- **PokiCode:** Kullanıcıya özel kod (`#POKI-XXXX`) ile odaya tıklatıp (`send_knock`) bağlantı kurma.
- **PokiRoom (Canlı Oda):** 
  - İki kedi ve online durumuna göre yanan masa lambası.
  - PokiPet streak (günlük seri) sayacı (🌱 -> 🌿 -> 🪴 -> 🌸).
  - Canlı yazıyor animasyonu (üç zıplayan pati).
  - **Buğulu Mesaj (Foggy Message):** Parmağınızla silerek (kazıyarak) okunan gizli mesajlar.
  - **Poki-Poke ("Seni Düşünüyorum"):** Ekranda uçuşan kalpler efekti.

---

## 🛠️ Supabase Kurulumu

1. [Supabase](https://supabase.com) üzerinde bir proje oluşturun.
2. **Authentication > Providers:** "Allow anonymous sign-ins" (Anonim Giriş) seçeneğini açın.
3. **Database > SQL Editor:** `supabase/step2_additions.sql` ve `supabase/step3_additions.sql` dosyalarındaki sorguları sırasıyla çalıştırın.
4. **Project Settings > API:** `Project URL` ve `anon public key` bilgilerinizi alın.

---

## 🚀 Canlıya Alma (Online Publish)

### Yöntem 1: GitHub Pages ile Ücretsiz Canlı Yayın (Önerilen)
1. Bu projeyi bir GitHub deposuna yükleyin (`git push`).
2. GitHub reponuzda **Settings > Pages** sekmesine gidin:
   - **Source:** "GitHub Actions" olarak seçin.
3. Reponuzda **Settings > Secrets and variables > Actions** sekmesine gidin:
   - `SUPABASE_URL`: Supabase proje URL'niz
   - `SUPABASE_ANON_KEY`: Supabase anon anahtarınız
4. Kod yüklendiğinde GitHub Actions otomatik olarak Flutter'ı bulutta derler ve web sitenizi `https://<kullanici-adi>.github.io/<repo-adi>/` adresinde yayına alır!
5. Ayrıca **Actions** sekmesinden telefonunuza kurabileceğiniz **Android APK** dosyasını da indirebilirsiniz.

### Yöntem 2: Google Project IDX ile Tarayıcıda Önizleme
1. [idx.google.com](https://idx.google.com) adresine gidin.
2. GitHub reponuzu bağlayın.
3. Tarayıcınızda sıfır kurulumla emülatörde ve webde anında çalıştırın.
