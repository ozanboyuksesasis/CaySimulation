# Milestone 8 — Birleşik Envanter ve ilk oturum eğitimi

## Oyuncu akışı

Eski **MAĞAZA → SATIN AL → ENVANTER → YERLEŞTİR** akışı normal yeni oyundan kaldırıldı: **EVET**.

- Yapılar: **ENVANTER → KATEGORİ → KUR → ÖNİZLEME → GEÇERLİ YERLEŞTİRME → ALTIN ÖDEMESİ → GERÇEK OYUN NESNESİ**.
- Yollar: **ENVANTER → ALTYAPI → İNŞA ET → HER BAŞARILI KARO İÇİN 25 ALTIN**.
- İşçiler: **ENVANTER → İŞÇİLER → TURHAN / HAVVA → İŞE AL**.
- Ekipman: **ENVANTER → EKİPMAN → SATIN AL → İŞÇİYİ SEÇ → EKİPMAN DEĞİŞTİR**.

Önizleme, iptal ve başarısız yerleştirme ücretsizdir. Taşıma ücretsiz kalır. Normal alt gezinme yalnız **Envanter / İşletme** içerir. İşletme salt okunur stok ve işletme özetidir. Test haritasının eski satın alma yardımcıları regresyon amacıyla korunmuştur.

## Yeni dosyalar

| Dosya | Sorumluluk |
|---|---|
| `lib/features/workers/equipment.dart` | Ekipman türleri, fiyatları, görselleri ve hasat süreleri |
| `lib/features/workers/workforce_state.dart` | Gerçek işçi sahipliği, işe alma, ekipman satın alma/takma/çıkarma |
| `lib/game/systems/tutorial_system.dart` | Görselleştirmeden bağımsız, dünya durumuna duyarlı eğitim durum makinesi |
| `lib/features/ui/tutorial_coach.dart` | Küçültülebilir, dokunmatik rehber ve gerçek kontrollere yönlendirme |
| `test/milestone8_test.dart` | İşgücü, ekipman, çoklu işçi ve iki seçimle uçtan uca eğitim testleri |
| `test/browser_milestone8.mjs` | Gerçek Chrome dokunmatik girişleri ve gerçek geçen zamanla kabul senaryosu |

## Değiştirilen dosyalar

- UI: `player_panels.dart`, `game_navigation.dart`, `game_hud.dart`, `worker_info_panel.dart`, `field_info_panel.dart`, `builder_overlay.dart`.
- Alan modelleri/sistemler: `build_catalog.dart`, `builder_system.dart`, `player_inventory.dart`, `worker.dart`, `worker_config.dart`, `harvest_job.dart`, `job_system.dart`.
- Oyun entegrasyonu: `cay_game.dart`, `grid_debug_component.dart`, `game_assets.dart`.
- Önceki testlerin yeni kurallara uyarlanması: `builder_test.dart`, `builder_ui_test.dart`, `mobile_panels_test.dart`, `shop_inventory_test.dart`, `worker_jobs_test.dart`, `transport_test.dart`.

## Mimari ve korunan sistemler

Mevcut `BuildCatalogItem` yapı fiyatı, footprint, yol ve tekillik kurallarının tek kaynağıdır. Envanter yapı kartları mevcut katalogdan okunur. İşçi teklifleri ve ekipman tanımları kendi türlerinin merkezi tanımlarıdır; fiyatlar widget'larda çoğaltılmaz.

`ShopService` silinmedi: eski test/ödül kaynaklı yerleştirilebilir envanter desteği korunur. Normal yapı işlemlerini `BuilderSystem` onay anında ücretlendirir. `fromInventory` açıkça seçilirse gelecekteki ödül öğeleri ücret alınmadan tüketilebilir; normal arayüz bu eski satın alma akışını sunmaz.

`WorkforceState` Turhan ve Havva'yı ayrı gerçek işçiler olarak sahiplenir. Her biri 1.000 Altın, benzersiz ve eşit performanslıdır. İşe alımda ev yakınındaki uygun boş karo seçilir. Yeni oyunda ücretsiz işçi yoktur. Test haritasındaki Mehmet, eski regresyonlar için makaslı bir test işçisi olarak korunur.

`JobSystem` FIFO kuyruğunu bir işçi listesine dağıtır; uygun ve boş ilk işçiyi deterministik olarak seçer. İki işçi aynı anda yürüyebilir ve çalışabilir. Bütün işçiler tek dünya saatini paylaşır; tarla büyümesi işçi sayısı kadar hızlanmaz. Ekipmansız işçi atanmaz. Ekipmanlı işçiler meşgulse iş kuyrukta bekler.

Ekipman boşta envanter miktarı ile işçiye takılı slot arasında taşınır; aynı makas iki işçide bulunmaz. Ekipman değişimi eski öğeyi geri verir. Görevdeyken ekipman değiştirilemez. Makas 250 Altın / 5 saniye, motor 2.500 Altın / 2,5 saniyedir; ikisi de 25 kg üretir.

