---
name: state-management
description: Riverpod (codegen'siz) ile provider yazma kuralları. Herhangi bir provider oluştururken veya ekran state'i bağlarken oku.
---

# State Management — Riverpod (codegen YOK)

## Altın kural
Sadece 3 tip provider kullan:

| İhtiyaç | Provider |
|---|---|
| Firestore'dan canlı veri | `StreamProvider` / `StreamProvider.family` |
| Tek seferlik async iş (AI çağrısı vb.) | `FutureProvider` / `FutureProvider.family` |
| Form, seçim, küçük UI state'i | `NotifierProvider` |
| Repository / servis örnekleri | `Provider` |

`StateNotifier`, `ChangeNotifierProvider`, `StateProvider` kullanma.

## Dosya düzeni
Her feature kendi `providers.dart` dosyasına sahip. Repository provider'ları `data/repositories/` içindeki dosyanın en altında.

## Şablonlar

```dart
// data/repositories/habit_repository.dart
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(FirebaseFirestore.instance);
});

// core: oturumdaki kullanıcı
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final uidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// features/home/providers.dart
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(uid);
});

final habitLogsProvider =
    StreamProvider.family<Set<String>, String>((ref, habitId) {
  final uid = ref.watch(uidProvider)!;
  return ref.watch(habitRepositoryProvider).watchDoneDateKeys(uid, habitId);
});

// Yıllık takvim: (habitId, year) record ile family
final yearLogsProvider = FutureProvider.family<Map<String, String>,
    ({String habitId, int year})>((ref, args) {
  final uid = ref.watch(uidProvider)!;
  return ref.watch(habitRepositoryProvider)
      .fetchYearLogs(uid, args.habitId, args.year);
});
```

Record parametreli family kullanırken record'u her build'de aynı değerlerle oluştur. Record'lar değere göre eşit sayıldığı için cache doğru çalışır.

## Aksiyonlar
Butonlar repository'yi doğrudan çağırabilir, ekstra controller şart değil:

```dart
onPressed: () => ref.read(habitRepositoryProvider).markToday(uid, habit.id),
```

Stream zaten güncellendiği için UI kendiliğinden yenilenir. Manuel `invalidate` gerekmez (FutureProvider hariç).

## UI'da AsyncValue
```dart
ref.watch(habitsProvider).when(
  data: (habits) => habits.isEmpty ? const EmptyGarden() : HabitList(habits),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => ErrorView(message: 'Alışkanlıklar yüklenemedi'),
);
```

## Yapma
- ❌ `ref.watch` içinde `build` dışında okuma. Callback'lerde `ref.read`.
- ❌ Saniye sayacını provider ile yapma (bkz. `ui-responsive-animation.md`).
- ❌ Hesaplanmış istatistikleri provider'da tutup elle senkronize etme. `domain` fonksiyonlarını build içinde çağır, ucuzdur.
- ❌ `riverpod_generator`, `freezed`, `build_runner`.