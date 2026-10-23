# BloomHabit — Alışkanlık Takip Uygulaması (project.md)

> Bu dosya coding agent için ana talimat dosyasıdır. Her göreve başlamadan önce bu dosyayı ve ilgili `skills/*.md` dosyasını oku.
> Çalışma süresi çok kısa (~1 saat). **Öncelik: çalışan ana akış. Süsler en son.**

---

## 1. Ürün Özeti

Kullanıcıya pozitif alışkanlık kazandıran (kitap okuma, spor, zayıflama) ve kötü alışkanlık bıraktıran (sigara, alkol) bir Flutter mobil uygulaması.

Temel fikir: Kullanıcı her gün tek dokunuşla alışkanlığını onaylar. Zinciri büyüdükçe ana sayfadaki tohum filize, filiz çiçeğe dönüşür. 30 gün sonunda bahçeye yeni bir çiçek eklenir.

- Platform: **Sadece Android + iOS** (telefon). Web/desktop yok.
- UI dili: **Türkçe**. Kod, değişken, dosya adları: **İngilizce**.
- Bütün telefon boyutlarında responsive (küçük 320dp → büyük 430dp+).

---

## 2. Teknoloji Yığını (KESİN — değiştirme)

| Katman | Seçim |
|---|---|
| Backend / DB | Tamamen cihazda yerel — Hive (`hive_ce`, `hive_ce_flutter`) |
| Auth | Yok (Hesap/şifre/Google girişi yok, yerel profil) |
| Database | Hive Boxes (Map/JSON saklama, codegen / TypeAdapter YOK) |
| AI | Gemini Flash REST API (`http`, `const String.fromEnvironment('GEMINI_API_KEY')`) |
| State management | `flutter_riverpod` (codegen YOK) |
| Routing | `go_router` |
| Grafikler | `fl_chart` |
| Bildirim | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Responsive | `flutter_screenutil` (designSize: 390x844) + `LayoutBuilder` |
| Tarih formatı | `intl` |
| Opsiyonel | `lottie` (sadece kullanıcı dosya verirse), `confetti` |

Paketleri `flutter pub add <paket>` ile en güncel stabil sürümle ekle. Listede olmayan paket eklemeden önce **kullanıcıya sor**.

---

## 3. Klasör Yapısı (feature-first)

```
lib/
  main.dart
  app.dart                      # MaterialApp.router + ScreenUtilInit + theme
  core/
    theme/app_theme.dart
    router/app_router.dart
    utils/date_key.dart         # yyyy-MM-dd yardımcıları
    widgets/                    # ortak butonlar, boş durum, loading
  data/
    models/                     # AppUser, Habit, HabitLog, DailyMotivation
    repositories/               # auth_repository, user_repository, habit_repository, motivation_repository
  domain/
    habit_stats.dart            # SAF fonksiyonlar: streak, score, yüzdeler, yıllık takvim
    plant_stage.dart            # SAF fonksiyon: gün → bitki aşaması
  features/
    auth/                       # login, register
    onboarding/                 # character_select, username
    home/                       # plant, motivation cards, habit list, add sheet
    habit_detail/               # grafikler + yıllık zincir takvimi
    garden/                     # 30 gün sonrası bahçe ekranı
    profile/
  services/
    notification_service.dart
    ai_service.dart
test/
  domain/                       # habit_stats ve plant_stage testleri
```

Kural: **Widget'lar Hive kutularını doğrudan çağırmaz.** Widget → Provider → Repository → HiveService.

---

## 4. Veri Modeli (Hive Kutuları)

Tüm veriler Hive kutularında Map/JSON olarak tutulur (`build_runner` / `TypeAdapter` kullanılmaz):

```
profile (tek kayıt, key: "current")
  username: String
  characterId: String?          // "char_1" ... "char_6"
  gardenStartDate: String (ISO8601)
  shields: int
  lastShieldCheck: String? (ISO8601)
  themeMode: String?            // "system" | "light" | "dark"

habits (key: habitId)
  id: String
  title: String
  type: "build" | "quit"        // build: kazanılacak, quit: bırakılacak
  icon: String                  // emoji veya ikon adı
  color: int                    // ARGB integer
  startDate: String (ISO8601)
  lastRelapseAt: String? (ISO8601)
  dailyCost: double?
  targetPerWeek: int?
  reminderTime: "HH:mm"?
  reminderDays: List<int>
  isDeleted: bool               // soft delete
  createdAt: String (ISO8601)

logs (key: "habitId|yyyy-MM-dd")
  date: "yyyy-MM-dd"
  status: "done" | "relapse"
  count: int?
  at: String (ISO8601)
  support: Map<String, dynamic>? // Relapse destek mesajı önbelleği

motivation (key: "yyyy-MM-dd")
  options: List<Map<String, dynamic>> // 3 seçenek: [{id, text, tone}]
  selectedIndex: int?                 // null = henüz seçilmedi
  selectedAt: String? (ISO8601)

settings
  has_profile: bool
```

