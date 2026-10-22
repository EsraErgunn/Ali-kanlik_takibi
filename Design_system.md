---
name: design-system
description: BloomHabit "Botanical Vitality" tasarım sistemi ve onaylanmış ekran tasarımları (Bahçem, Yeni Alışkanlık, Alışkanlık Detay, Profil). Herhangi bir ekran, widget veya tema yazarken ÖNCE bunu oku. Tasarım ile project.md çelişirse TASARIM kazanır.
---

# BloomHabit — Tasarım Sistemi ve Ekranlar

> Tasarım **onaylandı ve kesindir.** Agent yeni stil icat etmez, sadece bu dosyayı ve `docs/design/` içindeki ekran görüntülerini birebir uygular.
> Ekran görüntüleri: `docs/design/00_design_system.png`, `01_home.png`, `02_new_habit.png`, `03_habit_detail.png`, `04_profile.png` (kullanıcı ekleyecek). Görüntü varsa ölçü ve hizalamada görüntüyü referans al.

## 1. Tokenlar — `core/theme/app_colors.dart`, `app_theme.dart`

### Renkler
| Token | Hex | Kullanım |
|---|---|---|
| `primary` | `#1B6B48` | Ana butonlar, aktif nav, tamamlandı, grafik çizgisi, logo |
| `primaryDark` | `#0F4A31` | Basılı durum, ısı haritası en koyu ton |
| `primaryContainer` | `#DCEFE3` | Yeşil bilgi kutuları, seçili çip zemini, "Seviye" rozeti |
| `secondary` | `#F07152` | Bırakma (quit) etiketi, zincir alevi 🔥, "Kaydım", Tehlikeli Alan, kaçırılan gün |
| `secondaryContainer` | `#FDE3DB` | Bırakma rozet zemini, alev rozeti zemini |
| `tertiary` | `#ECA038` | Tasarruf, XP, joker/kalkan, uyarı çipleri |
| `tertiaryContainer` | `#FBEBCF` | Tertiary rozet zemini |
| `neutral` | `#2B2824` | Ana metin |
| `neutralVariant` | `#6E6862` | İkincil metin, açıklamalar |
| `background` | `#FBF7F2` | Sayfa zemini (sıcak krem) |
| `surface` | `#FFFFFF` | Kartlar |
| `surfaceMuted` | `#F3EEE8` | İç kutular, input zemini, kilitli kart |
| `outline` | `#E7E0D8` | İnce kenarlıklar |

Her rengin 50–900 tonları tasarım sisteminde var. Gerekirse `Color.lerp` ile türet, yeni renk ekleme.
Koyu tema: aynı hue'lar, background `#141311`, surface `#1E1C1A`, primary `#7FD1A6`.

### Tipografi
- Font: **Plus Jakarta Sans** (`google_fonts` → `GoogleFonts.plusJakartaSansTextTheme()`), bütün uygulamada tek font.
- Ölçek (`.sp`):

| Stil | Boyut | Ağırlık | Örnek |
|---|---|---|---|
| displaySmall | 26 | 800 | "Yeni Alışkanlık Tohumu Ek" |
| headlineSmall | 20 | 700 | "Sigarayı Bırakma", "@deniz_yesil" |
| titleMedium | 16 | 700 | Bölüm başlıkları ("Günün AI Kehaneti") |
| titleSmall | 14 | 700 | Kart başlıkları |
| bodyMedium | 13 | 500 | Açıklamalar |
| labelSmall | 10 | 700, UPPERCASE, letterSpacing 0.8 | Üst etiketler ("AKTİF İYİLEŞME ROTASI", "CANLI SAYAÇ") |
| statNumber | 24–28 | 800, tabularFigures | "05 GÜN", "32 Gün", "94%" |

