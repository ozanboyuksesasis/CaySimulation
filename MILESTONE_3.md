# Milestone 3 — İşçi ve fiziksel hasat

## Oynanabilir akış

HAZIR TARLA → HASAT EMRİ → FIFO İŞ ATAMA → İŞÇİ YÜRÜR → 5 SANİYE HASAT → 25 KG TARLA STOĞU

Üç tarla yine bağımsız dikilir ve büyür. `Hasat Et` artık yalnızca emir verir.
Mehmet meşgulse diğer emirler sırada kalır. Hasat sırasında tarla modelinin durumu
READY olarak kalır; UI iş durumuna göre `Hasat yapılıyor` gösterir. İş tamamlanınca
tarla HARVESTED olur, hasat sayısı bir artar ve kendi stoğuna 25 kg ekler.

Global `InventoryState.freshTeaKg` tarla stoklarını içermez. İş sistemi global
envanteri veya altını değiştirmez. Çay Alım Yeri görünür ve işlevsizdir; paneli
`Durum: Açık / Teslim Alınan Yaş Çay: 0 kg` gösterir.

## Yeni dosyalar

- `lib/features/workers/worker.dart`: Worker, WorkerState, Türkçe durum etiketleri, JSON veri görüntüsü.
- `lib/features/workers/worker_config.dart`: 2 mantıksal karo/sn ve 5 saniye hasat.
- `lib/features/workers/worker_component.dart`: modelin kesirli konumunu mevcut Flame dünya bileşenine bağlar.
- `lib/features/workers/harvest_job.dart`: genişletilebilir Job tabanı, HarvestJob ve JobStatus.
- `lib/features/workers/job_system.dart`: FIFO atama, yol, hareket, çalışma süresi, tamamlama/hata.
- `lib/game/systems/grid_pathfinder.dart`: tekrar kullanılabilir A* ve etkileşim karoları.
- `lib/features/ui/worker_info_panel.dart`: aynı seçim panelinde Mehmet'in görevi ve süresi.
- `test/worker_jobs_test.dart`: 24 yeni kontrollü zaman testi.
- `test/browser_milestone3.mjs`: gerçek Chrome tıklamaları ve gerçek zamanla iki tarla senaryosu.
- `MILESTONE_3.md`: bu rapor.

## Değişen dosyalar

- `tea_field.dart`: field-local stock, completeHarvest, removeHarvestedStock, stok beklerken büyüme kilidi.
- `plantation_system.dart`: anlık hasat/global envantere ekleme yolu kaldırıldı; dikim korunur.
- `tea_field_component.dart`: hafif `25 kg` stok rozeti.
- `inventory_state.dart`: global stok kapsamı belgelendi.
- `worker_prototype.dart`: mevcut erkek üretici artık Mehmet olarak tanımlı.
- `cay_game.dart`: işçi, yürünebilirlik, iş sistemi ve tek simülasyon saati bağlantısı.
- `grid_debug_component.dart`: engelli karolar, kalan rota ve etkileşim hedefi.
- `game_hud.dart`, `field_info_panel.dart`: iş kuyruğu, çalışma durumu, süre, tarla stoğu ve işçi seçimi.
- `test/plantation_test.dart`, `test/harvest_ui_test.dart`, `test/game_smoke_test.dart`: önceki testler yalnızca yeni hasat/stok ve Mehmet davranışına uyarlandı; silinmedi.
- `test/browser_milestone2.mjs`: eski browser kontrolündeki anlık envanter/yeniden büyüme beklentileri yeni stok davranışına uyarlandı.
- `README.md`: güncel milestone yönlendirmesi.

## İşçi ve iş mimarisi

Worker modeli Flame bileşeni içermez. Konum sürekli mantıksal koordinattır;
JSON'a kimlik, ad, konum, durum, hız ve atanmış iş kimliği yazılabilir.
Durumlar: idle, movingToJob, working, returning, blocked. Son iki durum sonraki
genişletmelere hazırdır; bu milestone'da iş sonrası evine dönmez, bulunduğu yerde
boşta kalır veya sonraki işi alır. Yol bulunamazsa güvenli biçimde idle olur.

HarvestJob tarla kimliği, oluşturulma zamanı, atanmış işçi, etkileşim hedefi,
çalışılan süre ve durum taşır. Durumlar queued, assigned, inProgress, completed,
failed. Aktif iş varken tekrar emir aynı işi döndürür. Yeni hasat iş kimlikleri
oturum içinde benzersizdir. FIFO eşit zamanlarda ekleme sırasını korur.
Gelecekte başka Job türleri eklenebilir; yalnızca hasat yürütücüsü uygulanmıştır.

JobSystem, tarla büyümesini de ilerleterek hareket ve hasadı aynı simülasyon
saatinde tutar. Bir karede artan süre sonraki yol parçasına/işe taşınır; büyük
zaman adımları erken tamamlanma veya çift ürün oluşturmaz. Arka planda oyun durur.

## Yol ve etkileşim konumu

