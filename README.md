# BloomHabit 🌱 — Botanik Alışkanlık Takip Uygulaması

> **"Her gün bir tohum ek, alışkanlıklarını sula, bahçeni yeşert."**
> BloomHabit, pozitif alışkanlıklar kazandıran ve kötü alışkanlıkları bıraktıran, botanik metaforla zenginleştirilmiş Flutter mobil uygulamasıdır.

---

## 🌿 Özellikler

1. **Botanik Büyüme & Canlı Bitki (Terrarium):**
   - 30 günlük döngü: `Tohum (0. Gün) → Filiz (1-3. Gün) → Sap (4-10. Gün) → Tomurcuk (11-20. Gün) → Çiçek (21-29. Gün)`.
   - Fizik tabanlı rüzgarla sallanma animasyonu.
   - **Solgunluk Uyarısı:** Dün hiçbir alışkanlık sulanmadığında bitki desatüre olur ve solgun görünür.
   - Tamamlanan her 30 günlük döngü kalıcı bir çiçek olarak **Bahçe Ekranına** eklenir.

2. **Günün AI Kehaneti (3D Flip Kartlar):**
   - Günde 1 kez seçim hakkı.
   - 3 boyutlu kart çevirme animasyonu (`Transform` + matrix4).
   - Firebase AI Logic (Gemini Flash) ile kullanıcının hedeflerine özel Türkçe botanik tavsiyeler + offline yedek kehanet havuzu.

3. **Alışkanlık Yönetimi & Ritüeller:**
   - **Kazanım (Build):** Tek dokunuşla sulama, alevli aktif zincir sayacı, hedef ve saat bilgisi.
   - **Bırakma (Quit):** Canlı saniye sayacı (`12g 04s 33d 09sn Temiz`), parasal tasarruf ve içilmeyen adet hesabı, onaylı "Kaydım" butonu.
   - **Filtreler:** Tümü, Kazanım 🌱, Bırakma 🚭, Arşivlenenler 🗄.
   - **Soft Delete & Geri Yükleme:** Onaylı silme ve 5 saniyelik SnackBar ile geri alma; arşiv sekmesinden tek dokunuşla bahçeye geri yükleme.

4. **Derin Analiz & Dinamik İrade Grafikleri:**
   - **Güç Skoru İlerlemesi:** Her temiz gün +1, kaçırılan gün −1 (taban 0). Son 30 günlük yumuşak eğrili `LineChart`.
   - **Haftalık Sürdürülebilirlik:** Son 8 haftanın tamamlama sütunları (`BarChart`).
   - **30 Günlük Terrarium Matrisi:** 6 kolonlu numaralı renk yoğunluk ızgarası.
   - **Yıllık Zincir Takvimi:** Elle çizilmiş kırmızı X'ler, art arda gelen günlerde haftalık zincir bağlantı halkaları, gün detay bottom sheet'i.
   - **Birleşik Analiz Sekmesi:** Tüm alışkanlıkların tek potada birleştiği güç skoru, haftalık sürdürülebilirlik ve genel bahçe yıllık zincir takvimi.

5. **Kalkan (Joker) & Otomatik Koruma:**
   - Uygulama açılışında günde 1 kez otomatik denetim (`lastShieldCheck`).
   - Dünü kaçırılmış ve zinciri ≥ 3 olan alışkanlıklar en uzun zincirden başlanarak kalkanla korunur (`frozen`).

6. **Kilometre Taşları & Kutlamalar:**
   - 7, 14, 21, 30 günlük zincir kilometre taşlarında ekranın üstünden dökülen konfeti şöleni (`confetti`) ve haptic titreşim geri bildirimi.

7. **Profil, Bahçıvan Kimliği & Koyu Tema:**
   - Karakter seçimi (6 özgün bahçıvan emojisi/rengi).
   - Firestore transaction ile korunan benzersiz kullanıcı adı (`usernames/{lower}`).
   - Gerçek verilerden hesaplanan rozetler (İlk Tohum, 7 Günlük Alev, Kalkan Ustası, 30 Gün Çiçeği, 100 Günlük Efsane).
   - Tek dokunuşla Aydınlık / Karanlık Tema geçişi (`ThemeMode`).

8. **Kişiselleştirilebilir Yerel Bildirimler:**
   - Saat ve gün bazında tekrarlayan yerel sulama hatırlatıcıları (`flutter_local_notifications`).
   - Profil ayarlarından genel bildirim anahtarı.

