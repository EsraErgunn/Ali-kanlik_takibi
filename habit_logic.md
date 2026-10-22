---
name: habit-logic
description: Zincir, haftalık/aylık yüzde, güç skoru, saniye sayacı, bitki aşaması ve yıllık takvim hesapları için saf fonksiyonlar ve testler. Herhangi bir tarih/istatistik hesabı yazarken oku.
---

# Alışkanlık Mantığı (Domain)

Bütün fonksiyonlar `lib/domain/` altında, **saf** (Firebase, Flutter widget, `DateTime.now()` bağımlılığı yok). `today` her zaman parametre olarak gelir. Böylece test edilir.

## Tarih anahtarı — `core/utils/date_key.dart`
```dart
class DateKey {
  static final _f = DateFormat('yyyy-MM-dd');
  static String of(DateTime d) => _f.format(DateTime(d.year, d.month, d.day));
  static String today() => of(DateTime.now());
  static DateTime parse(String k) => DateTime.parse(k); // yerel gece yarısı
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  /// DST'den etkilenmeyen gün ekleme
  static DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
}
```
❌ `d.add(Duration(days: 1))` kullanma (DST günlerinde kayar). ✅ `DateKey.addDays`.
❌ Gün farkını `difference().inDays` ile hesaplama. ✅ Aşağıdaki `daysBetween`.

```dart
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day)).inDays;
```
(Burada UTC sadece tarih farkı için kullanılır. Saatler sıfırlandığı için DST etkisi yok.)

## Girdi tipi
```dart
/// key: yyyy-MM-dd, value: 'done' | 'relapse'
typedef LogMap = Map<String, String>;
bool isDone(LogMap logs, DateTime d) => logs[DateKey.of(d)] == 'done';

/// Zinciri sürdüren gün: done veya frozen (kalkan). Yüzde/skor için sadece isDone.
bool keepsChain(LogMap logs, DateTime d) {
  final s = logs[DateKey.of(d)];
  return s == 'done' || s == 'frozen';
}
```
`partial` (count tipinde hedefin altı) ve `relapse` zinciri **kırar**.

## Aktif zincir
```dart
int currentStreak(LogMap logs, DateTime today) {
  var day = keepsChain(logs, today) ? today : DateKey.addDays(today, -1);
  var count = 0;
  while (keepsChain(logs, day)) {
    if (isDone(logs, day)) count++;   // frozen gün zinciri taşır ama sayıya eklenmez
    day = DateKey.addDays(day, -1);
  }
  return count;
}
```
Bugün henüz yapılmadıysa zincir dünden sayılır, gün bitene kadar kopmaz.

## XP ve Seviye
```dart
int totalXp(int totalDone) => totalDone * 10;

({int level, String title, double progress}) levelFor(int xp) {
  const thresholds = [0, 100, 300, 600, 1000, 1500, 2500];
  const titles = ['Tohum', 'Filiz', 'Bahçıvan', 'Usta Bahçıvan',
                  'Bahçe Bilgesi', 'Orman Koruyucu', 'Efsane Bahçıvan'];
  var i = thresholds.lastIndexWhere((t) => xp >= t);
  final next = i + 1 < thresholds.length ? thresholds[i + 1] : thresholds[i];
  final p = next == thresholds[i] ? 1.0 : (xp - thresholds[i]) / (next - thresholds[i]);
  return (level: i + 1, title: titles[i], progress: p);
}
```

## Kalkan (joker) uygulama
Saf fonksiyon: `List<String> habitsToFreeze(Map<String, LogMap> logsByHabit, DateTime today, int shields)` → dünü kaçırılmış ve zinciri ≥3 olan alışkanlıkları en uzun zincirden başlayarak `shields` adet döndürür. Yazma işlemini repository batch ile yapar (log `frozen` + `shields` azalt). Uygulama açılışında **günde bir kez** çalışır (`users.lastShieldCheck` = bugünün anahtarı).

## Count tipi
`status = count >= dailyTarget ? 'done' : 'partial'`. Kart ilerlemesi `count / dailyTarget` (maks 1).

## Tasarruf (quit)
`cleanDays` = startDate'ten (veya son relapse'ten değil, **bütün zaman**) bugüne kadar `done` gün sayısı. `saved = cleanDays * unitsPerDay * unitPrice`, `avoided = cleanDays * unitsPerDay`.

## En uzun zincir
Log anahtarlarını sırala, ardışık günleri say, maksimumu döndür.

