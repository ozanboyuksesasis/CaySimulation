# Milestone 4 — Fiziksel çay nakliyesi

Milestone 1–3 temeli korunarak tek kamyonla tarla → Çay Alım Yeri lojistiği eklendi.
Fabrika işleme, paketleme ve satış uygulanmadı. PNG dosyaları değiştirilmedi.

## Uygulanan akış

HASADA HAZIR TARLA → HASAT EMRİ → MEHMET → 25 KG TARLA STOĞU → TAŞIMA EMRİ →
ÇAY KAMYONU → 3 SANİYE YÜKLEME → 25 KG KAMYON YÜKÜ → ÇAY ALIM YERİ →
3 SANİYE TESLİM → 25 KG ALIM YERİ STOĞU

Tarla stoğu yükleme tamamlandığında sıfırlanırsa **o anda** yenilenme sayacı başlar.
Teslimatı beklemez. Stok kalmışsa büyüme kilidi devam eder. Hasat ve nakliye altını
değiştirmez. Eski global `InventoryState` uyumluluk için korunur; fiziksel çay
buraya eklenmez. HUD yalnızca `Alım Yerindeki Çay` miktarını gösterir.

## Oluşturulan dosyalar

| Dosya | İşlev |
| --- | --- |
| `lib/game/models/job.dart` | Hasat ve nakliyenin ortak Job/JobStatus tabanı |
| `lib/game/world/road_tiles.dart` | Yol karoları, tarla yükleme ve merkez teslim noktaları, garaj |
| `lib/game/systems/world_simulation.dart` | İşçi, nakliye ve büyümeyi aynı saatte ilerletir |
| `lib/features/transport/transport_config.dart` | 100 kg, 2.5 karo/sn, 3 sn yükleme/teslim |
| `lib/features/transport/transport_vehicle.dart` | Çizimden bağımsız araç, yük, kapasite, konum ve durum |
| `lib/features/transport/transport_job.dart` | Kaynak/hedef, araç, yük, aşama ve zaman verileri |
| `lib/features/transport/transport_system.dart` | FIFO, A* rotaları, hareket, stok aktarma, dönüş ve hata yönetimi |
| `lib/features/transport/vehicle_component.dart` | Flame çizimi, kesirli hareket, derinlik, seçim ve yük rozeti |
| `lib/features/buildings/tea_collection_center.dart` | Alım yerinin bağımsız teslim alınan çay stoğu |
| `lib/features/ui/transport_info_panel.dart` | Türkçe tarla nakliye ve kamyon panelleri |
| `test/transport_test.dart` | 38 kontrollü zaman testi |
| `test/transport_ui_test.dart` | Gerçek bileşenler/panellerle iki teslimat testi |
| `test/browser_milestone4.mjs` | Chrome'da gerçek süreli ve gerçek tıklamalı senaryo |
| `MILESTONE_4.md` | Bu rapor |

## Değiştirilen dosyalar

- `lib/game/cay_game.dart`: araç, merkez, nakliye ve ortak simülasyon bağlantıları.
- `lib/game/systems/grid_pathfinder.dart`: araçlara özel açık yol kümesi; işçinin eski kuralları korunur.
- `lib/game/world/prototype_map.dart`: yol tanımını paylaşır; kamyon adı, konumu ve mantıksal footprint'i güncellenir.
- `lib/game/components/grid_debug_component.dart`: mavi araç yolları, rota ve etkileşim noktaları.
- `lib/features/workers/harvest_job.dart`: ortak Job tabanını kullanır ve eski import için yeniden dışa aktarır.
- `lib/features/workers/job_system.dart`: sonraki olay zamanını ortak saate bildirir; hasat davranışı korunur.
- `lib/features/plantation/tea_field.dart`: iki taraflı stok aktarımı tamamlanana kadar bildirim erteleyebilir.
- `lib/features/economy/inventory_state.dart`: global envanterin lojistikten ayrı kapsamı açıklanır.
- `lib/features/ui/field_info_panel.dart`: boşalan stok ve yeniden büyüme durumu canlı görünür.
- `lib/features/ui/game_hud.dart`: merkez stoğu, araç seçimi, nakliye paneli ve debug bilgileri.
- `test/harvest_ui_test.dart`: yalnızca eski global HUD beklentisi merkez stoğuna çevrildi.
- `test/browser_milestone2.mjs`, `test/browser_milestone3.mjs`: aynı HUD değişikliğine uyarlandı.
- `README.md`: güncel akış, mimari, kapsam ve doğrulama bilgileri.

## Model ve iş mimarisi