### Şekil ve boşluk
- Kart radius: **20.r** · iç kutu radius: **14.r** · çip/buton: **pill (999)** · ikon kutusu: **12.r**
- Sayfa yatay padding: **16.w** · kartlar arası: **12.h** · bölümler arası: **24.h**
- Gölge: çok hafif — `BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: Offset(0, 4))`. Kalın gölge yok.
- Kenarlık: kartlarda yok ya da `outline` 1px. Input'larda `outline` 1px, odakta `primary` 1.5px.

### Ortak bileşenler — `core/widgets/`
- `BloomCard` — beyaz, 20.r, hafif gölge, padding 16.
- `SectionHeader(title, icon?, trailing?)` — sol ikon + başlık, sağda küçük gri metin ("2/3 Tamamlandı", "1/1 Hak").
- `EyebrowLabel` — labelSmall, renkli (ör. primary/secondary).
- `StatusChip(text, tone: primary|secondary|tertiary|neutral, icon?)` — pill, container zemin, renkli metin.
- `StatTile(label, value, sub, icon?, valueColor?)` — "BAHÇE YAŞI / 32 Gün / Toprak yeşeriyor".
- `PrimaryPillButton` — tam genişlik, primary dolu, 52.h, ikon + metin.
- `OutlinePillButton(tone)` — "Kaydım" gibi.
- `ProgressPill(value, color)` — 6.h yüksek, yuvarlak.
- `InfoBox(text, tone)` — container zemin, sol ikon, 14.r.
- `LockedCard` — `surfaceMuted`, kilit ikonu, soluk metin.

## 2. Navigasyon
`AppShell` → alt bar 5 öğe: **Bahçem · Alışkanlıklar · (+) · Analiz · Profil**
- Ortadaki `+`: alt barın üstüne taşan, 56.r yuvarlak, primary FAB → **Yeni Alışkanlık** sayfasına push (bottom sheet DEĞİL).
- Aktif sekme: primary ikon + label. Pasif: neutralVariant.
- Ortak üst bar (Bahçem, Profil): sol 🌱 logo + "BloomHabit" (primary, 18.sp, 800) + altında sayfa adı (küçük gri) · `StatusChip("Seviye 4 Bahçıvan", primary)` · `StatusChip("🔥 14 Gün", secondary)` · sağda yuvarlak avatar (karakter).
- Alt sayfalar (Yeni Alışkanlık, Detay): sol geri oku + 🌱 + başlık, sağda avatar.

## 3. Ekran: Bahçem (Ana sayfa)
Yukarıdan aşağıya:

1. **Bitki kartı** (`BloomCard`, hafif yeşil-krem gradient zemin)
   - Üst satır: sol `StatusChip("Zümrüt Orkidesi · Seviye 4")`, sağ `StatusChip("🛡 Kalkan: 1/2 Hazır", tertiary)`.
   - Ortada `StatusChip("📅 18. Gün", tertiary)`, altında bitki görseli (sallanan, terrarium tarzı, ~180.h). Görsel kullanıcıdan gelecek, placeholder kullan.
   - Alt: "🌿 Tomurcuk Aşaması" + sağda "21. Günde Çiçek Açar (%86)" + `ProgressPill`.
   - `InfoBox(primary)`: "Bugün tüm alışkanlıklarını tamamlarsan ilk taç yaprağı açacak! Kaçırırsan solma uyarısı devreye girer." Metin aşamaya göre değişir.
2. **Günün AI Kehaneti** — `SectionHeader` + `StatusChip("✨ Gemini AI")` + sağda "1/1 Hak" (seçildiyse "0/1").
   - 3 kart yan yana. Seçilen kart genişler (~%60): üstte kart adı ("🌱 Derin Kökler Kartı"), italik tırnaklı metin, alt satır `#hashtag` + yer imi ikonu.
   - Seçilmeyenler dar, `LockedCard`: kilit + "Yarın Açılır" + küçük kart adı.
   - Seçimden önce: 3 eşit kapalı kart (yaprak deseni, "Bir kart seç").
   - Altında ortalanmış gri not: "Günde sadece 1 kehanet seçme hakkın var. Seçtiğin kart bugünkü bahçe enerjini belirler."