## Yüzdeler
```dart
double completionRate(LogMap logs, DateTime from, DateTime to, DateTime start, DateTime today) {
  final s = [from, start].reduce((a, b) => a.isAfter(b) ? a : b);
  final e = [to, today].reduce((a, b) => a.isBefore(b) ? a : b);
  if (s.isAfter(e)) return 0;
  var total = 0, done = 0;
  for (var d = s; !d.isAfter(e); d = DateKey.addDays(d, 1)) {
    total++;
    if (isDone(logs, d)) done++;
  }
  return total == 0 ? 0 : done / total;
}
```
- Haftalık: `from` = bu haftanın pazartesisi (`DateKey.addDays(today, -(today.weekday - 1))`), `to` = pazar.
- Aylık: `from` = ayın 1'i, `to` = ayın son günü (`DateTime(y, m + 1, 0)`).

## Güç skoru (çizgi grafik)
```dart
List<int> strengthSeries(LogMap logs, DateTime start, DateTime today) {
  final result = <int>[];
  var score = 0;
  final lastDay = isDone(logs, today) ? today : DateKey.addDays(today, -1);
  for (var d = DateKey.dateOnly(start); !d.isAfter(lastDay); d = DateKey.addDays(d, 1)) {
    score = isDone(logs, d) ? score + 1 : (score - 1).clamp(0, 1 << 30);
    result.add(score);
  }
  return result;
}
```
Grafikte son 30 değeri göster.

## Haftalık sütunlar
Son 8 haftanın her biri için (pazartesi–pazar) `done` sayısı → `List<int>` (uzunluk 8, eskiden yeniye).

## Saniye sayacı
```dart
Duration elapsedFor(Habit h, DateTime now) =>
    now.difference(h.type == HabitType.quit ? (h.lastRelapseAt ?? h.startDate) : h.startDate);

String formatElapsed(Duration d) {
  final days = d.inDays;
  final h = d.inHours % 24, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${days}g ${two(h)}s ${two(m)}d ${two(s)}sn';
}
```

## Bitki aşaması — `domain/plant_stage.dart`
```dart
enum PlantStage { seed, sprout, stem, bud, flower }

({PlantStage stage, int completedCycles}) plantFor(DateTime gardenStart, DateTime today) {
  final days = daysBetween(gardenStart, today);
  final inCycle = days % 30;
  final stage = switch (inCycle) {
    0 => PlantStage.seed,
    <= 3 => PlantStage.sprout,
    <= 10 => PlantStage.stem,
    <= 20 => PlantStage.bud,
    _ => PlantStage.flower,
  };
  return (stage: stage, completedCycles: days ~/ 30);
}
```
Solgunluk: `bool isWilted` = dün hiçbir aktif alışkanlıkta `done` yoksa true (ilk gün hariç).

## Yıllık zincir takvimi verisi
```dart
enum DayMark { none, done, relapse, missed, future, beforeStart, today }

class CalendarDay {
  final DateTime date;
  final DayMark mark;
  final bool linkLeft;   // önceki gün done ve bugün pazartesi değil
  final bool linkRight;  // sonraki gün done ve bugün pazar değil
  final bool continuesNextRow; // pazar done + ertesi pazartesi done
  final bool continuesPrevRow; // pazartesi done + önceki pazar done
  final bool isToday;
}

List<CalendarDay> buildMonth(int year, int month, LogMap logs, DateTime start, DateTime today);
```
Kurallar:
- `done` olan günler için: `linkRight = isDone(next) && date.weekday != 7`, `linkLeft = isDone(prev) && date.weekday != 1`.
- Satır kırılımı (pazar → pazartesi) ardışık done ise: `continuesNextRow` / `continuesPrevRow` bayrakları true olur. UI satır sonu/başında küçük halka ucu çizer.
- Ay sınırında bağlantı çizilmez.
- `isToday` ayrı bayrak. Bugün `done` ise hem X hem halka gösterilir.
- Yıl özeti: `doneCount`, `eligibleDays` (start ile min(today, 31 Aralık) arası), yüzde, yıl içindeki en uzun zincir.

## Testler — `test/domain/` (ZORUNLU)
En az şu senaryolar:
- Zincir: bugün yapıldı / yapılmadı / dün kırıldı / boş log.
- DST geçişini kapsayan tarih aralığında `addDays` ve `daysBetween` doğru.
- Haftalık % startDate hafta ortasındayken doğru payda.
- Güç skoru 0'ın altına inmiyor.
- `buildMonth`: pazar–pazartesi geçişinde `linkRight` false ve `continuesNextRow` true.
- `plantFor`: gün 0, 3, 4, 29, 30, 61.