TransportVehicle, TransportJob ve TeaCollectionCenter Flame nesneleri saklamaz.
JSON uyumlu veri görüntüleri kimlik, mantıksal konum, durum, stok ve iş bağlantılarını
taşır; kalıcı kayıt/yükleme eklenmedi. Araç durumları idle, movingToField, loading,
movingToCollectionCenter, unloading, returning ve blocked'dır; oyuncuya Türkçe gösterilir.

HarvestJob ve TransportJob aynı Job tabanını kullanır. Yürütücüler ayrı tutulur:
Mehmet yalnızca hasat kuyruğunu, kamyon yalnızca nakliye kuyruğunu işler. Bir araç
aynı anda tek iş alır. Aktif tarla işi varsa tekrar emir aynı işi döndürür.
FIFO sırası oluşturulma/ekleme sırasıdır; aynı zaman damgasında da korunur.

Teslimden sonra bekleyen iş varsa alım yerinden doğrudan o tarlaya gider.
Kuyruk boşsa garaja döner. Dönüş sırasında gelen emir kaybolmaz, garaja varınca alınır.

WorldSimulation süreyi yürüyüş, yolculuk ve çalışma olay sınırlarında böler.
İşçi yürütücüsü büyüme saatini bir kez ilerletir; kamyon aynı süreyi kullanır.
Bu sayede iki sistem eşzamanlı çalışır, büyük zaman adımları yükleme anını ve
yenilenme başlangıcını kaydırmaz. Duraklatma/arka plan davranışı korunur.

## Yol ve etkileşim noktaları

A* dört yönde mantıksal karolar üzerinde çalışır. İşçiler uygun normal zeminde
yürür; araçlar yalnızca `roadTiles` kümesinden geçer. Tarlalar, binalar, kuyu ve
harita dışı her iki yol bulucuda engeldir. Araçlar için çim üzerinden kısayol yoktur.

Mevcut x=8/9 ve y=7/8 ana yolları korundu. Ek bağlantılar:
y=4 üzerinde x=4…10, x=4 üzerinde y=3…7 ve (7,3) karosu.
Arazi çizimi ile araç geçiş kuralları aynı yol verisini kullanır.

| Nokta | Mantıksal karo | Açıklama |
| --- | --- | --- |
| Kamyon başlangıç/garaj | (10,7) | Depo yakınında yol; ayak merkezi (10.5,7.5) |
| field-01 yükleme | (4,3) | (2,2) tarlasının doğu kenarı |
| field-02 yükleme | (7,3) | (5,2) tarlasının doğu kenarı |
| field-03 yükleme | (4,6) | (2,5) tarlasının doğu kenarı |
| Çay Alım Yeri teslim | (10,4) | Merkezin batı kenarı; bina footprint'i dışında |

Mevcut genel `interactionTiles` API'si bu atanmış noktaların dış komşu ve
yürünebilir olduğunu doğrular. Araç merkeze/tarlanın içine girmez. Başlangıçta
garaj → her tarla → teslim rotaları kontrol edilir; sorun varsa Türkçe tanı yazılır.
Debug modunda yol ve kamyon rotası mavi, işçi rotası sarıdır; stok/kuyruk bilgileri görünür.

## Yükleme, teslim ve ürün korunumu

Yüklemenin ilk 3 saniyesinde stok tarladadır. Süre tamamlanınca
`min(tarlaStoğu, boşKapasite)` kadar ürün kamyona aktarılır. Kısmi yükleme kalan
stoğu korur ve yenilenmeyi başlatmaz. Tek iş tek seferdir; kalan ürün için teslim
sonrasında yeni emir verilebilir. Teslimde de 3 saniye boyunca yük kamyondadır;
yalnızca bitişte merkeze aktarılır.

`totalTeaKg = Σ tarlaStoğu + kamyonYükü + alımYeriStoğu`.
Her aktarımın öncesi/sonrası toplamı denetlenir. İki model de güncellenmeden
dinleyici bildirimi yapılmaz; UI bile ara anda ürünün kaybolduğunu/çoğaldığını görmez.
Hasat yeni çay üretir; nakliye yalnızca yer değiştirir. Ekonomi/global envanter
nakliye yürütücüsünün bağımlılıkları değildir.

Tarlaya yol yoksa iş failed olur, tarla stoğu korunur. Yüklü kamyonun teslim
yolu yoksa iş failed, araç blocked olur; yük araçta kalır. Türkçe hata ve
`Yolu tekrar dene` düğmesi vardır. Yol geri açılırsa eldeki yük teslim edilir.
Işınlama veya çim üzerinden alternatif yol yoktur.

## Gerçek master assetler

