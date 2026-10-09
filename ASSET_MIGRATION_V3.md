# Game Ready V3 — kontrollü görsel geçişi

Milestone 8 başlatılmadı. Harita, ekonomi, mantıksal footprint, koordinatlar,
etkileşim noktaları, yol bulma ve üretim/hasat/nakliye modelleri değiştirilmedi.

## Envanter ve karar özeti

Arşiv: `Downloads/CAY_SIMULASYON_GAME_READY_V3.zip`. Manifest 47 ayrılmış parça
tanımlar; ayrıca 4 temiz tarla görseli vardır. 40 orijinal ve 40 şeffaf master
kopyası geliştirme arşivinde tutulur. **51 adaydan 26 kabul, 25 ret.**

| Grup | Kabul | Ret | Şimdiki kullanım |
| --- | ---: | ---: | --- |
| Tarla durumları | 4 | 0 | Tüm tarla çizimleri, mağaza/envanter ve önizleme |
| Yol kaynak parçaları | 4 | 3 | Düz parça katalog küçük resmi; diğerleri kayıtlı |
| Taş patikalar | 3 | 3 | İlerisi için kayıtlı |
| Duvar | 0 | 1 | Kullanılmıyor |
| Dere | 0 | 3 | Kullanılmıyor |
| Çuvallar | 5 | 0 | Dolu çuval tarla stok etiketinde |
| Sepetler | 6 | 0 | İlerisi için kayıtlı |
| Paketler | 0 | 7 | Kullanılmıyor |
| Dekorasyon | 4 | 8 | İlerisi için kayıtlı |

Mevcut **28 sağlam tekil bina/karakter/araç/ekipman PNG'si değiştirilmedi**.
V3 şeffaf kopyaları bunlarla birebir aynı; kullanıcının düzelttiği altı dosya korunur.

## Tarlalar

| Durum | Kullanılan V3 dosyası |
| --- | --- |
| EMPTY | `fields/01_FIELD_EMPTY.png` |
| PLANTED | `fields/02_FIELD_PLANTED.png` |
| GROWING_1 / GROWING_2 | `fields/03_FIELD_GROWING.png` |
| READY | `fields/04_FIELD_HARVEST.png` |
| HARVESTED / yeniden büyüme | `fields/02_FIELD_PLANTED.png` |

Dördü de kabul edildi. Toprak, çay çalıları, taş duvar, merdiven/yol ve zemine
ait ayrıntılar korunur; dış krem dikdörtgen şeffaftır. PNG'ler birebir kopyalandı,
yeniden üretilmedi veya düzenlenmedi. Anchor, görsel ölçek ve offset değişmedi.
Kimlik, 2×2 alan, dikim bedeli, büyüme süresi, 25 kg ürün ve görev davranışı aynı.
Mevcut `BoxFit.contain` mağaza/envanterde de oranı korur.

## Yollar

Kabul edilenler (`tiles/roads/`):

- `road_straight_horizontal.png`: güvenli sahne parçası; Toprak Yol küçük resmi.
- `road_gate.png`: tek parça çit/kapı çevresi, gelecek dekor kullanımı.
- `road_shrub.png`: yol kenarı bitki parçası.
- `road_tree_small.png`: yol kenarı ağaç parçası.

**Komşulara göre otomatik yol görseli seçimi aktif değil.** Kaynaklar ortak
izometrik karo uçları olan modüler bir düz/viraj/T/kavşak/uç seti oluşturmuyor;
ağaç ve çitler bağlantı uçlarını kapatıyor. Mevcut genel yol çizimi ve mantıksal
yol bağlantıları korunur. Bu parçalar araba yolu verisi olarak yorumlanmaz.

Reddedilenler:

| Dosya | Neden |
| --- | --- |
| `road_curve.png` | Adındaki viraj yerine birleşik T-yol/ağaç/çit sahnesi; bağlantı anlamı belirsiz |
| `road_straight_vertical.png` | Sağ üstte komşu nesne kırpıntısı ve yol ucunda ağaç |
| `road_tree_large.png` | Sol kenarda komşu yol/çit şeridi |

## Patika / duvar / dere

Kabul edilen patikalar (`tiles/paths/`): `path_platform.png`,
`path_raised_platform.png`, `path_steps.png`. Mevcut kataloğa yeni satın alma
öğesi eklenmedi; merkezi görsel kaydında sonraki kullanım için hazırlar.

