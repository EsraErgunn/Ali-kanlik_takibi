import 'dart:math';
import '../../data/models/support_message.dart';

const List<SupportMessage> fallbackSupportList = [
  SupportMessage(
    message: 'Bugüne kadar kazandığın temiz günler yok olmadı; bedenine ve zihnine verdiğin mola hala seninle.',
    nextStep: 'Büyük bir bardak soğuk su iç ve 5 derin nefes al.',
  ),
  SupportMessage(
    message: 'Bir adım geri atmış olmak, yürüdüğün onca yolu silmez. İyileşme doğrusal değil, dalgalı bir yolculuktur.',
    nextStep: 'Pencereyi açıp 2 dakika boyunca dışarıdaki havayı içine çek.',
  ),
  SupportMessage(
    message: 'Kendine karşı acımasız olma. Önemli olan düştüğün an değil, ayağa kalktığın şu anki kararlılığın.',
    nextStep: 'Oturduğun yeri değiştir ve omuzlarını yavaşça geriye doğru esnet.',
  ),
  SupportMessage(
    message: 'Zincir kırılmış gibi hissettirse de irade kasın güçlendi. Birikmiş tüm emeklerin hala senin içinde.',
    nextStep: 'Telefonunu bir kenara bırakıp ellerini ve yüzünü ılık suyla yıka.',
  ),
  SupportMessage(
    message: 'Bugün sadece küçük bir sarsıntı yaşadın, rotan hala aynı. Kendini affet ve yeni sayacına güven.',
    nextStep: 'Bulunduğun odadan çıkıp kısa bir tur at, suyunu tazele.',
  ),
  SupportMessage(
    message: 'Her temiz günün beyninde yeni yollar açtı. Bir anlık dalgınlık o yolları tamamen kapatamaz.',
    nextStep: 'Bir sonraki isteği sadece 10 dakika ertele ve bekle.',
  ),
  SupportMessage(
    message: 'Toprağa düşen tohum ölmez, yeniden filizlenir. Sabırla ve şefkatle yeniden başlayabilirsin 🌱',
    nextStep: 'Gözlerini kapatıp 1 dakika boyunca sadece nefesine odaklan.',
  ),
  SupportMessage(
    message: 'Geçmişteki başarın tesadüf değildi; bunu sen başardın ve yine aynı güçle başarabilirsin.',
    nextStep: 'Hemen temiz bir kağıda aklından geçen tek bir duyguyu yaz.',
  ),
  SupportMessage(
    message: 'Kendini suçlamak sadece yorgunluk getirir. Derin bir nefes al; yolculuğun tam şu an devam ediyor.',
    nextStep: 'Ilık bir bitki çayı hazırla ve yavaş yavaş yudumla.',
  ),
  SupportMessage(
    message: 'Bir kere tökezlemek başarısızlık değildir; vazgeçmediğin sürece hedefine doğru ilerliyorsun.',
    nextStep: 'Balkona veya kapı önüne çıkıp 10 derin nefes al.',
  ),
  SupportMessage(
    message: 'Buraya kadar geldiğin günler hafızanda ve hücrelerinde kayıtlı. Şimdi sadece bir sonraki adımı düşün.',
    nextStep: 'Omuzlarını serbest bırak ve ayak tabanlarını yere sağlam bas.',
  ),
  SupportMessage(
    message: 'Bu an bir yenilgi değil, sadece yolun üzerindeki küçük bir çakıl taşı. Rotanı düzelt ve ilerle.',
    nextStep: 'Bir bardak su doldur ve içine küçük bir dilim limon at.',
  ),
  SupportMessage(
    message: 'Dürüstlüğün ve kaydını girmen ne kadar cesur olduğunu gösteriyor. İyileşme dürüstlükle başlar.',
    nextStep: 'En sevdiğin sakinleştirici bir şarkıyı aç ve dinle.',
  ),
  SupportMessage(
    message: 'Kusursuzluk değil süreklilik arıyoruz. Bu küçük sapma genel başarı tablonu gölgeleyemez.',
    nextStep: 'Kısa bir esneme hareketi yap ve kollarını yukarı uzat.',
  ),
  SupportMessage(
    message: 'Bugüne kadarki gayretin silinmedi, hepsi hanene yazıldı. Şimdi sadece bugünü sakinlikle tamamla.',
    nextStep: 'Derin bir nefes vererek tüm kaslarını gevşet.',
  ),
  SupportMessage(
    message: 'Ağaçlar da fırtınada yaprak döker ama kökleri yerinde kalır. Sen de köklerine güven ve devam et.',
    nextStep: 'Ellerini kalbinin üstüne koy ve 3 kez yavaşça nefes al.',
  ),
];

SupportMessage getFallbackSupport(String dateKey, String habitId) {
  // Deterministic seed based on dateKey and habitId
  final seed = (dateKey.hashCode ^ habitId.hashCode).abs();
  final random = Random(seed);
  return fallbackSupportList[random.nextInt(fallbackSupportList.length)];
}
