---
name: notifications
description: Alışkanlık başına özelleştirilebilir yerel hatırlatmalar (saat + gün seçimi), izinler ve iptal. Hatırlatma özelliğinde çalışırken oku. Faz 6 — zaman kalırsa.
---

# Kişiselleştirilebilir Hatırlatmalar

Sunucu yok, push yok. Sadece **yerel bildirimler**.

## Paketler
```bash
flutter pub add flutter_local_notifications timezone flutter_timezone
```

## Başlatma (`services/notification_service.dart`)
```dart
Future<void> init() async {
  tz.initializeTimeZones();
  final name = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(name));
  await _plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));
}
```
`flutter_timezone`'un yeni sürümleri `String` yerine bir nesne döndürebilir. Kurulu sürüme göre `.identifier` kullan.

## İzinler
- Android 13+: `POST_NOTIFICATIONS` izni → plugin'in `requestNotificationsPermission()` fonksiyonu.
- iOS: `requestPermissions(alert: true, badge: true, sound: true)`.
- İzin, kullanıcı **ilk hatırlatma kurduğunda** istenir. Uygulama açılışında değil.
- **Exact alarm izni isteme.** `AndroidScheduleMode.inexactAllowWhileIdle` kullan (birkaç dakika sapma kabul edilebilir).

## Hatırlatma tablosu (UI)
Alışkanlık ekleme/detay sayfasında:
- Saat seçici (`showTimePicker`).
- Gün çipleri: P S Ç P C C P (`FilterChip`, çoklu seçim). Hazır kısayollar: "Her gün", "Hafta içi", "Hafta sonu".
- Aç/kapat anahtarı.
- Profil → Bildirimler: genel anahtar (kapalıysa bütün bildirimler iptal).

## Zamanlama
Her (alışkanlık, gün) için ayrı tekrarlayan bildirim:
```dart
int notifId(String habitId, int weekday) =>
    (habitId.hashCode & 0x7ffffff) * 10 + weekday; // pozitif, benzersiz

Future<void> scheduleHabit(Habit h) async {
  await cancelHabit(h.id);
  if (h.reminderTime == null) return;
  final [hh, mm] = h.reminderTime!.split(':').map(int.parse).toList();
  for (final wd in h.reminderDays) {
    await _plugin.zonedSchedule(
      notifId(h.id, wd),
      h.title,
      _body(h),
      _nextInstance(wd, hh, mm),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}

Future<void> cancelHabit(String id) async {
  for (var wd = 1; wd <= 7; wd++) {
    await _plugin.cancel(notifId(id, wd));
  }
}
```
Plugin sürümüne göre `zonedSchedule` parametreleri named olabilir. Kurulu sürümün API'sine uy.

`_body`: build → "Zincirin 🔥 {streak} gün. Bugünü de ekle!", quit → "{elapsed} gündür güçlüsün 💪".

## Ne zaman yeniden zamanla
- Alışkanlık eklenince / hatırlatma düzenlenince → `scheduleHabit`.
- Silinince → `cancelHabit`. Geri alınınca → tekrar `scheduleHabit`.
- Uygulama açılışında (giriş yapıldıysa) → bütün aktif alışkanlıklar için bir kez `scheduleHabit` (cihaz değişimi/yeniden kurulum).
- Çıkış yapınca → `cancelAll()`.

## Yapma
- ❌ FCM / push / Cloud Functions.
- ❌ `SCHEDULE_EXACT_ALARM` izni.
- ❌ İzni uygulama ilk açıldığında istemek.
- ❌ Silinen alışkanlığın bildirimini bırakmak.