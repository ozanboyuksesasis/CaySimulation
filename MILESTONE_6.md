# Milestone 6 — Oyuncu yapı ve taşıma sistemi

## Sonuç ve erişim

Yeni oyun varsayılandır: 10.000 Altın, (3,9) konumunda 2×2 Çiftlik Evi,
(6,9) yakınında Mehmet ve başlangıç yol ağı. Tarla, depo, alım yeri, fabrika ve
pazar başlangıçta yoktur. Kamyon modeli hazırdır fakat alım yeri kurulana kadar
görünmez ve nakliye emri alamaz. Kamyonun garajı (10,7), kapasitesi 100 kg'dır.

`Harita modu` menüsü iki yeni oturum seçeneği sunar. Eski M1–5 yerleşimi
`GameMapMode.devTest` altında korunur. Webde `?map=dev` de aynı haritayı açar.
Mod değiştirince mevcut oturum sıfırlanır; seçeneklerin adı bunu açıkça belirtir.

## Katalog ve assetler

| Yapı | Kategori | Altın | Mantıksal alan | Yol / sınır | PNG |
| --- | --- | ---: | --- | --- | --- |
| Çay Tarlası | Tarım | 500 | 2×2 | Çoklu; nakliye için sonradan yol gerekir | `01_FIELD_EMPTY.png`; döngüde `02_FIELD_PLANTED.png`, `03_FIELD_GROWING.png`, `04_FIELD_HARVEST.png` |
| Çay Alım Yeri | Lojistik | 2.500 | 3×2 | Garaja bağlı yol, en fazla 1 | `35_TEA_COLLECTION_CENTER.png` |
| Çay Fabrikası | Üretim | 4.000 | 3×3 | Garaja bağlı yol, en fazla 1 | `09_TEA_FACTORY.png` |
| Depo | Lojistik | 1.500 | 2×1 | Garaja bağlı yol | `06_TEA_WAREHOUSE.png` |
| Toprak Yol | Altyapı | 25 | 1×1 | Tekrarlı yerleştirme | Menü: `25_DIRT_ROAD_SET.png`; dünya: mevcut genel yol karosu |
| Köy Kuyusu | Dekorasyon | 50 | 1×1 | Oyun etkisi yok | `12_VILLAGE_WELL.png` |

Çiftlik Evi `05_FARMER_HOUSE.png`, Mehmet `15_FARMER_MALE.png`, aynı tek kamyon
`14_TEA_TRANSPORT_TRUCK.png` kullanır. PNG dosyaları değiştirilmedi. Görsel boyutlar
katalogda mantıksal footprint'ten ayrı tutulur. Ağaç atlası kesmek yerine mevcut
bağımsız kuyu dekorasyonu kullanıldı.

## Mimari

- `Settlement`: mantıksal yapılar, yol kümesi ve karo→sahip doluluk indeksi.
  Doluluk sprite piksellerinden hesaplanmaz. `PlacedStructure.toJson()` temel
  kimlik/tür/katalog/konum verisini verir; kayıt/geri yükleme uygulanmadı.
- `BuildCatalogItem`: fiyat, kategori, açıklama, PNG, footprint, görsel ölçü,
  yol gereksinimi ve adet sınırının tek kaynağı.
- `BuilderSystem`: `inactive`, `selecting`, `placingNew`, `placingRoad`,
  `movingExisting`. Önizleme konumu, seçilen katalog, taşınan kimlik ve başlangıç
  konumunu tutar. UI/Flame nesnesi içermez. Tekrar doğrulama ve satın alma burada yapılır.
- `PlacementValidator`: sınır, doluluk, ayrılmış geçiş karoları, adet ve bağlı yol
  kontrolü. Onayda tekrar çalışır. Bakiye yalnızca başarılı yeni yerleştirmede düşer.
- `CayGame` mevcut sistemlerin bağlayıcısıdır. Yerleşim değişikliği gerçek `TeaField`,
  `TeaCollectionCenter`, `TeaFactory` modellerini ve bileşenlerini kaydeder;
  var olan modelleri taşırken aynı nesne ve stoklar korunur.