- **Reaktivite:** Riverpod `StreamProvider`'lar için `box.watch()` + başlangıç değeri kullanılır.
- **Tekil Gün Kuralı:** `logs` anahtarı `"habitId|yyyy-MM-dd"` olduğu için gün başına tek kayıt kuralı key yapısıyla garanti edilir.
- **Yıllık Takvim:** `logs` kutusunda `"habitId|YYYY-"` ön ekiyle taranarak tek geçişte filtrelenir.

---

## 5. Ekranlar ve Akış

```
Splash ("settings" ve "profile" kutusunda profil kontrolü)
 ├─ profil yok → Karşılama Ekranı ("/welcome" — "Bahçeni Kur 🌱" butonu)
 │                 └─ Karakter Seçimi ("/onboarding/character")
 │                      └─ Kullanıcı Adı ("/onboarding/username")
 │                           └─ Ana Sayfa ("/home")
 └─ profil var → doğrudan Ana Sayfa ("/home")
```

### 5.1 Karşılama & Yerel Profil
- Hesap/şifre/Google girişi yoktur. E-posta ve şifre hiçbir yerde saklanmaz.
- Yeni kullanıcı karşılamada "Bahçeni Kur 🌱" butonuna basarak doğrudan karakter seçimine geçer.

### 5.2 Onboarding
- **Karakter seçimi:** 6 adet karakter kartı (`char_1`…`char_6`). Kod `characterId` saklar.
- **Kullanıcı adı:** 3–20 karakter, format `[a-zA-Z0-9_.]`. Benzersizlik kontrolü yoktur; format doğrulandığında profil yerel olarak kaydedilir.

### 5.3 Ana Sayfa (yukarıdan aşağıya)
1. **Bitki alanı:** tohum → filiz → sap → tomurcuk → çiçek. Çiçek rüzgarda sallanır. Görseller placeholder (`assets/plant/stage_0.png` … `stage_4.png`), yoksa `Icon` / `CustomPaint` ile çizilmiş basit placeholder kullan.
2. **Günün motivasyonu:** 3 kapalı kart. Kullanıcı birine dokunur, kart döner (flip). Gün boyunca başka seçim yapılamaz, diğer kartlar kilitli görünür.
3. **Alışkanlık listesi:** her kartta ikon, başlık, saniye saniye artan süre sayacı, aktif zincir 🔥, "Bugün yaptım" butonu (quit tipinde "Bugün temizim" + küçük "Kaydım" butonu). Karta dokununca detay sayfasına gider. Sola kaydırınca silme (onaylı).
4. **FAB (+):** alışkanlık ekleme bottom sheet'i. Hazır şablonlar: Kitap okuma, Spor, Zayıflama, Su içme, Sigara bırakma, Alkol bırakma + "Özel". Alanlar: ad, tür, ikon, renk, hatırlatma saati, günler.

### 5.4 Alışkanlık Detay
- Üstte özet: aktif zincir, en uzun zincir, haftalık %, aylık %.
- **Sekme 1 — Grafikler:**
  - Çizgi grafik: "Güç skoru" (yapılan gün +1, kaçırılan gün −1, alt sınır 0). Son 30 gün.
  - Sütun grafik: haftalık tamamlama sayısı, son 8 hafta.
  - Isı haritası ızgarası: son 30 gün (GitHub tarzı).
- **Sekme 2 — Yıllık Zincir Takvimi:**
  - Yıl seçici (‹ 2026 ›), 12 mini ay takvimi ızgara halinde.
  - Tamamlanan gün **elle çizilmiş gibi kırmızı X** ile işaretlenir.
  - **Art arda tamamlanan günler aynı hafta satırındaysa birbirine zincir halkası/çizgi ile bağlanır.** Hafta sonundan sonraki pazartesiye geçişte satır sonunda ve başında küçük bir halka ucu gösterilir.
  - Bugün: halka ile çevrili. Gelecek günler: soluk. Başlangıç tarihinden önceki günler: gri/pasif. Kaçırılan geçmiş günler: boş. Quit tipinde "relapse" günü: turuncu küçük daire.
  - Üstte: "Bu yıl X / Y gün (%Z)", "En uzun zincir", "Aktif zincir".
  - Güne dokununca küçük bottom sheet: tarih + durum (sadece görüntüleme).
