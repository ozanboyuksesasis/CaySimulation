# Çay Simülasyonu — Milestone 7

Normal oyun artık **10.000 Altın, Çiftlik Evi, Mehmet ve başlangıç yollarıyla** açılır.
`Mağaza` menüsünden tarla, alım yeri, fabrika, depo, yol ve dekoratif kuyu satın alınır.
Bedel satın alırken ödenir; yapı önce envantere girer, otomatik yerleşmez.
`Envanter → Yerleştir` ücretsizdir ve yalnız başarılı yerleştirme bir adet tüketir.
İptalde yerleştirilmemiş öğe envanterde kalır. Seçili yapıda `Taşı`
ile ücretsiz konum değiştirilebilir; stoklar ve üretim durumları korunur.

**Mobil öncelikli:** Android/iOS yatay oyun; web/Chrome geliştirme ve test içindir.
Tüm oyun eylemleri dokunma, sürükleme, pinch zoom ve açık düğmelerle kullanılabilir.
`İşletme` paneli gerçek fiziksel çay stoklarından hesaplanan salt okunur özeti gösterir;
çay envantere kopyalanmaz.

[Milestone 7 raporu: mağaza, envanter, mobil arayüz ve doğrulama](MILESTONE_7.md).

[Game Ready V3 görsel geçişi](ASSET_MIGRATION_V3.md): dört tarla durumu artık
şeffaf dış zemine sahip; 22 güvenli ayrılmış parça kaydedildi. Hasat stoğu
etiketinde dolu çuval + kg görünür. Mevcut 28 tekil görsel ve oynanış korundu.

Önceki hazır test haritası korunur: üstteki **Harita modu** menüsünden
`Test haritası (yeni oturum)` veya webde `?map=dev`. Harita değişimi yeni oturum açar;
kayıt sistemi henüz yoktur. Kamyon alım yeri kurulduğunda kullanıma açılır.

[Milestone 6 raporu: mimari, katalog, dosyalar, testler ve sınırlar](MILESTONE_6.md).

**Güncel akış:** Çay Dik → büyüme → Hasat Et → Mehmet yürür → 5 saniye hasat →
25 kg tarla stoğu → Taşıma Emri Ver → kamyon yoldan gelir → 3 saniye yükleme →
25 kg kamyon yükü → Çay Alım Yeri → 3 saniye teslimat → 25 kg alım yeri stoğu.
Tarla yükleme sonunda boşaldığı anda yeniden büyümeye başlar. Nakliye ve hasat
ayrı FIFO kuyruklarıyla aynı anda çalışır. Teslimat altın kazandırmaz.

Alım yerinde biriken çay `Fabrikaya Sevk Et` emriyle **aynı kamyonun aynı FIFO
kuyruğundan** fabrikaya taşınır. `Üretimi Başlat` emriyle **100 kg yaş çay →
10 saniyelik tek proses → 20 kg kuru çay** üretilir. Kuru çay fabrikada kalır;
üretim altın kazandırmaz. Detaylı işleme aşamaları, paketleme ve satış yoktur.

[Milestone 5 raporu: dosyalar, sevkiyat, üretim, testler ve sınırlar](MILESTONE_5.md).

Geçmiş aşamalar: [Milestone 4](MILESTONE_4.md), [Milestone 3](MILESTONE_3.md), [Milestone 2](MILESTONE_2.md).

Test haritasında üç bağımsız tarla, 250 Altınlık dikim, 18 saniyelik ilk büyüme, Mehmet ve bir
100 kg kapasiteli Çay Kamyonu vardır. Başlangıç: 10.000 Altın, tüm fiziksel stoklar
0 kg. Mehmet (6,9), kamyon Depo yakınındaki (10,7) yol karosunda başlar.
Çay Alım Yeri teslimat/sevkiyat yapar; fabrika tek üretim prosesi uygular.

Doğu Karadeniz'de geçen, Türkçe arayüzlü çevrimdışı tek oyunculu izometrik dünya prototipi.
Flutter **3.47.6 stable**, Dart **3.13.5**, Flame **1.38.2**. Flutter pub paketi olarak
değil SDK olarak kullanılır; bağımlılık çözümü `pubspec.lock` dosyasında tutulur.

## Çalıştırma

```powershell
cd C:\codespace\ai\cay_simulasyonu
flutter pub get
flutter run
```

Yerel tarayıcı: `flutter run -d chrome`. Android için bağlı cihaz/emülatör gerekir.
iOS derleme ve cihaz testi macOS/Xcode gerektirir. Android ve iOS yatay yönlendirilmiştir.
Flutter PATH'te değilse bu makinede `C:\codespace\sdk\flutter\bin\flutter.bat` kullanın.

```powershell
flutter analyze
flutter test
flutter build web
```

