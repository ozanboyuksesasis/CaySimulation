# Milestone 5 — Fabrika sevkiyatı ve tek üretim prosesi

## Fiziksel akış

ÇAY TARLASI → MEHMET → YAŞ ÇAY → ÇAY KAMYONU → ÇAY ALIM YERİ →
ÇAY KAMYONU → ÇAY FABRİKASI → 100 KG YAŞ ÇAY → TEK ÜRETİM PROSESİ → 20 KG KURU ÇAY

Mevcut hasat/nakliye akışı korunur. Alım yerindeki `Fabrikaya Sevk Et` düğmesi
aynı kamyona iş verir; çay anında taşınmaz. Fabrikadaki `Üretimi Başlat` düğmesi
tek parti başlatır. Sevkiyat ve üretim altın kazandırmaz. Kuru çay fabrikada kalır.

## Oluşturulan dosyalar

| Dosya | Sorumluluk |
| --- | --- |
| `lib/features/buildings/factory_config.dart` | 100 kg girdi, 20 kg çıktı, 10 saniye reçete sabitleri |
| `lib/features/buildings/tea_factory.dart` | Çizimden bağımsız fabrika, ham/kuru stok, işlemdeki parti ve üretim saati |
| `lib/features/ui/factory_info_panel.dart` | Canlı fabrika ve alım yeri sevkiyat panelleri |
| `test/factory_test.dart` | 38 kontrollü zaman testi |
| `test/factory_ui_test.dart` | Gerçek assetlerle sevkiyat, eksik girdi ve canlı üretim paneli testi |
| `test/browser_milestone5.mjs` | Gerçek Chrome tıklamaları ve geçen süreyle dört hasat → sevkiyat → üretim senaryosu |
| `MILESTONE_5.md` | Bu rapor |

## Değiştirilen dosyalar

- `lib/features/buildings/tea_collection_center.dart`: sevkiyat için doğrulamalı stok çıkarma API'si.
- `lib/features/buildings/building_prototypes.dart`: mevcut binanın adı `Çay Fabrikası` olarak tutarlılaştırıldı.
- `lib/features/transport/transport_job.dart`: kaynak/hedef türü ve kimliği, sevk miktarı; fabrika sevkiyatı kurucusu.
- `lib/features/transport/transport_system.dart`: ortak FIFO, iki rota türü, fabrika teslimatı, ham çay hesabı, hata/yeniden deneme.
- `lib/features/transport/transport_vehicle.dart`: alım yerine yükleme için gidiş ve fabrikaya gidiş durumları.
- `lib/features/ui/transport_info_panel.dart`: iş türüne göre kaynak, hedef ve Türkçe yükleme durumu.
- `lib/features/ui/game_hud.dart`: bina paneli bağlantıları ve fabrika debug bilgileri; ana HUD kalabalıklaştırılmadı.
- `lib/game/cay_game.dart`: mevcut fabrika binasına domain modeli ve sevkiyat bağlantısı.
- `lib/game/systems/world_simulation.dart`: üretimi işçi ve kamyonla aynı saatte ilerletir.
- `lib/game/world/road_tiles.dart`: fabrika teslim karosu ve beş yol karosu.
- `lib/game/components/grid_debug_component.dart`: fabrika teslim noktasının gösterimi.
- `README.md`: güncel akış, kapsam, rapor bağlantısı ve test sayısı.

## TeaFactory modeli ve üretim

Model Flame bileşeni saklamaz. Kimlik, Türkçe ad, mantıksal konum/footprint,
teslim karosu, ham stok, kuru stok, işlemdeki girdi, durum, başlangıç zamanı ve
üretim süresi taşır. `toJson()` veri görüntüsü üretir; kayıt/yükleme eklenmedi.

Durumlar `idle`, `processing`, `outputBlocked` şeklindedir. Son durum gelecek
kapasite sınırı için ayrılmıştır; bu sürümde çıktı deposu sınırsızdır. UI, idle
ve yeterli girdi durumunu `Üretime Hazır`, diğer idle durumunu `Bekliyor` gösterir.

