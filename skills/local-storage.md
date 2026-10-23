---
name: local-storage
description: Hive (hive_ce) yerel veri saklama, kutular (boxes), anahtar formatları, watch reaktivitesi ve bahçe sıfırlama rehberi.
---

# Yerel Veri Saklama (Hive Local Storage)

Uygulama tüm verilerini cihazda yerel olarak `hive_ce` ve `hive_ce_flutter` paketleri ile saklar. Uzak sunucu veya Firebase kullanılmaz; hesap, şifre ve oturum açma yoktur.

Codegen (`build_runner`, `TypeAdapter`) KULLANILMAZ. Hive kutularında doğrudan Map / JSON veri saklanır ve modellerin `toMap()` / `fromMap()` metotları kullanılır.

---

## 1. Hive Kutuları (Boxes)

`HiveService` singleton sınıfı uygulama başlangıcında (`main.dart`) başlatılır ve 5 ana kutuyu yönetir:

| Kutu Adı | Tip / Değer | Amaç |
|---|---|---|
| `profile` | `Map<String, dynamic>` | Tek kayıt (`current` anahtarı): `{username, characterId, gardenStartDate, shields, lastShieldCheck, themeMode}` |
| `habits` | `Map<String, dynamic>` | Key = `habitId` (uuid/timestamp). Alışkanlık tanımı ve ayarları |
| `logs` | `Map<String, dynamic>` | Key = `habitId\|yyyy-MM-dd`. Günlük tamamlama veya relapse kayıtları (gün başına tek kayıt garantisi key ile sağlanır) |
| `motivation` | `Map<String, dynamic>` | Key = `yyyy-MM-dd`. Günün motivasyon kartları ve seçim durumu |
| `settings` | `dynamic` | `has_profile` gibi bayraklar ve yerel tercihler |

---

## 2. Anahtar Formatları (Key Schemes)

- **Profil:** `'current'`
- **Alışkanlıklar:** `habit.id` (örnek: `'h_1729689400000'`)
- **Günlük Loglar:** `'$habitId|$dateKey'` (örnek: `'h_123|2026-10-23'`)
  - Bu bileşik anahtar yapısı sayesinde aynı alışkanlık için aynı güne asla mükerrer kayıt girilemez.
- **Yıllık Takvim Filtreleme:** `'$habitId|$year-'` ön ekiyle `logs` kutusunda anahtar taraması yapılır (örnek: `h_123|2026-`).
- **Günün Motivasyonu:** `DateKey.today()` (örnek: `'2026-10-23'`)

---

## 3. Reaktivite ve Riverpod (`box.watch()`)

Riverpod `StreamProvider`'lar Hive'ın reaktif `watch()` akışını dinler. Başlangıçta kutudaki mevcut veri `yield` edilir, ardından kutudaki her değişiklik otomatik olarak arayüze yansıtılır:

```dart
// Alışkanlık listesi akışı
Stream<List<Habit>> watchHabits([String? uid]) async* {
  yield _getHabitsList(isDeleted: false);
  yield* HiveService.instance.habitsBox.watch().map((_) => _getHabitsList(isDeleted: false));
}

// Alışkanlığın log akışı
Stream<LogMap> watchDoneDates(String uid, String habitId) async* {
  yield _getDoneDates(habitId);
  yield* HiveService.instance.logsBox.watch().where((event) {
    final key = event.key?.toString() ?? '';
    return key.startsWith('$habitId|');
  }).map((_) => _getDoneDates(habitId));
}
```

---

## 4. Bahçeyi Sıfırlama / Çıkış

Kullanıcı "Çıkış Yap / Bahçeyi Sıfırla" eylemini onayladığında:
1. `NotificationService.instance.cancelAll()` ile planlanmış yerel bildirimler iptal edilir.
2. `HiveService.instance.clearAll()` ile bütün Hive kutuları (`profile`, `habits`, `logs`, `motivation`, `settings`) temizlenir.
3. Uygulama `ProfileStateNotifier` üzerinden `/welcome` (Karşılama Ekranı) rotasına yönlendirilir.
