# Milestone 2 — Çay tarlası ve ilk hasat döngüsü

Mevcut Flutter/Flame mimarisi, izometrik dönüşüm, kamera, seçim, debug ızgarası
ve ekonomi korunmuştur. Üç tarla başlangıçta boştur: `(2,2)`, `(5,2)`, `(2,5)`.
Her biri 2×2 mantıksal karo kaplar. Görsel boyutu PNG çözünürlüğünden bağımsızdır.

## Durum ve zaman

`TeaFieldState`: `empty → planted → growing1 → growing2 → ready → harvested`.
Boş tarla sadece **Çay Dik** ile ekilir. İlk büyüme 5+5+8 saniye sürer.
Hasattan 5 saniye sonra `growing1` aşamasına döner ve 5+8 saniyede tekrar hazır olur.
Hazır tarla oyuncu hasat edene kadar bekler; otomatik ürün veya altın üretmez.

Tüm süreler, 250 Altın dikim bedeli ve 25 kg ürün `plantation_config.dart` içindedir.
`PlantationSystem` mevcut `EconomyState` örneğini kullanır; alternatif bir bakiye
tutmaz. Hasat yalnızca `InventoryState.freshTeaKg` değerini artırır. Yeniden büyüme
ücretsizdir. Yanlış durumda dikim/hasat ve tekrarlı tıklamalar işlem oluşturmaz.

Zaman Flame `dt` değerinden ilerleyen **simülasyon zamanıdır**. Tarla başına durum,
başlama zamanı, dikim zamanı, ilerleme ve hasat sayısı ayrı tutulur. Uzun bir kare
birden fazla aşamayı doğru zaman sınırlarıyla geçebilir. Arka plana alındığında
oyun ve büyüme durur. `toJson()` yalnızca veri görüntüsü üretir; kayıt/yükleme yoktur.

## Oluşturulan dosyalar

- `lib/features/plantation/tea_field.dart`: rendering nesnesi içermeyen alan modeli.
- `plantation_config.dart`: geliştirme dengesi ve süreler.
- `plantation_system.dart`: dikim/hasat işlemleri, ortak zaman ilerletme.
- `field_visuals.dart`: durum → PNG ve Türkçe durum isimleri.
- `tea_field_component.dart`: modele bağlı sprite, durum rozeti, hazır işareti.
- `lib/features/economy/inventory_state.dart`: yaş çay miktarı.
- `lib/features/ui/field_info_panel.dart`: dikim/hasat, sayaç ve ilerleme çubuğu.
- `test/plantation_test.dart`, `test/harvest_ui_test.dart`: alan ve UI testleri.
- `test/browser_milestone2.mjs`: gerçek Chrome arayüzünde, gerçek süreyle kontrol.

Değişenler: `cay_game.dart`, `world_entity.dart`, `plantation_prototype.dart`,
`building_prototypes.dart`, `prototype_map.dart`, `game_hud.dart`, mevcut smoke testi.
`README.md` güncel milestone rehberine yönlendirir. Yeni paket eklenmemiştir.

## Master asset eşlemesi

Gerçek pakette tarlalar 01–04'tür; 05–08 bina assetleridir. Bu nedenle alternatif
paket numaralarını kullanarak ev veya depoyu tarla durumuna atamak doğru değildir.
Hiçbir PNG yeniden üretilmedi, değişmedi veya yeniden adlandırılmadı.

