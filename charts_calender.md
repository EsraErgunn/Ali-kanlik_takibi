---
name: charts-calendar
description: fl_chart ile güç skoru çizgi grafiği ve haftalık sütun grafiği, 30 günlük ısı haritası ve X ile işaretlenen yıllık zincir takvimi. Detay sayfasında çalışırken oku.
---

# Grafikler ve Takvimler

Bütün veriler `domain/habit_stats.dart` fonksiyonlarından gelir. Widget hesap yapmaz.

## Detay sayfası düzeni
**Tek scroll, sekme YOK.** Sıra ve görsel stil `design-system.md` §5'te. Bu dosya sadece grafik/takvim çizim mantığını anlatır; renk, başlık ve kart stili için design-system geçerli.

## 30 Günlük Terrarium Matrisi (tasarımdaki hali)
Aşağıdaki "Isı haritası" bölümü yerine tasarımdaki **6 kolonlu, 1–30 numaralı** kare ızgara kullanılır. Hücre rengi 4 seviye (done gün sayısına göre değil, o günün durumuna göre): `done` → primaryDark, `done` ve zincirin parçası değil → primary, `partial`/`frozen` → primaryContainer, `missed` → secondaryContainer, gelecek → surfaceMuted soluk. Hücre içinde gün numarası (beyaz/koyu kontrasta göre).

## 1. Güç skoru — Çizgi grafik
```dart
LineChart(LineChartData(
  minY: 0,
  gridData: const FlGridData(show: true, drawVerticalLine: false),
  titlesData: ..., // alt eksen: her 7 günde bir "dd.MM"
  lineBarsData: [
    LineChartBarData(
      spots: [for (var i = 0; i < s.length; i++) FlSpot(i.toDouble(), s[i].toDouble())],
      isCurved: true,
      preventCurveOverShooting: true,
      barWidth: 3,
      color: habitColor,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: habitColor.withValues(alpha: 0.15)),
    ),
  ],
))
```
- Son 30 gün. Veri 2 günden azsa grafik yerine "Birkaç gün sonra burada gelişimini göreceksin" yazısı.
- Yükseklik: `200.h`, `AspectRatio` değil (küçük ekranlarda taşmasın).

## 2. Haftalık tamamlama — Sütun grafik
- 8 sütun, `maxY: 7`. Alt etiket: "Bu", "-1", … "-7" ya da haftanın başlangıç tarihi `dd.MM`.
- Bu hafta sütunu tam renk, geçmiş haftalar `alpha: 0.6`.
- Dokununca tooltip: "5/7 gün".

## 3. Isı haritası (son 30 gün)
- 7 satır (Pzt–Paz) × ~5 kolon, `GridView` değil `Wrap`/`Column(Row)` ile hafif çizim.
- Hücre: `done` → alışkanlık rengi, `missed` → `surfaceContainerHighest`, gelecek → şeffaf, başlangıç öncesi → çok soluk.
- Hücre boyutu `LayoutBuilder` ile: `(width - spacing * 5) / 6`, üst sınır `28.r`.

## 4. Yıllık Zincir Takvimi ⭐

### Düzen
```
‹  2026  ›
Bu yıl 124 / 295 gün (%42) · En uzun zincir 31 · Aktif 12
[Oca] [Şub] [Mar]
[Nis] [May] [Haz]     ← LayoutBuilder: <360 → 2 kolon, <600 → 3, aksi 4
...
```
- Yıl değiştirme: gelecek yıllara gidilemez, ilk yıl = alışkanlığın başlangıç yılı.
- Veri: `yearLogsProvider((habitId: id, year: y))`. **Tek Firestore sorgusu.**
- Hesap: `buildMonth(...)` (bkz. `habit-logic.md`).

### Mini ay takvimi
- Başlık: Türkçe ay adı (`DateFormat.MMMM('tr_TR')`, `initializeDateFormatting('tr_TR')` main'de çağrılmalı).
- Gün başlıkları: P S Ç P C C P (pazartesi başlangıç).
- Ayın ilk gününden önce `weekday - 1` boş hücre.
- Hücre kare. Boyut ay kutusunun genişliğinden: `cell = boxWidth / 7`.

### Hücre çizimi — `ChainDayPainter extends CustomPainter`
Katman sırası (alttan üste):
1. **Zincir bağlantısı** (sadece `done` günlerde):
   - `linkRight`: hücre merkezinden sağ kenara kalın yuvarlak uçlu çizgi (`strokeWidth = cell * 0.12`, renk: alışkanlık rengi `alpha 0.5`).
   - `linkLeft`: sol kenardan merkeze aynı çizgi.
   - İki komşu hücrenin yarım çizgileri birleşince kesintisiz zincir oluşur.
   - İstersen çizginin ortasına küçük oval halka (`drawOval`, stroke) çiz. Zincir halkası görünümü verir.
   - `continuesNextRow` / `continuesPrevRow`: satırın sağ/sol kenarına küçük açık halka ucu.
2. **Gün numarası:** küçük, `onSurfaceVariant`, `done` ise `alpha 0.5` (X'in altında kalır).
3. **X işareti** (`done`):
   - İki çapraz çizgi, `strokeCap: round`, `strokeWidth = cell * 0.11`, renk kırmızı (`Color(0xFFE53935)`) veya alışkanlık rengi.
   - **El çizimi hissi:** tarihten tohumlanmış `Random(date.millisecondsSinceEpoch)` ile her uçta ±%6 kayma ve ±4° dönme. Böylece her X biraz farklı görünür ama her çizimde aynı kalır.
   - Çizgi uçları hücrenin %18 içeriden başlasın.
4. **relapse:** turuncu küçük dolu daire.
5. **today:** `primary` renginde ince halka (stroke).
6. **future:** sadece soluk numara. **beforeStart:** `alpha 0.25`.

`shouldRepaint`: sadece `mark`, bağlantı bayrakları veya renk değiştiyse true.

### Etkileşim
- Hücreye dokununca bottom sheet: "22 Ekim 2026 Perşembe — Tamamlandı ✓" / "Kaçırıldı" / "Kaydın günü". **Düzenleme yok.**
- Yeni X eklenme animasyonu (sadece bugün işaretlenince detay sayfası açıksa): X'in iki çizgisi sırayla çizilir (`PathMetric.extractPath` ile 0→1, 400 ms).

### Performans
- 12 ay × ~31 hücre = ~372 `CustomPaint`. Sorun yok, ama her ayı `RepaintBoundary` içine al.
- Yıl değişince sadece provider değişir, eski yıl cache'te kalır.

### Erişilebilirlik
- Her hücre `Semantics(label: '22 Ekim, tamamlandı')`.

## Yapma
- ❌ Yıllık takvim için 365 ayrı okuma.
- ❌ Grafik içinde iş kuralı hesaplama.
- ❌ X işaretini her build'de farklı rastgele çizme (tohumsuz `Random()`).
- ❌ Takvimden geçmiş günü işaretleme/düzenleme.
- ❌ `syncfusion` veya başka grafik paketi ekleme. Sadece `fl_chart`.