- Hatırlatma düzenleme ve silme butonu (onaylı).

### 5.5 Bahçe
- `gardenStartDate`'ten bu yana geçen gün ≥ 30 ise: tamamlanan her 30 günlük döngü bahçede bir çiçek olur. Bütün çiçekler sallanır, büyüme animasyonu bir kez oynar.

### 5.6 Profil
- Karakter (dokununca değiştir), kullanıcı adı (düzenle — format kontrolüyle).
- İstatistik kartları: toplam tamamlama, en uzun zincir, aktif alışkanlık sayısı, üyelik günü.
- Çiçek galerisi (bahçedeki çiçekler).
- Rozetler (Faz 5).
- Bildirim ayarları (genel aç/kapat).
- Tema: açık / koyu / sistem.
- **Çıkış Yap / Bahçeyi Sıfırla:** onay diyaloğu → bütün Hive kutularını temizle, bildirimleri iptal et → Karşılama ekranına dön. (Hesabı sil butonu ile birleşmiştir).

---

## 6. İş Kuralları (TEK DOĞRU KAYNAK)

Bütün hesaplar `lib/domain/` altında **saf fonksiyon** olarak yazılır ve test edilir. Ayrıntılar `skills/habit-logic.md` dosyasında.

- **Gün anahtarı:** cihazın yerel saatine göre `yyyy-MM-dd`. UTC kullanılmaz.
- **Tek dokunuş:** bugünün log'u varsa buton "Tamamlandı ✓" olur ve tekrar basılamaz. Geri alma sadece aynı gün, 5 saniyelik SnackBar'dan.
- **Geçmiş günler işaretlenemez.**
- **Aktif zincir:** bugünden geriye ardışık `done` gün sayısı. Bugün henüz yapılmadıysa sayım dünden başlar (zincir gün bitene kadar kopmaz).
- **Haftalık %:** bu hafta (Pazartesi başlangıç), başlangıç tarihinden sonraki ve bugüne kadarki günler içinde tamamlanma oranı. **Aylık %:** aynı mantık, takvim ayı.
- **Güç skoru:** startDate'ten itibaren her gün done ise +1, değilse −1, min 0. Bugün henüz yapılmadıysa bugün hesaba katılmaz.
- **Saniye sayacı:** build → `startDate`'ten beri; quit → `lastRelapseAt ?? startDate`'ten beri. Format: `12g 04s 33d 09sn`.
- **Kaydım (quit):** onay diyaloğu → bugünün log'u `relapse`, `lastRelapseAt = now`. Sayaç sıfırlanır.
- **Silme:** `Dismissible.confirmDismiss` ile onay diyaloğu → `isDeleted: true` → 5 sn "Geri al" SnackBar'ı. İlgili bildirimler iptal edilir.
- **Bitki aşaması:** `dayInCycle = gün % 30` → 0: tohum, 1–3: filiz, 4–10: sap, 11–20: tomurcuk, 21–29: çiçek. Dün hiçbir alışkanlık yapılmadıysa bitki "solgun" görünür (renk/doygunluk düşer, boyu küçülmez).
- **Motivasyon:** günde 1 doküman, 3 seçenek, seçim transaction ile ve sadece `selectedIndex == null` iken yazılır.

---

## 7. Geliştirme Sırası (Fazlar)

Her fazın sonunda uygulama **derlenir ve çalışır durumda** olmalı. Her faz sonunda İngilizce commit at.

| Faz | İş | Kabul kriteri |
|---|---|---|
| 0 | Proje, paketler, `flutterfire configure`, tema, router, ScreenUtil | Uygulama açılıyor |
| 1 | Auth (Email + Google), onboarding (karakter + kullanıcı adı) | Kayıt → karakter → kullanıcı adı → ana sayfa akışı çalışıyor |
| 2 | Alışkanlık ekle / listele / tek dokunuş onay / zincir / saniye sayacı / onaylı silme | Firestore'da veri doğru yazılıyor, `domain` testleri geçiyor |
| 3 | Detay sayfası: grafikler + ısı haritası + **yıllık zincir takvimi** | Grafikler gerçek veriyle çiziliyor |
| 4 | Motivasyon kartları (AI + offline yedek) | Günde tek seçim, uygulama yeniden açılınca seçim korunuyor |
| 5 | Bitki aşamaları + sallanma, bahçe ekranı, profil | 320dp ve 430dp genişlikte overflow yok |
| 6 | Bildirimler, rozetler, konfeti, koyu tema | Zaman kalırsa |