Reçete `FactoryConfig` içindedir: **100 kg Yaş Çay → 20 kg Kuru Çay / 10 saniye**.
Soldurma, kıvırma, oksidasyon, kurutma veya tasnif ayrı oyun aşamaları değildir.
100 kg'dan az stokta üretim başlatılamaz; eksik miktar Türkçe gösterilir.

Başlatma tam 100 kg'ı rawTeaKg'dan processingInputKg'ye aktarır; hemen kuru çay
oluşturmaz. Aynı anda tek parti çalışır. On saniye dolunca parti girdisi sıfırlanır,
dryTeaKg'ye 20 eklenir ve durum idle olur. Artan süre yeni parti başlatmaz.
250 kg ham çay için iki ayrı oyuncu emriyle 40 kg kuru çay ve 50 kg ham çay kalır.
Kuru çay satılmaz, paketlenmez, otomatik başka binaya gönderilmez.

WorldSimulation üretim bitişini de olay sınırı olarak kullanır. Fabrika, kamyon
ve Mehmet aynı elapsed time ile bağımsız ilerler; saat iki/üç kere ilerlemez.
Mevcut duraklatma davranışı korunur.

## Genelleştirilen sevkiyat ve yol

**Mevcut TransportJob genelleştirildi; ikinci bir taşıma sistemi/kamyon eklenmedi.**
Kaynak/hedef `TransportLocation` enum'u, sourceId/destinationId ve istenen miktar
taşır. Eski tarla işlerinin constructor ve fieldId kullanımı korunur. Yeni
`factoryShipment` kurucusu kaynak alım yeri, hedef fabrika olacak biçimde tanımlar.

Her iki iş türü aynı TransportSystem listesine eklenir ve aynı FIFO sırasıyla
aynı araca atanır. Aktif fabrika sevkiyatı varken tekrar emir çoğaltılmaz. Sipariş
anında `min(alım yeri stoğu, kamyon kapasitesi)` belirlenir; sonradan gelen çay
bu siparişin miktarını sessizce büyütmez. 150 kg stoktan ilk sefer 100 kg taşır,
50 kg yerinde kalır. Sonraki sefer için oyuncu yeniden emir verebilir.

Yükleme ve boşaltma mevcut **3 saniyelik** sabitleri kullanır. Stok ancak aşama
başarıyla tamamlandığında aktarılır. Araç kapasitesi **100 kg**, hızı **2,5 karo/sn**,
garajı **(10,7)** olarak korunur. Teslimden sonra sıradaki iş alınır; yoksa garaja dönülür.

Fabrika mevcut **(13,11)** konumunda, **3×3** footprint ile kalır. Yeni teslim
karosu **(12,13)**, batı kenarında ve footprint'in dışındadır. Yalnızca
**(12,9)…(12,13)** arasındaki beş yol karosu eklendi; (12,8) mevcut ana yola bağlıdır.
Alım yerinin **(10,4)** karosu hem teslim hem yükleme için kullanılır. Aynı A*,
aynı yol-only geçiş kuralı uygulanır; çim kısayolu veya ışınlama yoktur.
Başlangıç bağlantı doğrulamasına alım yeri → fabrika rotası eklendi.

Fabrikaya yol yoksa `Çay Fabrikasına ulaşılacak araç yolu bulunamadı.` gösterilir;
yüklü kamyon blocked kalır ve yükü korunur. Yol geri açıldığında mevcut tekrar
deneme ile teslim edebilir. Kaynağa ulaşamayan işte alım yerinin stoğu değişmez.

## Stok muhasebesi

Ham çayın yetkili sahipleri: tarla, kamyon, alım yeri, fabrika ham deposu ve
fabrikanın işlemdeki partisidir. Global InventoryState bu zincire dahil değildir.

`totalRawTeaKg = Σ tarla stoğu + araç yükü + alım yeri stoğu + fabrika ham stoğu + işlemdeki girdi`.