- Kimlikler çalışma zamanında tür başına artar (`field_001`, `factory_001` vb.).
  Mevcut kimliklerle çakışma kontrol edilir; sabit test haritası kimliği gerekmez.
- `buildingPlaced`, `fieldPlaced`, `collectionCenterPlaced`, `factoryPlaced`,
  `buildingMoved` olayları kimlikle yayınlanır. Eğitim ekranı eklenmedi.

## Doluluk, yollar ve hareket

Başlangıç yol ağı: y=7 üzerinde x=4…12 ve x=8 üzerinde y=4…10. Her yeni yol
aynı mantıksal kümeye eklenir. Mevcut işçi ve kamyon A* nesneleri güncellenen
topolojiyi okur; işçi normal arazide, kamyon yalnızca yol karolarında yürür/sürer.
Tarla ve bina alanları engeldir. Etkileşim noktası footprint'in dış kenarındaki,
garajdan ulaşılabilir en yakın yol karosudur; binanın ortasına araç sokulmaz.
Tarla yolsuz kurulabilir; uygun yol sonradan kurulduğunda yükleme noktası kaydedilir.

Yapı yerleştirme mevcut yolun üstüne yapı kuramaz. Mehmet'in/kamyonun mevcut
karosu, aktif kalan rotaları ve garaj yapı için ayrılmıştır. İnşa veya taşıma
devam eden hareketin rotasını kapatmaz. Araç ve işçi çarpışma kaçınması eklenmedi.

Taşıma önizlemesi asıl dünyayı değiştirmez: sadece doğrulama kendi footprint'ini
yok sayar, asıl çizim gizlenir ve ghost görünür. Böylece iptal konum, doluluk,
etkileşim noktası ve stoklara hiç dokunmaz. Onay tüm mekânsal verileri günceller;
tarla durumu/hasat sayısı/stok, alım yeri stoğu ve fabrika girdisi/çıktısı korunur.
Taşıma 0 Altındır. Aktif veya kuyruktaki ilgili hasat/nakliye işi, yük taşıyan
başarısız iş veya fabrika üretimi varsa taşıma reddedilir; onay anında da kontrol edilir.

## Oyuncu arayüzü ve kontroller

`Yapılar` alt menüsünde Türkçe kategoriler ve görselli fiyat/açıklama kartları vardır.
Seçim ödeme yapmaz. Fare hareketi veya haritaya dokunma önizlemeyi izometrik
mantıksal karoya oturtur. Kaynak sprite yaklaşık %65 opaklıkla, footprint
yeşil/kırmızı gösterilir. Geçersizlik nedeni panelde görünür; sürekli snackbar yoktur.

`Yerleştir`/`İptal`, taşımada `Onayla`/`Vazgeç`; yol modunda her ayrı tıklama veya
dokunma bir yol satın alır ve mod açık kalır, `Bitir` kapatır. Escape ve sağ tık iptal
eder. Sürükleme kamerayı hareket ettirir, yol satın almaz; tekerlek/pinch zoom korunur.
Tarla/bina önizlemesi haritaya tıklayınca sabitlenir; onay düğmesine giderken
fare hareketi konumu değiştirmez. Başka bir karoya tıklayarak yeniden konum seçilir.
Uzun basma yerine açık `Taşı` düğmesi kullanılır.

Normal panel koordinat/footprint/geliştirici metinlerini gizler; `Izgara` açılınca
görünürler. Alım yeri yokken `Çay Alım Yeri gerekli.`, fabrika yokken `Çay Fabrikası
gerekli.` görünür; olmayan hedefe iş yaratılamaz.

## Dosyalar

Oluşturulanlar:

- `lib/features/builder/build_catalog.dart`
- `lib/features/builder/settlement.dart`
- `lib/features/builder/placement_validator.dart`
- `lib/features/builder/builder_system.dart`
- `lib/features/builder/placement_preview.dart`
- `lib/game/world/map_setup.dart`
- `lib/features/ui/builder_overlay.dart`
- `test/builder_test.dart`, `test/builder_ui_test.dart`, `test/browser_milestone6.mjs`
- `MILESTONE_6.md`