3. **Bugünkü Görevler** — sağda "2/3 Tamamlandı". Filtre çipleri: `Tümü (3)` · `Kazanım 🌱` · `Bırakma 🚭` (seçili = primary dolu).
4. **Alışkanlık kartları** (3 varyant):
   - **Bırakma (quit):** ikon kutusu secondaryContainer · başlık + `StatusChip("Bırakma", secondary)` · alt satır "🔥 5 Gün Zincir • 500₺ Tasarruf 💰" · sağ üst ⋮ menü · `surfaceMuted` kutu: "CANLI SAYAÇ:" + sağda `ElapsedTicker` "5g 14s 30d 44sn Temiz" (bold) · altta yan yana: `PrimaryPillButton("✓ Bugün Temizim")` (geniş) + `OutlinePillButton("◇ Kaydım", secondary)` (dar).
   - **Kazanım (build):** ikon kutusu primaryContainer · başlık + `StatusChip("Kazanım 🌱", primary)` · "Hedef: 20 Sayfa • Saat: 21:30" · "⚡ 18 Gün Zincir (En Uzun!)" (primary) · sağda yuvarlak onay butonu (yapıldıysa primary dolu ✓, değilse outline).
   - **Sayaçlı (count):** "2.5L Su İç" + `Kazanım` · "4/5 Bardak (2000 ml)" · sağda `StatusChip("+ 1 Bardak")` buton · altta `ProgressPill`. Hedefe ulaşınca kart "tamamlandı" durumuna geçer.
   - Karta dokununca Detay sayfası. Sola kaydır → onaylı silme.

## 4. Ekran: Yeni Alışkanlık
- Ortada `StatusChip("🌱 BOTANİK RİTÜEL OLUŞTURUCU")`, başlık "Yeni Alışkanlık Tohumu Ek 🌱", gri alt metin.
- **Segment** (pill, 2 seçenek): "🌱 Alışkanlık Kazan" | "🛡 Kötü Alışkanlığı Bırak". Seçime göre altındaki `InfoBox` değişir ("Pozitif Büyüme & Rutin Zinciri" / "Özgürlük Yolu & Temiz Gün Sayacı").
- "⚡ Popüler Tohum Şablonları" + sağda "Tek Dokunuşla Seç" → yatay kaydırmalı çipler (Kitap Okuma (20 sf), Sigarayı Bırak, Su İç, Spor, Zayıflama, Alkolü Bırak). Çip formu doldurur.
- Form kartı: "Tohum Adı *" input (sağda seçili ikon) · "Tohum Simgesi" 6 ikonluk grid (seçili = primaryContainer zemin) · "Aura / Saksı Rengi" 6 renk dairesi (seçili ✓) · "⏰ Sulama & Hatırlatma Saati" sağda saat + saat ikonu · "Tekrar Günleri" 7 kare toggle (Pzt…Paz, seçili = primary dolu beyaz yazı).
- Bırakma seçiliyse ek alanlar: "Günlük adet" + "Birim fiyat (₺)" (tasarruf için). Sayaçlı şablonda: "Günlük hedef" + "Birim" (Bardak).
- Önizleme kartı: ikon + ad + `StatusChip("+10 XP", tertiary)` + "Seviye 1: Filiz Aşaması (0/7 Günlük Tohum)".
- Alt: `PrimaryPillButton("🪴 Tohumu Bahçeme Dik")` + küçük gri not.