---

---

## 🚀 Kurulum ve Başlangıç

### 1. Gereksinimler
- Flutter SDK (3.x veya üzeri)
- Dart SDK
- Android Studio / Xcode & iOS Simulator

### 2. Bağımlılıkları Yükleme ve Pod Kurulumu
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3. Uygulamayı Çalıştırma
Uygulama tüm verilerini cihazda yerel Hive kutularında saklar (hesap/şifre girişi gerekmez).
Gemini Flash AI motivasyon ve relapse destek özelliklerini aktif etmek için `GEMINI_API_KEY` dart-define ile verilir (anahtar verilmezse veya istek başarısız olursa uygulama sessizce yerel zengin havuzuna düşer):

```bash
flutter run -d "iPhone 18 Pro" --dart-define=GEMINI_API_KEY=...
```

### 4. Testleri Çalıştırma
```bash
flutter analyze
flutter test
```

---

## 📂 Klasör Yapısı (Feature-First)

```
lib/
├── main.dart                      # Uygulama giriş noktası, HiveService ve Bildirim başlatma
├── app.dart                       # MaterialApp.router, ScreenUtilInit ve Tema sağlayıcı
├── core/
│   ├── router/app_router.dart     # GoRouter konfigürasyonu ve karşılama yönlendirme kuralları
│   ├── theme/                     # AppTheme, AppColors, ThemeModeNotifier
│   ├── utils/date_key.dart        # yyyy-MM-dd tarih anahtarı yardımcıları
│   └── widgets/                   # BloomCard, AppShell, StatTile, ConfettiOverlay vb.
├── data/
│   ├── models/                    # AppUser, Habit, HabitLog, DailyMotivation, SupportMessage
│   ├── repositories/              # UserRepository, HabitRepository, MotivationRepository (Hive tabanlı)
│   ├── services/hive_service.dart # profile, habits, logs, motivation, settings kutuları yönetimi
│   └── sources/                   # GeminiSupportMessageSource, SupportMessageSource
├── domain/
│   ├── habit_stats.dart           # Streak, güç skoru, yüzdeler, birleşik analiz saf fonksiyonları
│   └── plant_stage.dart           # Bitki aşaması, döngü hesabı, solgunluk kontrolü
├── features/
│   ├── welcome/                   # Karşılama ekranı ("Bahçeni Kur 🌱" butonu)
│   ├── onboarding/                # Karakter seçimi ve yerel kullanıcı adı kaydı
│   ├── home/                      # Bitki kartı, motivasyon kartları, ritüel listesi, yeni alışkanlık
│   ├── habits/                    # Filtreli alışkanlıklar listesi ve arşivden geri yükleme
│   ├── habit_detail/              # İrade grafiği, haftalık sütunlar, terrarium ve yıllık zincir
│   ├── analytics/                 # Birleşik güç skoru, haftalık sürdürülebilirlik, genel yıllık zincir
│   ├── garden/                    # 30 gün sonrası açan çiçekler bahçesi
│   ├── relapse/                   # Relapse destek kartı ve bottom sheet
│   └── profile/                   # Karakter & kullanıcı adı, rozetler, koyu mod, "Bahçeyi Sıfırla"
└── services/
    ├── ai_service.dart            # Gemini Flash REST API servisi (http)
    ├── relapse_support_service.dart
    └── notification_service.dart  # flutter_local_notifications yerel sulama hatırlatıcı servisi
```

---

## 🛡️ Güvenlik ve Mimari Prensipleri

- **Tamamen Yerel Veri (Offline-First):** Bütün veriler `hive_ce` kutularında Map/JSON formatında saklanır. Harici sunucu bağımlılığı yoktur.
- **Kutular Doğrudan Çağrılmaz:** Widget → Provider → Repository → HiveService.
- **İş Kuralları Saf Fonksiyonlardır:** Bütün zincir, yüzde, güç skoru ve kalkan hesapları `lib/domain/` altında bağımsız olarak yazılmış ve birim testlerle doğrulanmıştır.
- **Gizli Anahtar Bulunmaz:** Gemini REST API anahtarı koda, dosyalara veya repoya asla yazılmaz; sadece derleme zamanında `const String.fromEnvironment('GEMINI_API_KEY')` ile alınır.