| Dosya (`assets/images/`) | Nesne | Güncel kullanım |
| --- | --- | --- |
| `vehicles/14_TEA_TRANSPORT_TRUCK.png` | Çay Kamyonu | Yoldan yükleme, teslim ve garaja dönüş |
| `characters/15_FARMER_MALE.png` | Mehmet | Yürüyen ve hasat yapan işçi |
| `buildings/35_TEA_COLLECTION_CENTER.png` | Çay Alım Yeri | Haritada görünür, teslim edilen çayı biriktirir |
| `fields/01_FIELD_EMPTY.png` | Çay Tarlası | Boş |
| `fields/02_FIELD_PLANTED.png` | Çay Tarlası | Ekilmiş/hasat edilmiş/yenilenen |
| `fields/03_FIELD_GROWING.png` | Çay Tarlası | İki büyüme aşaması |
| `fields/04_FIELD_HARVEST.png` | Çay Tarlası | Hasada hazır |
| `buildings/05_FARMER_HOUSE.png` | Çiftlik Evi | Korunan yerleşim |
| `buildings/06_TEA_WAREHOUSE.png` | Depo | Garaj yakınında, henüz işlemsiz |
| `buildings/09_TEA_FACTORY.png` | Çay Fabrikası | Korunan yerleşim, işleme yok |
| `infrastructure/12_VILLAGE_WELL.png` | Köy kuyusu | Korunan dekorasyon |
| `buildings/39_MARKET.png` | Pazar | Korunan yerleşim, satış yok |

Kaynak PNG'ler yeniden üretilmedi, temizlenmedi veya boyutlandırılmadı.
Araç görseli 190×130 dünya pikseli, mantıksal footprint'i 1×1'dir; PNG çözünürlüğü
kapasite, hız veya yol bulmayı etkilemez. Hareket konumu derinlik sırasına katılır.

## Doğrulama

- `flutter analyze`: **sorun yok**.
- `flutter test`: **87/87 geçti**. Önceki 48 test korunur; 38 nakliye birim testi
  ve bir uçtan uca Flutter arayüz testi eklendi. Birim/arayüz testleri gerçek süre beklemez.
- Test kapsamı: emir/çoğaltma/FIFO, araç geçiş kuralları ve kenar hedefi, 3 saniye
  sınırları, yükleme/teslim stok aktarımı, regrowth, kapasite/kısmi yük, garaj,
  iki no-path durumu, atomik kütle korunumu, işçiyle eşzamanlılık, ekonomi ve eski
  envanterin değişmemesi, gerçek harita bağlantıları, JSON, büyük/küçük zaman adımı.
- `flutter build web`: **başarılı**. SDK'nın kullanılmayan CupertinoIcons fontu
  için verdiği mevcut tree-shaking uyarısı derlemeyi engellemedi.
- Gerçek Chrome release sürümünde tıklama ve gerçek geçen zamanla iki tarla
  büyütüldü, hasat edildi ve FIFO teslim edildi. İlk nakliye sırasında Mehmet
  ikinci tarlada çalıştı. Yükleme sırasında 25 kg tarlada kaldı; bitince 0 kg tarla,
  25 kg kamyon oldu ve yenilenme başladı. Teslimler sonunda merkez **50 kg**, kamyon
  **0 kg**, altın **9.500**; kamyon garajda **Boşta**. Çalışma zamanı istisnası görülmedi.
- Chrome görselleri: `milestone4_loading.png`, `milestone4_loaded_regrowth.png`,
  `milestone4_transport_queue.png`, `milestone4_unloading.png`,
  `milestone4_second_delivery.png`, `milestone4_returned_home.png`,
  `milestone4_debug_roads.png`; eşzamanlı hareket için `milestone4_simultaneous_*.png`.
- Yerel web önizlemesi: **http://127.0.0.1:7361**. Sunucu yeniden başlatılacaksa
  `flutter build web` ardından `node test/serve_web.mjs`; alternatif `flutter run -d chrome`.
  Bu yardımcı sadece yerel dosya sunar; oyuna backend eklenmedi.

## Bilinen sınırlar

Tek kamyon, tek işçi, sabit yol ağı ve etkileşim noktaları vardır. Çarpışma kaçınma
yoktur. PNG'ler tek karedir; yön/tekerlek/yürüme animasyonu yoktur. Kaynak görsellerin
mevcut arka planları ve geniş hit-test kutuları korunur; üst üste gelen nesnelerin
görünür bölümüne tıklamak gerekebilir. Karmaşık binalar ayrı derinlik katmanlarına
bölünmedi. İş geçmişi prototip oturumunda bellekte tutulur. Kalıcı kayıt, çevrimdışı
arka plan ilerlemesi, işleme, paketleme ve satış yoktur. Android/iOS fiziksel cihaz
testi bu aşamada yapılmadı. Milestone 4 sınırında duruldu.