## Kontroller

- Fareyle veya tek parmakla sürükleme: kamerayı kaydırır.
- Fare tekerleği veya iki parmakla sıkıştırma: odak noktasında yakınlaştırır.
- Tıklama/dokunma: nesneyi ve canlı oyun panelini seçer; koordinat/footprint yalnızca ızgara açıkken görünür.
- `Mağaza`: kategori seç → `Satın Al`. Haritada nesne oluşmaz.
- `Envanter`: öğede `Yerleştir` → haritada konuma dokun → `Yerleştir`. Yeniden ödeme yoktur.
- `İşletme`: para, işletme sayıları ve fiziksel çay stokları; salt okunur.
- Yeşil önizleme geçerli, kırmızı önizleme geçersiz konumu gösterir.
- `Taşı` → yeni konum → `Onayla`; `Vazgeç` değişiklik yapmadan çıkar.
- Yol da önce 25 Altına satın alınır. Yol modunda her ayrı dokunuş envanterden bir karo tüketir;
  `Bitir`/`İptal` kalan karoları koruyarak çıkar. Önceden yerleştirilen yollar geri alınmaz.
- `Escape` / sağ tık yerleştirmeyi iptal eder; pan ve zoom tüm modlarda çalışır.
- `+`, `−`, ortalama düğmeleri: alternatif kamera kontrolleri.
- `Izgara`: koordinatlar, nesne alanları, seçili karo ve FPS.
- `Çay Dik`, `Hasat Et`, `Taşıma Emri Ver`: seçili tarla için uygun durumda görünür.
- Mehmet, kamyon ve Çay Alım Yeri seçilince durumları ve stokları canlı izlenir.
- Alım yerinde `Fabrikaya Sevk Et`; fabrikada yeterli girdi varsa `Üretimi Başlat`.

HUD başlangıçta `Altın: 10.000` gösterir. `EconomyState` içinde `canAfford`,
`spend` ve `earn` bulunur. Yetersiz bakiyede `spend` false döner; negatif tutar
ArgumentError üretir. Sıfır tutar durumu değiştirmez.

## Mimari ve dosyalar

- `lib/main.dart`: uygulama, tema ve yatay ekran.
- `lib/game/cay_game.dart`: Flame dünyasını ve bileşenleri bağlar.
- `game/models/game_config.dart`: 128×64 karo, 20×20 harita, zoom 0.25–2.0, başlangıç 0.65.
- `game/world/isometric_grid.dart`: çizimden bağımsız ileri/ters dönüşüm ve footprint.
- `game/world/prototype_map.dart`: yerleşim ve ayrılmış alanlar; üretim mantığı içermez.
- `game/camera/management_camera.dart`: kaydırma, odaklı zoom ve harita sınırları.
- `game/models/entity_definition.dart`: kimlik, tür, konum, boyut, anchor, offset, footprint.
- `game/components/`: ortak WorldEntity, önbellekli arazi çizimi ve debug katmanı.
- `game/systems/`: asset yükleme, derinlik sıralaması, A* ve ortak simülasyon saati.
- `game/world/road_tiles.dart`: yol ağı, yükleme/teslim karoları ve garaj.
- `features/plantation`: bağımsız tarla döngüsü, büyüme, hasat stoğu ve görsel eşleme.
- `features/workers`: Mehmet, FIFO hasat işleri ve akıcı yürüyüş.
- `features/transport`: kamyon modeli/bileşeni, FIFO nakliye, yükleme ve teslimat.
- `features/buildings`: yerleşimler, alım yeri ve fabrika stokları, üretim modeli/reçetesi.
- `features/economy`: çizimden bağımsız ekonomi durumu.
- `features/economy/player_inventory.dart`: yerleştirilmemiş öğeler; fiziksel ürün stoklarından ayrıdır.
- `features/shop/shop_service.dart`: satın alma ve envanter + yerleşik toplam sahiplik sınırı.
- `features/economy/resource_summary.dart`: fiziksel stokları kopyalamadan okuyan özet.
- `features/ui`: Flutter HUD ve fare/dokunma kontrolleri.
- `features/builder`: katalog, doluluk, yerleştirme doğrulaması, yapı durum makinesi ve önizleme.
- `game/world/map_setup.dart`: yeni oyun/test haritası ayrımı ve yapı-görsel adaptörü.
- `test/`: ekonomi, dönüşüm, kamera, derinlik ve gerçek assetlerle etkileşim testleri.

Mantıksal koordinat footprint'in **arka/üst köşesidir**. Nesnenin zemin noktası
ön köşeye yerleşir. Öncelik zemin Y'si, ardından X ve benzersiz kimlikle belirlenir.
`setGridPosition` sonrasında sıralama bir sonraki karede yenilenir. Karakterler
aynı dünya listesinde yer aldığı için binaların önünden/arkasından geçebilir.
Gelecekte karmaşık, içinden geçilebilir büyük binalar için görsel katmanlara bölme gerekebilir.