A* 20×20 mantıksal ızgarada dört yönde yürür; ekran pikseli kullanmaz. Normal
zemin ve yollar açıktır. Binalar, tüm tarla içleri ve kuyu footprint'i engeldir;
harita dışı kapalıdır. Hedef tarlanın içine de girilmez: footprint'in dört kenarı
boyunca dış komşular adaydır. Çok hedefli A*, **en kısa yürünebilir yol** mesafesine
göre en yakın adayı seçer; eşitlikler deterministiktir. Bu API daha sonra bina
girişi/yükleme noktaları için kullanılabilir.

Mehmet waypoint'ler arasında 2 karo/sn hızla kesirli konumlarda ilerler. Render
mevcut izometrik dönüşümü kullanır, ayak konumunun dünya Y'si derinlik sırasına
katılır. Hareket, kamera ve hit-test aynı bileşen konumunu kullanır. Başlangıç:
Çiftlik Evi yakınında **(6,9)** karosu, ayak merkezi **(6.5,9.5)**; hiçbir bina
footprint'inin içinde değildir. Yol bulunamayan iş failed olur; alan panelinde
`Tarlaya ulaşılacak yol bulunamadı.` görünür ve tekrar emir verilebilir.

## Tarla stoğu ve sonraki aşamaya hazırlık

`harvestedStockKg > 0` iken HARVESTED durumunun büyüme süresi yoktur. UI:
`Tarlada Bekleyen Yaş Çay: 25 kg` ve `Tarlada 25 kg yaş çay toplanmayı bekliyor.`

`removeHarvestedStock(amount)` sadece veri API'sidir; oyuncu düğmesi veya taşıma
sistemi eklenmedi. Kısmi alma büyümeyi başlatmaz. Stok sıfıra indiği simülasyon
anında 5 saniyelik yenilenme başlar; ardından eski GROWING_1 akışı devam eder.
Negatif veya mevcut stoktan fazla alma reddedilir. Bu metot global stoğa otomatik
ürün eklemez. Gelecekte taşımanın stok aktarmayı ayrıca yönetmesi gerekir.

## Kullanılan master assetler

| Nesne | Gerçek dosya | Kullanım |
| --- | --- | --- |
| Mehmet | `assets/images/characters/15_FARMER_MALE.png` | Yürüyen/seçilebilir işçi |
| Çay Alım Yeri | `assets/images/buildings/35_TEA_COLLECTION_CENTER.png` | Haritada korunur; teslimat yok |
| Nakliye kamyonu | `assets/images/vehicles/14_TEA_TRANSPORT_TRUCK.png` | Sabit görsel; taşıma yok |

Diğer mevcut karakter assetleri: 16_FARMER_FEMALE, 17_FACTORY_WORKER,
18_MECHANIC, 19_TEA_MERCHANT, 20_TEA_FACTORY_WORKER, 21_TEA_FACTORY_SUPERVISOR,
22_TRUCK_DRIVER, 23_VILLAGE_ELDER, 24_TEA_MERCHANT. Bu milestone'da kullanılmazlar.
40 PNG'nin kaynak ZIP ile SHA-256 eşleşmesi doğrulandı; hiçbiri değiştirilmedi.

## Doğrulama ve sınırlar

24 yeni test; istenen 20 işçi/hasat koşuluna ek olarak engel dolaşma, en yakın
erişilebilir hedef, JSON, büyük zaman adımı ve geçersiz stok işlemlerini kapsar.
Önceki 24 test korunarak toplam **48/48 test başarılı**. `flutter analyze` sorun
bildirmedi; `flutter build web` başarılı. Doğrulama komutları README'deki gibidir.

Gerçek Chrome release kontrolünde (2,5) ve (5,2) tarlaları büyütüldü. İlk hasat
sürerken ikinci emir kuyruğa girdi. Mehmet yürüdü, seçildiğinde `Çay topluyor`
gösterdi, 5 saniyelik işi bitirdi ve ikinci tarlaya yürüdü. İki tarlada ayrı ayrı
25 kg oluştu; global stok 0 kg ve altın 9.500 kaldı. İlk tarla bekleme sonrasında
HARVESTED kaldı. Çay Alım Yeri Açık / 0 kg olarak korundu. Ekran çıktıları:
`milestone3_worker_working.png`, `milestone3_queued.png`,
`milestone3_moving_to_second.png`, `milestone3_stock_blocks_regrowth.png`.

Tek işçi ve statik engel haritası vardır. Yolculuk görseli mevcut tek kare PNG'nin
akıcı yer değiştirmesidir; yürüyüş/hasat sprite animasyonu yoktur. Komşu iki tarla
aynı geçerli etkileşim karosunu paylaşırsa ikinci iş için gereksiz yürüyüş yapılmaz.
Kaynak arka planları korunur; kompleks bina katmanları henüz bölünmemiştir.
İş geçmişi yalnızca bu küçük prototip oturumu boyunca bellekte kalır. Kayıt/yükleme,
çoklu işçi/çarpışma, işe alma, taşıma, teslimat, işleme, paketleme ve satış yoktur.
Fiziksel Android/iOS cihaz testi yapılmadı.