Değiştirilenler:

- `lib/main.dart`, `lib/game/cay_game.dart`
- `lib/game/systems/grid_pathfinder.dart`
- `lib/game/components/terrain_component.dart`, `world_entity.dart`, `grid_debug_component.dart`
- `lib/features/plantation/plantation_system.dart`, `tea_field.dart`, `tea_field_component.dart`
- `lib/features/buildings/tea_collection_center.dart`, `tea_factory.dart`
- `lib/features/transport/transport_system.dart`
- `lib/features/ui/game_screen.dart`, `game_hud.dart`, `transport_info_panel.dart`, `worker_info_panel.dart`
- Eski `game_smoke_test`, `factory_ui_test`, `harvest_ui_test`, `transport_ui_test`,
  `factory_test`, `transport_test`: eski yerleşim beklentileri için açık `devTest` seçimi.
- `test/browser_milestone2/3/4/5.mjs`: test haritası URL'si; `README.md`.

## Doğrulama

- `flutter analyze`: sorun yok.
- `flutter test`: **177/177 başarılı**. Önceki 126 test + 50 yeni domain testi +
  gerçek asset/arayüz etkileşimli 1 yeni kapsamlı widget testi.
- `flutter build web`: başarılı. Chrome'da çalıştırıldı.
- Yeni testler istenen 40 senaryoyu ve yol bağlantısı/adet sınırı/tekrarlı yol,
  kendi alanına taşıma, onayda meşguliyet, aktif rota koruması, sonradan yol bağlama,
  kimlik/seri veri ve olay yayını senaryolarını kapsar. Zaman beklemeden simülasyon saati kullanılır.
- Widget akışı: iki tarla, geçersiz/geçerli konum, tam fiyat, yeni tarla hasadı,
  meşgul taşıma engeli, stokla taşıma/iptal, pan/zoom sırasında kazara satın almama,
  tekrarlı yol, Escape ve 740×360 yatay menü.
- Gerçek Chrome akışı (`test/browser_milestone6.mjs`): yeni oyun 10.000; ilk tarla
  9.500, ikinci 9.000; 250 Altın dikim; 18 saniye büyüme; Mehmet'in fiziksel hasadı;
  25 kg stokla ücretsiz taşıma ve iptal; dinamik alım yeri ve fabrika kurulumu;
  aynı kamyonla tarla→alım yeri→fabrika 25 kg; stok aktarımı ve yetersiz reçete
  mesajı; iki yol satın alma sonrası 2.200 Altın. Oyun durumuna test enjeksiyonu yoktur.
- Korunan dev haritasında `test/browser_milestone5.mjs` tekrar çalıştırıldı:
  dört gerçek hasat, 100 kg alım yeri stoğu, aynı kamyonla sevkiyat, 10 saniyelik
  üretim ve 20 kg kuru çay; Altın 9.500'de kaldı, kamyon boş olarak garaja döndü.
- Ekran kayıtları `milestone6_*.png`: yeni oyun, geçerli/geçersiz ghost, iki tarla,
  hasat, taşıma, alım yeri, fabrika ve yol yapımı.

## Sınırlar

Yol atlası otomatik düz/viraj/T/kavşak olarak kesilmedi; bağlantı doğru mantıksal
karolarla çalışır, mevcut genel yol görseli kullanılır. Bazı kaynak PNG'lerin
arka planı korunur. Çiftlik Evi ve yol karoları taşınmaz; sökme/satma/yükseltme yoktur.
Uzun basma yoktur; `Taşı` birincil kontroldür. Dekorasyon mevcut kuyu ile sınırlıdır.
Alım yeri ve fabrika birer adettir. Kayıt yoktur; yenileme/mod değişimi yeni oturumdur.
Mobil cihaz üzerinde test yapılmadı; dokunma/pinch ve yatay dar ekran widget testleri vardır.

Paketleme, satış, yeni üretim prosesi, yeni araç/işçi, ilerleme sistemi veya sonraki
milestone kapsamı uygulanmadı.