## 5. Ekran: Alışkanlık Detay (tek sayfa scroll, sekme YOK)
1. **Başlık kartı:** `EyebrowLabel("AKTİF İYİLEŞME ROTASI")` (build: "AKTİF BÜYÜME ROTASI") · ikon + başlık · sağda "● Canlı İzleme" (yeşil nokta yanıp söner).
   - "⏳ Duman-Free Süre" (build: "Büyüme Süresi") + sağda "Özgürlük Yolu" · 4 kutu: **GÜN · SAAT · DK · SN** (statNumber, 2 hane, SN kutusu secondary renk). Saniyede bir güncellenir (yalıtılmış widget).
   - 3 mini `StatTile`: **Tasarruf** "500,00 ₺ / 5 paket x 100₺" · **İçilmeyen** "100 adet / sigara" · **Kalkan** "1 Joker Hak / Zincir Koruyucu" (tertiary). Build tipinde: Tamamlama, En Uzun Zincir, Kalkan.
2. **Güç Skoru İlerlemesi:** `EyebrowLabel("DİNAMİK İRADE GRAFİĞİ")` + sağ `StatusChip("🔥 Kararlı İrade", secondary)` · `StatusChip("🚩 Tepe: 18 Puan")` · yumuşak eğri çizgi + altı primary gradient alan, noktalar sadece hafta işaretlerinde, son nokta vurgulu · x: "3 Hafta Önce · 2 Hafta Önce · Geçen Hafta · Bugün (18 Skor)" · altında `InfoBox`: "Güç Skoru Algoritması: Her temiz gün +1 puan kazandırır, kaçırılan gün −1 puan eksiltir. Taban puan 0'dır, asla negatife inmez."
3. **Haftalık Tamamlama Barları:** `EyebrowLabel("SÜRDÜRÜLEBİLİRLİK")` · sağda "7/7 Gün · %100 Başarı" · 8 sütun H1…H7, Bu; üstünde "x/7"; 7/7 = primaryDark, 5–6 = primary açık ton, ≤3 = secondaryContainer. Yuvarlak üst köşeler.
4. **30 Günlük Terrarium Matrisi:** sağda "28 / 30 Gün" · gri alt yazı · 3 `StatTile`: Aylık Başarı %93.3 · Haftalık Tamlık %100 · Toplam Başarı 28 Gün · **6 kolonlu numaralı ızgara (1–30)**, renk yoğunluğu 4 seviye (surfaceMuted → primaryContainer → primary → primaryDark), kaçırılan gün secondaryContainer, gelecek gün çok soluk · lejant: "Düşük Yoğunluk ●●●● Tam İrade (Bloom)".
5. **Yıllık Zincir Takvimi** (tasarımda yok, bu stilde ekle): aynı `BloomCard`, `EyebrowLabel("YILLIK ZİNCİR")`, başlık "Zinciri Kırma" + yıl seçici. X'ler `secondary`, zincir bağlantıları `primary` (alpha 0.5). Ayrıntı: `charts-calendar.md`.
6. **Alışkanlık Rutini & Bildirimler:** "Hatırlatma Vakti / Her akşam düzenli kontrol" + sağda `StatusChip("20:00 (Her Gün)")` (dokununca düzenle) · "Motivasyon Mesajı" kutusu (bildirim metni önizlemesi).
7. **Tehlikeli Alan:** secondaryContainer çok açık zemin, secondary başlık "⚠ Tehlikeli Alan" + sağda "Geri Alınabilir" · açıklama: arşivlenince 5 sn geri alma · `OutlinePillButton("🗑 Bu Alışkanlığı Arşivle / Kaldır", secondary)` → onay diyaloğu.

