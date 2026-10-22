---
name: ui-responsive-animation
description: Responsive düzen, tema, bitki büyüme ve rüzgar sallanma animasyonu, motivasyon kartı flip, saniye sayacı widget'ı, onaylı silme ve boş durumlar. Herhangi bir ekran veya widget yazarken oku.
---

# UI, Responsive ve Animasyon

## Responsive temel
```dart
ScreenUtilInit(
  designSize: const Size(390, 844),
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (_, child) => MaterialApp.router(...),
);
```
- Boyutlar: `16.w`, `12.h`, `14.sp`, `12.r`. Sabit sayı yok.
- Font: `sp` kullanırken sistem yazı büyütmesine dikkat et. `MediaQuery.textScalerOf` 1.3 üstündeyse kartlarda `maxLines` + `TextOverflow.ellipsis`.
- Izgaralar `LayoutBuilder` ile kolon sayısı seçer:
  ```dart
  int cols(double w) => w < 360 ? 2 : w < 600 ? 3 : 4;
  ```
- Her ekranın kökü `SafeArea`. Uzun içerik `CustomScrollView` + `Sliver`. Klavye açılan formlarda `SingleChildScrollView`.
- Bottom sheet: `isScrollControlled: true` + `Padding(bottom: MediaQuery.viewInsetsOf(context).bottom)`.
- **Test genişlikleri:** 320, 360, 390, 430 dp. Hiçbirinde sarı-siyah overflow bandı olmamalı.

## Tema
- Material 3, `ColorScheme.fromSeed(seedColor: Color(0xFF4CAF50))` (yeşil, bitki teması).
- Açık + koyu tema baştan tanımlı, `ThemeMode` profil ayarından gelir.
- Renkleri her zaman `Theme.of(context).colorScheme`'den al. Hardcode renk sadece alışkanlığın kendi rengi için.

## Saniye sayacı widget'ı (yalıtılmış)
```dart
class ElapsedTicker extends StatefulWidget {
  const ElapsedTicker({super.key, required this.since, this.style});
  final DateTime since;
  final TextStyle? style;
  @override
  State<ElapsedTicker> createState() => _ElapsedTickerState();
}

class _ElapsedTickerState extends State<ElapsedTicker> {
  late final Timer _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() { _t.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Text(
        formatElapsed(DateTime.now().difference(widget.since)),
        style: widget.style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}
```
Sadece bu küçük `Text` yeniden çizilir. `tabularFigures` sayılar değişirken metnin zıplamasını önler.

## Bitki + rüzgarda sallanma
```dart
class SwayingPlant extends StatefulWidget { ... }

class _SwayingPlantState extends State<SwayingPlant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(seconds: 3),
  )..repeat();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value * 2 * math.pi;
        // iki farklı frekans → doğal, tekdüze olmayan rüzgar
        final angle = 0.05 * math.sin(t) + 0.015 * math.sin(3 * t + 1);
        return Transform.rotate(
          angle: angle, alignment: Alignment.bottomCenter, child: child);
      },
      child: PlantImage(stage: widget.stage, wilted: widget.wilted),
    );
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
}
```
- Tohum aşamasında sallanma yok (`angle = 0`).
- **Aşama geçişi:** `AnimatedSwitcher` + `ScaleTransition` (alignment bottomCenter) ile yeni aşama yerden büyüyerek gelsin.
- **Tohum ekme animasyonu:** ilk girişte tohum yukarıdan düşer (`SlideTransition` + `Curves.bounceOut`), sonra toprak hafifçe kabarır.
- **Solgunluk:** `ColorFiltered(colorFilter: ColorFilter.matrix(<desaturate>))` + %10 aşağı eğim. Boy küçülmez.
- **Placeholder:** `assets/plant/stage_{0..4}.png` yoksa `errorBuilder` ile basit `Icon(Icons.spa)` / `Icons.eco` göster. Görsel ÜRETME.
- Bahçe ekranında her çiçek farklı faz (`phase = index * 0.7`) ve farklı süreyle sallansın, aynı anda sallanmasınlar.

## Motivasyon kartı flip
- 3 kart `Row` içinde `Expanded`. 320dp'de yazı sığmazsa kart açılınca tam genişlik `AnimatedContainer`'a büyüsün.
- Flip: `TweenAnimationBuilder<double>(tween: Tween(0, pi))` + `Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(v))`. `v > pi/2` olunca arka yüzü göster (arka yüz için ayrıca `rotateY(pi)` uygula ki yazı ters görünmesin).
- Seçim yapıldıysa: seçilen kart açık + vurgulu, diğer ikisi `Opacity(0.4)` + kilit ikonu, `onTap: null`.
- Dokunuşta `HapticFeedback.lightImpact()`.

## Alışkanlık kartı
- Sol: ikon dairesi (alışkanlık rengi). Orta: başlık + `ElapsedTicker` + 🔥 zincir. Sağ: onay butonu.
- Onay butonu: yapılmadıysa dolu buton "Bugün yaptım" (quit: "Bugün temizim"), yapıldıysa `check_circle` + "Tamamlandı". `AnimatedSwitcher` ile geçiş + `HapticFeedback.mediumImpact()`.
- Zincir 3, 7, 21, 30, 100'e ulaştığında konfeti (Faz 6).

## Onaylı silme
```dart
Dismissible(
  key: ValueKey(habit.id),
  direction: DismissDirection.endToStart,
  background: const DeleteBackground(),
  confirmDismiss: (_) => showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Alışkanlığı sil?'),
      content: Text('"${habit.title}" ve zinciri silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
      ],
    ),
  ),
  onDismissed: (_) { /* soft delete + Geri al SnackBar */ },
  child: HabitCard(habit),
);
```

## Boş durumlar
- Alışkanlık yok: tohum görseli + "İlk alışkanlığını ek 🌱" + büyük buton.
- Hata: ikon + kısa Türkçe mesaj + "Tekrar dene".
- Yükleniyor: shimmer gerekmez, `CircularProgressIndicator` yeterli.

## Yapma
- ❌ Sabit `width/height` piksel.
- ❌ Saniye sayacını üst widget'ta tutup bütün listeyi her saniye yeniden çizme.
- ❌ `AnimationController`'ı dispose etmeyi unutma.
- ❌ Görsel/Lottie dosyası uydurma.