| Reddedilen dosya | Neden |
| --- | --- |
| `path_junction_cross.png` | Sol merdiven, sağ platform ve altta komşu kırpıntıları |
| `path_vertical.png` | Sağda kopuk kaynak parçaları; temiz ayrıştırma belirsiz |
| `path_vertical_stairs.png` | Sağdaki kopuk kırpıntılar nedeniyle güvenli değil |
| `stone_wall_enclosure.png` | Masterdaki sol/sağ duvar uçları kesilmiş; iç krem alan kalmış |
| `stream_waterfall_source.png` | Sağ altta komşu kıyı ve kesilmiş akarsu birleşimi |
| `stream_waterfall_end.png` | Sol üstte komşu kıyı kırpıntısı |
| `stream_winding.png` | Solda/altta komşu şelale ve ada parçaları |

Duvar veya dere kaynakları runtime'a alınmadı. Yeni engel, su veya yaya mekaniği yok.

## Çuvallar ve sepetler

Kabul edilen çuvallar (`items/tea_sacks/`):

- `tea_sack_empty_folded.png`
- `tea_sack_spilling.png`
- `tea_sack_quarter.png`
- `tea_sack_half.png`
- `tea_sack_full.png`

**Dolu çuval**, `harvestedStockKg > 0` iken tarla etiketinde küçük simge olarak
görünür; mevcut kg metni kalır. Yeni stok veya envanter oluşturmaz. Diğer
varyantların adları kaynak adlarıdır; doluluk miktarına ilişkin yeni kural yoktur.

Kabul edilen sepetler (`items/tea_baskets/`):

- `tea_basket_empty_small.png`
- `tea_basket_empty_large.png`
- `tea_basket_back_full.png`
- `tea_basket_quarter.png`
- `tea_basket_half.png`
- `tea_basket_full.png`

Sepetler yalnız kayıtlıdır; taşıma/işçi animasyonu eklenmedi.

## Paketler

Kabul edilen yok. Yedi dosyanın tümünde üst üste binen komşu kutular, kesik
nesneler veya krem kaynak zemini kaldığı için reddedildi:

`tea_package_large_a.png`, `tea_package_large_b.png`, `tea_package_medium_a.png`,
`tea_package_medium_b.png`, `tea_package_small.png`, `tea_package_tall.png`,
`tea_shipping_cartons.png`.

Gramaj adları tahmin edilmedi. Paketleme/satış/gelir mekaniği eklenmedi.

## Dekorasyon

Kabul: `large_tree.png`, `wooden_fence.png`, `wooden_gate.png`,
`stacked_firewood.png`. Yalnız merkezi kayıt; yeni fiyat veya yapı öğesi yok.

| Reddedilen dosya | Neden |
| --- | --- |
| `deciduous_tree.png` | Sağ kenarda kopuk komşu pikseli |
| `evergreen_tree.png` | Solda komşu çit kırpıntısı |
| `evergreen_rock_cluster.png` | Altta komşu lambanın başı ve yanda kırpıntı |
| `fence_corner.png` | Sağda komşu nesne kırpıntısı |
| `small_evergreen_tree.png` | Üstte/solda komşu zemin parçaları |
| `rock_cluster.png` | Sağda komşu odun/zemin parçası |
| `rustic_lamp.png` | İki yanda komşu nesne zeminleri |
| `wooden_bench.png` | Sağda dikdörtgen kesilmiş komşu zemin/gölge |

## Dosyalar ve runtime temizliği

- Yeni `lib/game/systems/game_assets.dart`: semantik alanlar ve güvenli parça
  grupları. Reddedilen duvar/dere/paket grupları boş; geçersiz yollar yok.
- `field_visuals.dart`, `build_catalog.dart`, bina/işçi/harita görsel tanımları
  merkezi sabitleri kullanır. Mantıksal değerler değişmedi.
- `tea_field_component.dart`: stok varsa dolu çuvalı kg metninin yanında çizer.
- `cay_game.dart`: yalnız kullanılan çuval simgesini önceden yükler; tüm gelecek
  parçaları gereksiz yere GPU belleğine yüklemez.
- `pubspec.yaml`: güvenli alt klasörler ve gerekli tekil dosyalar tanımlı.
- `test/asset_migration_test.dart`: üç yeni kontrol; eski testler değiştirilmedi.
- `dev_assets/v3_migration/`: öncesi yedek, ZIP kaynakları/manifest, SHA-256
  kararları, görsel inceleme panoları ve tarayıcı inceleme betikleri.