| Gerçek dosya (`assets/images/`) | Oyun nesnesi | Mevcut kullanım | Gelecekteki kullanım |
| --- | --- | --- | --- |
| `fields/01_FIELD_EMPTY.png` | Çay Tarlası | EMPTY / Boş | Hazırlanmış tarla |
| `fields/02_FIELD_PLANTED.png` | Çay Tarlası | PLANTED; geçici HARVESTED | Dikilmiş tarla; özel hasat sonrası asset geldiğinde ayrılır |
| `fields/03_FIELD_GROWING.png` | Çay Tarlası | GROWING_1 ve GROWING_2 | Büyüme görselleri; ayrı aşama assetleri geldiğinde ayrılır |
| `fields/04_FIELD_HARVEST.png` | Çay Tarlası | READY / Hasada Hazır | Hasat edilebilir tarla |
| `buildings/05_FARMER_HOUSE.png` | Çiftlik Evi | Haritada, doğru isimle seçilebilir | Tarımsal oyuncu binası |
| `buildings/06_TEA_WAREHOUSE.png` | Depo | Yol kenarında görsel yerleşim | Depolama / sevkiyat |
| `buildings/35_TEA_COLLECTION_CENTER.png` | Çay Alım Yeri | Haritada **bir adet**, `(11,3)`, Açık / 0 kg | Yaş çay teslim, tartım ve kabul noktası |
| `buildings/09_TEA_FACTORY.png` | Çay fabrikası | Milestone 1 konumunda görsel yerleşim | Çay işleme |
| `buildings/39_MARKET.png` | Pazar | Milestone 1 konumunda görsel yerleşim | Satış |
| `vehicles/14_TEA_TRANSPORT_TRUCK.png` | Çay nakliye kamyonu | Sabit örnek | Yaş çay taşıma |
| `characters/15_FARMER_MALE.png` | Çay üreticisi | Sabit örnek | Üretici / hasat işleri |
| `infrastructure/12_VILLAGE_WELL.png` | Köy kuyusu | Sabit örnek | Tarımsal su kaynağı |

Çay Alım Yeri'nin paneli `Durum: Açık` ve `Teslim Alınan Yaş Çay: 0 kg` gösterir.
Bu sıfır değeri bu milestone için sabit bilgilendirmedir; oyuncunun çay envanteri
teslimat değildir ve bu binaya aktarılmaz. Diğer bina/araç/işçi sistemleri yoktur.

## Test ve kontrol

14 yeni domain testi: dikim, kesin maliyet, yetersiz bakiye, sınır zamanları,
hazır durumu, kesin ürün miktarı, envantere ekleme, hasat durumu, üç bağımsız tarla,
tek ekonomi kaynağı, tekrar işlem engeli, ücretsiz yeniden büyüme, büyük zaman adımı,
JSON uyumlu veri ve geriye zaman engeli.

1 yeni gerçek assetli widget testi: HUD, tüm panel durumları, sprite eşlemesi,
yeniden seçim olmadan güncelleme, yetersiz altın mesajı, envanter, üç farklı durum,
Çay Alım Yeri paneli ve 740×360 yatay görünüm. Önceki 9 test korunmuştur.

```powershell
flutter analyze
flutter test
flutter build web
flutter run -d chrome --web-port 7359
```

Sonuç: analiz temiz, **24/24 test başarılı**, web release derlemesi başarılı.
Chrome release sürümünde gerçek süre ve gerçek tıklamalarla başlangıç 10.000 Altın,
dikim sonrası 9.750 Altın, otomatik büyüme, hasat sonrası 25 kg Yaş Çay ve yeniden
büyüme doğrulandı. Üç farklı tarla durumu aynı anda gözlendi. Çay Alım Yeri paneli
doğrulandı. Tarayıcı kontrolünde çalışma zamanı istisnası görülmedi.

`milestone2_ready.png`, `milestone2_harvested.png` ve `milestone2_collection.png`
görsel kontrol çıktılarıdır. 40 kaynak PNG, ZIP içindeki karşılığıyla SHA-256
olarak birebir eşleşir. Mobil fiziksel cihaz testi bu ortamda yapılmadı.

Tekrarlanabilir release tarayıcı kontrolü için `flutter build web` ardından
`node test/serve_web.mjs` yalnızca yerel test dosyalarını sunar. Uygulamanın
çalışırken kullandığı bir backend değildir. Chrome'u bu yerel adreste hata
ayıklama portuyla açıp `node --experimental-websocket test/browser_milestone2.mjs
PORT release` komutunu kullanabilirsiniz. Bu yardımcı oyun durumuna doğrudan
müdahale etmez; düğmelere basar ve gerçek süreyi bekler.

## Sınırlar

Altı durum için dört kaynak görsel vardır: iki büyüme aşaması aynı PNG'yi paylaşır;
durum rozeti/panel aşamayı ayırt eder. Hasat sonrası görsel geçici olarak dikilmiş
tarla görselidir. Kaynak PNG'lerin mevcut arka planları korunur. Durumlar yalnızca
oturum boyunca yaşar; yeniden başlatınca sıfırlanır. Kapalıyken büyüme, kayıt/yükleme,
işçi hareketi, taşıma, teslimat, işleme, satış veya ekonomi zinciri eklenmemiştir.