Nakliye aktarımlarında toplam eşitliği kontrol edilir ve iki taraf güncellenmeden
dinleyicilere bildirim yapılmaz. Eski `totalTeaKg` API'si uyumluluk için aynı ham
toplamı verir. Kuru çay ham toplama eklenmez. Üretim başlangıcı ham miktarı korur;
bitiş **100 kg ham → 20 kg kuru** reçete dönüşümüdür. Nakliye kütle korunumu ile
ürün dönüşümü testlerde ayrı doğrulanır. Ekonomi ve eski global stok değişmez.

## Master assetler

| Nesne | Mevcut dosya |
| --- | --- |
| Çay Fabrikası | `assets/images/buildings/09_TEA_FACTORY.png` |
| Çay Alım Yeri | `assets/images/buildings/35_TEA_COLLECTION_CENTER.png` |
| Çay Kamyonu | `assets/images/vehicles/14_TEA_TRANSPORT_TRUCK.png` |
| Mehmet | `assets/images/characters/15_FARMER_MALE.png` |

Dosyalar incelendi ve mevcut PNG'ler kullanıldı; yeniden üretilmedi veya değiştirilmedi.

## Doğrulama

- `flutter analyze`: sorun yok.
- `flutter test`: **126/126 başarılı**. Önceki **87 test değiştirilmeden** geçti;
  **38 domain/sevkiyat testi + 1 arayüz testi** eklendi.
- Kapsam: stoklu/boş kaynak, çift emir, 100 kg kapasite, 150 kg kısmi sevk, yol-only
  hareket ve dış hedef, zaman sınırları, atomik aktarım, iki nakliye türünün FIFO'su,
  99/100/250 kg üretim, tek parti, tam 20 kg çıktı, altın/konum sahipliği,
  eşzamanlı işçi/kamyon/üretim, yol hatası/yük koruma/tekrar deneme, JSON ve geçersiz veri.
- `flutter build web`: başarılı. Önceki SDK CupertinoIcons tree-shaking uyarısı
  derlemeyi engellemedi.
- Chrome release sürümünde gerçek tıklamalar ve gerçek geçen süreyle iki tarla
  ikişer kez hasat edildi. Dört adet 25 kg teslimatla alım yerinde **100 kg** birikti.
  Aynı kamyon alım yerine geldi, **3 saniye** yükledi, yoldan fabrikaya gitti ve
  **(12,13)** karosunda **3 saniye** boşalttı. Fabrika ham stoğu **100 kg** oldu.
  Oyuncu emriyle üretim başladı; canlı ilerleme/süre gösterildi ve **10 saniye**
  sonunda **0 kg ham / 0 kg işlemdeki girdi / 20 kg kuru çay** oluştu. Altın iki
  ilk dikimden sonraki **9.500** değerinde kaldı. Kamyon boş olarak garaja döndü.
  Çalışma zamanı istisnası görülmedi. Teslim noktasında kamyon seçimi ayrıca
  Flutter arayüz testinde doğrulandı.
- Görseller: `milestone5_collection_100.png`, `milestone5_shipment_loading.png`,
  `milestone5_truck_to_factory.png`, `milestone5_factory_unloading.png`,
  `milestone5_factory_ready.png`, `milestone5_production_progress.png`,
  `milestone5_dry_tea.png`.
- Yerel önizleme: **http://127.0.0.1:7361**. Yeniden başlatmak için
  `flutter build web` ve `node test/serve_web.mjs`; alternatif `flutter run -d chrome`.
  Yerel doğrulama sunucusu oyun backend'i değildir.

## Sınırlar

Tek fabrika, tek kamyon, tek işçi ve tek sabit reçete vardır. Parti otomatik
başlamaz; çıktı kapasitesi uygulanmadığı için outputBlocked henüz oluşmaz.
Mevcut PNG arka planları ve görsel kutu tabanlı seçim korunur; örtüşen nesnelerin
görünür bölümüne tıklamak gerekebilir. Çarpışma kaçınma ve yön animasyonu yoktur.
Fiziksel Android/iOS cihaz testi yapılmadı. Kalıcı kayıt, paketleme, satış, bina
yerleştirme/taşıma, inşaat arayüzü ve diğer Milestone 6 işleri uygulanmadı.