25–30, 37 ve 40 kaynak setleri artık runtime asset tanımlarının dışındadır.
Eski dosyalar silinmedi; gerektiğinde geri alınabilir. `original/`, manifest,
inceleme panoları ve reddedilen kırpımlar runtime listesinde yoktur.
Kabul edilen 22 ayrılmış parça ve mevcut 32 tekil görsel (4 tarla + 28 nesne)
toplam 54 runtime PNG oluşturur. Agresif APK optimizasyonu yapılmadı.

## Doğrulama

- `flutter analyze`: hatasız.
- Tüm testler: **221/221 başarılı** (218 mevcut + 3 görsel/paket kontrolü).
- Yeni kontroller: tüm tarla durumlarında dış alfa ve görünür nesne; kayıtlı
  parçaların gerçek PNG olarak yüklenmesi; master/ret dosyalarının manifestte olmaması.
- `flutter build web`: başarılı.
- `flutter build apk --debug`: başarılı; APK v2 imzası doğrulandı.
- Son web ve APK paketleri incelendi: **54 runtime PNG**, 0 master set,
  0 geliştirme arşivi/manifest/önizleme dosyası. Eski 28 tekil PNG'nin SHA-256
  değerleri V3 öncesi yedekle aynı.
- Yeni oyunda gerçek dokunma olaylarıyla satın alma → envanter → yerleştirme,
  iptal, yol yapımı, işletme özeti, Mehmet/hasat, kamyon/alım yeri/fabrika
  sevkiyatı doğrulandı. Altın/ürün davranışları korundu. Taşıma/iptal ve
  geometri regresyonları mevcut widget/domain testlerinde geçti.
- Ekim → büyüme 1 → büyüme 2 → hazır → hasat/25 kg → kamyona yükleme/yeniden
  büyüme aşamaları Chrome'da izlendi ve ayrı ekran görüntüleri alındı.
  Hiçbir durumda krem dikdörtgen geri gelmedi. Dolu çuval yalnız stok varken
  kg metninin yanında göründü.
- Test haritasında dört hasatla biriken 100 kg yaş çay fiziksel olarak fabrikaya
  taşındı; tek üretim prosesi sonunda 20 kg kuru çay oluştu, altın değişmedi
  ve kamyon garaja boş döndü. Tarayıcı çalışma zamanı istisnası görülmedi.
- Chrome yeni oyun, test haritası, mağaza ve envanter görsel incelemeleri
  1280×720, 960×540 ve 844×390 boyutlarında tamamlandı. Dar yatay ekranda
  mevcut kaydırma/yakınlaştırma ile haritada gezinilir; yeni giriş yöntemi yoktur.
- Android cihaz testi yapılamadı: `emulator-5554` çevrimdışı. Windows ortamında
  iOS çalıştırılmadı. Android/iOS yatay mobil hedef, web geliştirme hedefidir.

## Temel görseller

| Nesne | Dış krem/beyaz dikdörtgen |
| --- | --- |
| Çiftlik Evi | Yok |
| Mehmet | Yok |
| Çay Tarlası — tüm durumlar | Yok |
| Çay Alım Yeri | Yok |
| Çay Fabrikası | Yok |
| Çay Kamyonu | Yok |
| Depo | Yok |

Güncel APK: `Downloads/cay-simulasyonu-v3-debug.apk` (198,7 MiB).
SHA-256: `E54107DCAB22911128904FFA6DC52CC38EF2E7E564D8A12DCC2B49DABA12B769`.
Web: `http://127.0.0.1:7361/`; test haritası: `?map=dev`.

## Bilinen sınırlar

25 şüpheli çıkarım kullanılmaz; tüm dosya adları ve gerekçeleri yukarıdadır.
Otomatik yol varyantı seçimi ve yeni dekor satın alma seçenekleri açılmadı.
Kabul edilen yol/path parçaları tek bir karo ızgarasına otomatik döşenebilir
bir set olarak sunulmaz. Kaynak çuval/sepet adları gerçek miktar/gramaj kuralı
oluşturmaz. PNG'lerin kendi zemine ait gölgeleri korunur. Debug APK hâlâ büyüktür;
görüntü sıkıştırma veya çözünürlük düşürme yapılmadı.

Bu geçiş yalnız görsel entegrasyonudur. Mobil yatay dokunma kontrolleri korunur;
yeni etkileşim veya Milestone 8 özelliği eklenmez.