## 6. Ekran: Profil
1. Ortada avatar (karakter, 96.r, yeşil halka + sağ altta ✓ rozet) · "@deniz_yesil ✓" · `StatusChip("🌱 Seviye 4 • Usta Bahçıvan")`.
2. **2x2 StatTile:** BAHÇE YAŞI "32 Gün" / Toprak yeşeriyor · GENEL BAŞARI "94%" / Yüksek verim · EN UZUN ZİNCİR "18 Gün" (secondary) / Rekor disiplin · DONDURMA JOKERİ "2 Hazır" (tertiary rozet) / Zinciri korur.
3. **Çiçek Koleksiyonum** + sağda "2/4 Nadir" · gri açıklama · liste kartları: yuvarlak çiçek görseli · "Ekim Ayı Çiçeği" + `StatusChip("30/30 Gün")` · çiçek adı (bold) · ilgili alışkanlık · sağda ✓ rozet. Büyüyen çiçek: "Aralık Çiçeği • Büyüyor 🌱" + "18/30 Gün" + `ProgressPill` + "Tamamlanmaya 12 gün kaldı · %60". Kilitli: `LockedCard` "Ocak Ayı Sürprizi 🔒 / Kilitli Gizemli Tohum".
4. **Kilometre Taşı Rozetleri** + "4/5 Açıldı" · 2x2 rozet kartı (yuvarlak ikon, ad, açıklama, `StatusChip("Kazanıldı")`): İlk Tohum · 7 Günlük Alev · Kalkan Ustası · 21 Gün Döngüsü · altta kilitli geniş kart "100 Günlük Efsane Bahçe" + "32/100 Gün" + progress.
5. **Uygulama & Güvenlik** liste: Kullanıcı Adı Değiştir (alt: "@deniz_yesil (Benzersiz kimlik)", ›) · Bildirim Tercihleri (›) · Karanlık Mod (switch).
6. Ortada secondary metin buton "🗑 Hesabı ve Tüm Bahçe Verilerini Sil" + gri not "Bu işlem geri alınamaz. Google Play gereksinimlerine uygundur."

## 7. Tasarımı olmayan ekranlar (aynı dille yap, sade tut)
- **Giriş / Kayıt:** krem zemin, üstte logo + "BloomHabit" + slogan, `BloomCard` içinde inputlar, `PrimaryPillButton("Giriş Yap")`, beyaz outline "G  Google ile devam et", alt link "Hesabın yok mu? Kaydol".
- **Karakter Seçimi:** başlık "Bahçıvanını Seç", 2 kolon grid karakter kartları (seçili = primary 2px kenar + ✓), alt CTA "Devam".
- **Kullanıcı Adı:** "@" prefix'li input, canlı uygunluk kontrolü (✓ yeşil / ✗ secondary), CTA "Bahçeme Gir".
- **Alışkanlıklar sekmesi:** Bahçem'deki görev listesi + filtreler, tam sayfa, arşivlenenler bölümü (geri yükle).
- **Analiz sekmesi:** tüm alışkanlıkların birleşik güç skoru, haftalık barlar, genel yıllık zincir takvimi (gün = o gün en az bir alışkanlık yapıldıysa X).
- **Bahçe (30 gün sonrası):** tam ekran, toplanan çiçekler farklı fazlarda sallanır.

## 8. Metin dili
Botanik metafor tutarlı: alışkanlık = **tohum**, eklemek = **dikmek**, tamamlamak = **sulamak**, joker = **kalkan**, bildirim = **sulama saati**. Butonlarda ve boş durumlarda bu dili koru.

## 🚫 Yapma
- ❌ Bu paletin dışında renk, Plus Jakarta Sans dışında font kullanma.
- ❌ Material varsayılan mor/mavi tema, keskin köşeli kart, kalın gölge.
- ❌ Detay sayfasını sekmelere bölme. Tasarım tek scroll.
- ❌ Yeni Alışkanlık'ı bottom sheet yapma. Tam sayfa.
- ❌ **Uydurma sağlık verisi gösterme** (tasarımdaki "Akciğer +%12 Kapasite" gibi). Yerine "İçilmeyen adet" göster. Tıbbi iddia yok.
- ❌ Tasarımdaki örnek değerleri (500₺, 18 Gün, @deniz_yesil) hardcode etme. Hepsi gerçek veriden gelir.
- ❌ Görsel üretme. Çiçek, karakter, terrarium görselleri placeholder.