Tarla, taşıma, alım yeri, fabrika ve fiziksel stok sahipliği korunmuştur. Hasat yalnız tarla stoğu oluşturur. Taşıma miktarı korur; fabrika mevcut 100 kg yaş → 10 saniye → 20 kg kuru tarifini kullanır. Altın geliri ve yeni üretim aşaması eklenmedi.

## Eğitim

`TutorialSystem`, başarılı alan değişikliklerinin bildirimlerini dinler: yerleşim, işçi sahipliği, ekipman, tarla yaşam döngüsü, hasat işleri, taşıma işleri ve üretim. Tıklama sayısı veya sahte eğitim ürünleri kullanılmaz. Önceden tamamlanan sahiplik adımları yeniden satın aldırılmaz. İlk işçi referansı korunur ve metin Turhan/Havva adına göre değişir.

Fabrika hedefi doğrudan `rawTeaKg` değerini okur. Teslimat geçmişi gerçek taşıma işlerinin tamamlanan miktarından okunur. Yol doğrulaması gerçek araç A* kurallarını kullanır. Harita, ekonomi, mantıksal footprintler ve Game Ready V3 görselleri korunur.

Zorunlu başlangıç maliyeti **8.500 Altın**, başlangıç bakiyesi **10.000 Altın**. Mevcut başlangıç yoluna komşu yerleşimle ek yol satın almadan eğitim tamamlanabilir; bağlantı için **1.500 Altın** kalır. İsteğe bağlı ekstra alımlar da gerçek bütçeden ödenir; gizli altın veya eğitim ödülü yoktur.

Son zincir:

**ÇAY TARLASI → TURHAN/HAVVA + ÇAY MAKASI → DÖRT GERÇEK HASAT → TARLA STOĞU → KAMYON → ÇAY ALIM YERİ → KAMYON → FABRİKADA 100 KG YAŞ ÇAY → ÜRETİM → 20 KG KURU ÇAY → SERBEST OYUN**.

## Mobil ve görseller

- Android/iOS birincil oyun hedefidir; web geliştirme/test hedefidir. Yatay yönelim korunur.
- Envanter kategorileri yatay, kartlar dikey kaydırılır. SafeArea ve dokunmatik gezinme korunur.
- Önizleme sırasında sürükleme ve iki parmakla yakınlaştırma çalışır; onay açık düğmeyle yapılır. Yol yerleşimi dokunma ile, kamera gezinmesi sürüklemeyle ayrılır.
- Dar ekranda rehber açıklaması kaydırılabilir; işlem düğmesi sabit görünür. Rehber küçültülebilir ve büyük panel/yerleştirme açıkken gizlenir.
- Turhan: `15_FARMER_MALE.png`; Havva: `16_FARMER_FEMALE.png`.
- Ekipman: `34_TEA_SHEARS.png`, `33_TEA_HARVESTER_MOTOR.png`.
- Kamyon: `14_TEA_TRANSPORT_TRUCK.png`; alım yeri: `35_TEA_COLLECTION_CENTER.png`; fabrika: `09_TEA_FACTORY.png`.
- Hiçbir kaynak PNG değiştirilmedi veya yeniden üretilmedi.

## Doğrulama

- `flutter analyze`: hata/uyarı yok.
- Tüm testler: **237/237**. Yeni M8 alan testleri: **16**; önceki 221 test korunup çakışan UX/ücretsiz işçi beklentileri güncellendi.
- Dar ekran düğme görünürlüğü ve güvenli alan testleri: **1280×720, 960×540, 844×390**.
- `flutter build web`: başarılı.
- `flutter build apk --debug`: başarılı; çıktı `build/app/outputs/flutter-apk/app-debug.apk`.
- Chrome: gerçek dokunma olaylarıyla iptal/ücretlendirme, Havva işe alma, makas satın alma/takma, dört gerçek hasat, dört fiziksel fabrika sevkiyatı, 10 saniye üretim ve 20 kg kuru çay doğrulandı. Son bakiye **1.500 Altın**. Oyun durumu tarayıcıdan değiştirilmedi, süre hızlandırılmadı.
- Turhan ve Havva ile uçtan uca fiziksel zincir ayrı otomatik alan testlerinde doğrulandı.

## Sınırlar

- ADB yalnız çevrimdışı `emulator-5554` gösterdi; Android cihaz/emülatör üzerinde oynanış doğrulaması yapılamadı. APK derlemesi başarılıdır.
- Windows ortamında iOS derlemesi/cihaz testi yapılmadı.
- Kayıt/yükleme bu kapsamda yoktur; yeni oturumda dünya ve eğitim baştan başlar.
- Eğitim işlemleri otomatik yapmaz. İsteğe bağlı ek harcamalar başlangıç bütçesinden düşer; zorunlu hedefler için bütçe ayırmak gerekir.
- Paketleme, satış, XP, seviye, yeni üretim mekaniği, ses ve animasyon sprite sheet'leri eklenmedi.

Milestone 8 kapsamında duruldu.