## Asset ekleme ve boyut ayarı

Güncel tekil nesne görsellerinin 22'si `Downloads/CAY_SIMULASYON_GAME_READY_V2.zip`
paketindeki sağlam şeffaf sürümlerdir. İlk pakette hasarlı olan 14, 15, 19, 21,
23 ve 38, kullanıcının Downloads'a sağladığı temizlenmiş PNG'lerle güncellendi.
Bu altı dosyanın tavan/kol bölgeleri sağlamdır; krem arka planları artık yoktur.
09 ve 35 sağlam V2 şeffaf sürümleridir. Tarlalar 01–04 V3 temiz sürümlerine
geçirildi. Setler 25–30, 37, 40 kaynak olarak korunur ancak artık paketlenmez.
Güvenli ayrılmış V3 parçaları `tiles/`, `items/` ve `decorations/` altında kayıtlıdır.
Bu geçişte hiçbir PNG yeniden üretilmedi, kırpılmadı
veya yeniden boyutlandırılmadı. Yedekler `dev_assets/v2_migration/` altında,
oyun paketinin dışındadır. [V2 görsel geçiş raporu](ASSET_MIGRATION_V2.md).

| Klasör (`assets/images/`) | Asset numaraları |
| --- | --- |
| `fields/` | 01–04 |
| `buildings/` | 05–10, 35–36, 39 |
| `characters/` | 15–24 |
| `vehicles/` | 13–14, 38 |
| `equipment/` | 29–34 |
| `infrastructure/` | 11–12, 25–28 |
| `products/` | 37 |
| `decorations/` | 40 |

PNG'yi ilgili klasöre koyun, EntityDefinition.assetPath alanına örneğin
`buildings/05_FARMER_HOUSE.png` yazın ve uygulamayı yeniden başlatın.
Klasörler pubspec'te tanımlıdır; alt klasör eklerseniz ayrıca tanımlayın.
`visualSize` dünya pikseli cinsindedir ve PNG çözünürlüğünden bağımsızdır.
Görsel oranı korunarak bu kutuya sığdırılır. `anchor` ve `visualOffset` ile
konum ayarlanır. `footprint` mantıksal alanı, `depthOffset` zemin sıralama ayarını
belirler; bunlar PNG boyutundan türetilmez. Eksik/bozuk görsel isimli geçici
çizime düşer, debug panelinde uyarı sayısı görünür.

## Kapsam sınırı

Milestone 7 mağaza, yerleştirilmemiş yapı envanteri ve işletme özeti ekler.
Tek işçi ve tek kamyon bulunur; çarpışma kaçınma, detaylı işleme aşamaları, paketleme, satış,
kayıt sistemi ve ekonomi dengelemesi yoktur. Çiftlik Evi ve yollar taşınmaz;
görev/üretim sırasında ilgili yapının taşınması engellenir.
Yollar ve bölge zemini geçici çizimlerdir; asset set atlasları parçalanmamıştır.
Seçim görsel kutu veya footprint üzerinden yapılır; alpha piksel testi yoktur.
Kamera sınırda tutulur, izometrik haritanın köşelerinde dış zemin görülebilir.
Web geliştirme/test hedefidir; Android/iOS ana oyun hedefidir. Mobil oyun sunucu veya ağ gerektirmez.

## Doğrulama

`flutter analyze`: sorun yok. `flutter test`: 221 test; V3 görsel alfa/yükleme/paket kapsamı,
mağaza, envanter, fiziksel özet,
1280×720 / 960×540 / 844×390 yatay güvenli alan ve dokunmatik arayüz,
yapı kataloğu, satın alma, doluluk,
ücretsiz taşıma/iptal, dinamik yollar, yeni oyun, işçi, nakliye, FIFO, kapasite,
kısmi yükleme, ham çay korunumu, fabrika sevkiyatı, reçeteye göre üretim, yol hatası, tarla döngüsü, gerçek asset yükleme,
seçim, sürükleme, tekerlek, iki parmak zoom ve 740×360 yatay HUD dahil.
`flutter build web` ve `flutter build apk --debug` başarılı; Chrome'da dokunma olaylarıyla çalıştırıldı.
M7 ekran görüntüleri `milestone7_*.png`; APK `build/app/outputs/flutter-apk/app-debug.apk`.
Bu Windows ortamında Android cihaz testi yapılmadı (mevcut emülatör çevrimdışı);
iOS çalıştırılmadı.

Sürüm kaynakları: [Flutter arşivi](https://docs.flutter.dev/install/archive),
[Flame paketi](https://pub.dev/packages/flame).
