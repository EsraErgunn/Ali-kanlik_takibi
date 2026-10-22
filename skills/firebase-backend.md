---
name: firebase-backend
description: Firebase kurulumu, Auth (Email + Google), Firestore repository'leri, güvenlik kuralları ve sorgular. Backend/veri katmanına dokunurken oku.
---

# Firebase Backend

## Kurulum
```bash
flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in firebase_ai
dart pub global activate flutterfire_cli
flutterfire configure
```
- Firebase Console → Authentication → **Email/Password** ve **Google** sağlayıcılarını aç.
- Android'de Google girişi için **SHA-1 ve SHA-256** parmak izlerini Firebase projesine ekle (`cd android && ./gradlew signingReport`), sonra `google-services.json`'u yeniden indir.
- `main.dart`: `WidgetsFlutterBinding.ensureInitialized(); await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

## Google ile giriş
`google_sign_in` 7.x sürümünde API değişti. Önce eklenen sürümü kontrol et.

```dart
// 7.x+
await GoogleSignIn.instance.initialize();
final account = await GoogleSignIn.instance.authenticate();
final idToken = account.authentication.idToken;
final credential = GoogleAuthProvider.credential(idToken: idToken);
await FirebaseAuth.instance.signInWithCredential(credential);
```
Eski (6.x) sürüm gelirse `GoogleSignIn().signIn()` + `accessToken/idToken` kullan. Hangisi kuruluysa ona göre yaz, iki API'yi karıştırma.

## Auth hata mesajları (Türkçe)
| code | Mesaj |
|---|---|
| `invalid-email` | E-posta adresi geçersiz. |
| `user-not-found`, `wrong-password`, `invalid-credential` | E-posta veya şifre hatalı. |
| `email-already-in-use` | Bu e-posta ile zaten bir hesap var. |
| `weak-password` | Şifre en az 6 karakter olmalı. |
| `network-request-failed` | İnternet bağlantını kontrol et. |
| diğer | Bir şeyler ters gitti, tekrar dene. |

## Repository'ler
`data/repositories/` altında: `AuthRepository`, `UserRepository`, `HabitRepository`, `MotivationRepository`. Hepsi `FirebaseFirestore` örneğini constructor'dan alır.

### Kullanıcı adı ayırma (transaction)
```dart
Future<void> claimUsername(String uid, String username) async {
  final lower = username.toLowerCase();
  final db = FirebaseFirestore.instance;
  await db.runTransaction((tx) async {
    final nameRef = db.doc('usernames/$lower');
    final userRef = db.doc('users/$uid');
    final snap = await tx.get(nameRef);
    if (snap.exists && snap['uid'] != uid) {
      throw UsernameTakenException();
    }
    final userSnap = await tx.get(userRef);
    final old = userSnap.data()?['usernameLower'] as String?;
    if (old != null && old != lower) tx.delete(db.doc('usernames/$old'));
    tx.set(nameRef, {'uid': uid});
    tx.set(userRef, {'username': username, 'usernameLower': lower},
        SetOptions(merge: true));
  });
}
```
Not: Transaction'da bütün okumalar yazmalardan önce yapılmalı.

### Bugünü işaretle (idempotent)
```dart
Future<void> markToday(String uid, String habitId) {
  final key = DateKey.today();
  return _logs(uid, habitId).doc(key).set({
    'date': key,
    'status': 'done',
    'at': FieldValue.serverTimestamp(),
  });
}
```
Geri alma: aynı dokümanı sil (sadece bugünün anahtarı için izin ver).

### Kaydım (quit)
Batch: log `status: 'relapse'` + habit `lastRelapseAt: serverTimestamp()`.

### Alışkanlıkları dinle
```dart
Stream<List<Habit>> watchHabits(String uid) => _habits(uid)
    .where('isDeleted', isEqualTo: false)
    .orderBy('createdAt')
    .snapshots()
    .map((s) => s.docs.map(Habit.fromDoc).toList());
```
Bu sorgu composite index isteyebilir. Hata mesajındaki linke tıklayıp index oluştur.

### Yıllık loglar (TEK sorgu)
```dart
Future<Map<String, String>> fetchYearLogs(String uid, String habitId, int year) async {
  final s = await _logs(uid, habitId)
      .where('date', isGreaterThanOrEqualTo: '$year-01-01')
      .where('date', isLessThanOrEqualTo: '$year-12-31')
      .get();
  return {for (final d in s.docs) d['date'] as String: d['status'] as String};
}
```

## Firestore Güvenlik Kuralları
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /usernames/{name} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.data.uid == request.auth.uid;
      allow delete: if request.auth != null
                    && resource.data.uid == request.auth.uid;
      allow update: if false;
    }
  }
}
```

## Model kuralları
- Her model: `fromDoc(DocumentSnapshot)` + `toMap()`. Elle yaz, codegen yok.
- `Timestamp` null gelebilir (serverTimestamp gecikmesi). `(data['at'] as Timestamp?)?.toDate() ?? DateTime.now()`.

## Hesap silme
Sıra: `usernames/{lower}` sil → `users/{uid}` alt koleksiyonları ve dokümanı sil → `currentUser.delete()`. `requires-recent-login` hatası gelirse kullanıcıdan tekrar giriş iste.

## Yapma
- ❌ Cloud Functions, ayrı sunucu.
- ❌ Açık kurallar (`if true`).
- ❌ Widget içinden Firestore çağrısı.