---

## 8. 🚫 KESİNLİKLE YAPILMAYACAKLAR

### Mimari
- ❌ Firebase veya uzak backend paketleri (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_ai`, `google_sign_in`) **ekleme/kullanma**. Tüm veri cihazda Hive ile tutulur.
- ❌ Codegen (`riverpod_generator`, `build_runner`, `TypeAdapter`, `freezed`) **kullanma**. Hive kutularında doğrudan Map/JSON saklanır.
- ❌ Riverpod dışında state yönetimi (Provider, Bloc, GetX, MobX) **ekleme**, karıştırma.
- ❌ Widget içinden doğrudan Hive kutularını (`HiveService.instance.*Box`) **çağırma**. Her şey repository üzerinden.
- ❌ İş kurallarını (zincir, yüzde, skor) widget içinde **hesaplama**. Sadece `lib/domain/`.
- ❌ Global state için `setState` **kullanma** (sadece animasyon gibi widget içi geçici state'te serbest).

### Güvenlik & AI
- ❌ Gemini REST API anahtarını koda, `.env`'e, dosyalara veya repoya **ASLA yazma/gömme**. Sadece `const String.fromEnvironment('GEMINI_API_KEY')` ile al.
- ❌ `google_generative_ai` paketini KULLANMA (deprecated). Doğrudan `http` ile Gemini REST API'ye istek at.
- ❌ AI anahtarı yoksa veya istek başarısız olursa kullanıcıya hata gösterme; sessizce çevrimdışı yedek listeye düş.

### Veri / Mantık
- ❌ Gün hesabını `DateTime.now().difference(x).inDays` veya UTC ile **yapma**. Sadece yerel tarih anahtarları (`yyyy-MM-dd`).
- ❌ Aynı gün için ikinci log **oluşturma**. `logs` anahtarı (`habitId|yyyy-MM-dd`) ile tekillik korunur.
- ❌ Alışkanlığı onaysız **silme**. Hive'dan hard delete **yapma** (soft delete `isDeleted: true`).
- ❌ Motivasyonu her açılışta yeniden **üretme**. Günlük seçim yapıldıktan sonra değiştirmeye izin **verme**.
- ❌ AI'dan tıbbi tavsiye, ilaç, diyet/kalori hedefi, alkol/sigara bırakmaya dair klinik yönlendirme **isteme/gösterme**.

### UI / Performans
- ❌ Sabit piksel genişlik/yükseklik (`width: 375`) **kullanma**. ScreenUtil veya oran.
- ❌ Saniye sayacını global provider'a veya üst widget'a **koyma**. Sadece ilgili kartın kendi küçük widget'ında `Timer` olsun.
- ❌ Yıllık takvimde kayıtları tek tek okumak yerine `logs` kutusunda `habitId|YYYY-` ön ekiyle tek seferde tara.

### Kapsam Dışı (bu sürümde YOK)
- ❌ Arkadaş, sosyal paylaşım, liderlik tablosu, sohbet
- ❌ Ödeme, abonelik, reklam
- ❌ Web, desktop, tablet özel tasarımı
- ❌ Çoklu dil (sadece Türkçe UI)
- ❌ Çevrimdışı harici kullanıcı girişi (hesap/şifre/Google girişi yok)

### Süreç
- ❌ Çalışan kodu sebepsiz yeniden **yazma**, büyük refactor **yapma**.
- ❌ Listede olmayan paketi kullanıcıya sormadan **ekleme**.
- ❌ Türkçe commit mesajı **yazma**. Commit mesajları **İngilizce** ve Conventional Commits formatında (`refactor: replace firebase with local hive storage`).
- ❌ Bir fazı derlenmeyen kodla **bitirme**.

---

## 9. Skill Dosyaları

| Dosya | Ne zaman oku |
|---|---|
| `skills/state-management.md` | Provider yazarken |
| `skills/local-storage.md` | Hive kutuları, key formatları, watch kullanımı, sıfırlama |
| `skills/habit-logic.md` | Zincir, yüzde, skor, tarih hesapları |
| `skills/ui-responsive-animation.md` | Ekran, bitki, kart flip, sayaç |
| `skills/charts-calendar.md` | Grafikler, ısı haritası, yıllık zincir takvimi |
| `skills/ai-motivation.md` | Motivasyon kartları ve Gemini REST desteği |
| `skills/notifications.md` | Hatırlatmalar |