# Otomasyon / Tycoon / İlerleme — Milestone 9

## Uygulanan akış

Oyuncu Envanterden yapı kurar, işçi işe alır, ekipman satın alıp atar ve tarlayı ilk kez diker. Sonraki işler kendiliğinden yürür:

**Büyüme → uygun ekipmanlı işçi → fiziksel hasat → 25 kg tarla stoğu → yol üzerinden kamyon → Çay Alım Yeri → aynı kamyon → fabrika → 100 kg yaş çay / 10 saniye → 20 kg kuru çay.**

Normal oyunda otomasyon varsayılan olarak açık. `Hasat Et`, `Taşıma Emri Ver`, `Fabrikaya Sevk Et` ve `Üretimi Başlat` normal otomatik arayüzden kaldırıldı. İlk dikim ve işletmeyi kurma kararları oyuncuda kaldı. Fiyatlar, hareket hızları, ürün miktarı ve üretim tarifi korunuyor; üretim para kazandırmıyor.

## Mimari ve güvenlik

- `AutomationSystem` yalnız iş keşfeder ve mevcut domain komutlarını çağırır. Hareket, yükleme, boşaltma ve stok işlemleri mevcut JobSystem / TransportSystem / TeaFactory içinde kalır.
- Hasatlar hazır olma zamanına, eşitlikte tarla kimliğine göre keşfedilir. Uygun boş işçiler arasında en kısa erişilebilir A* yolu; eşitlikte kararlı işçi kimliği seçilir. Meşgul işçiye ikinci eşzamanlı görev verilmez.
- Tarla ve fabrika nakliyeleri aynı FIFO kuyruğunu paylaşır. Kaynak başına aktif iş, rezervasyon görevi görür. Ayrı, kopya bir çay stoğu oluşturulmadı.
- Araç yalnız mantıksal yol/erişim karolarında hareket eder. Yol yoksa yeni başarısız iş yağmuru oluşmaz. Yüklü kamyonun yolu kesilirse yük korunur; yol topolojisi değişince tekrar denenir.
- Geri dönen boş kamyon yeni iş geldiğinde garaja varmayı beklemeden yönlenebilir.
- `WorldSimulation` büyüme, hareket, hasat, yükleme, boşaltma ve üretim sınırlarında zamanı böler. Büyük/küçük zaman adımlarıyla aynı stok ve XP sonucu test edildi.
- Stok sıfırlandığında tarla yeniden büyür. Yükleme/boşaltma bitmeden çay aktarılmaz. Üretim girdisi açıkça ayrılır; taşıma kütleyi korur, üretim ise mevcut 100→20 tarifini uygular.
- Geliştirici menüsündeki **Otomasyon: Açık/Kapalı** yalnız yeni otomatik iş keşfini durdurur. Mevcut işler/kuyruk güvenle tamamlanabilir. Kapalı durumdaki manuel komutlar test amacıyla korunur; test haritası eski manuel varsayılanını korur.

## İşletme ve işçi XP

`ProgressionState` overflow ve tek ödülde birden çok seviye artışını destekler. Ödüllenen olay kimlikleri tutulur; aynı tamamlanma tekrar bildirildiğinde XP verilmez. İşletme ödülleri gerçek hasat/teslimat/üretim tamamlanma kancalarına bağlıdır. Görsel olaylardan XP üretilmez.

| Gerçek olay | İşletme XP |
|---|---:|
| İlk hasat | 10 |
| Sonraki her hasat | 5 |
| Alım Yerine teslimat | 5 |
| Fabrikaya teslimat | 10 |
| Üretim partisi | 20 |

İşletme seviye eşikleri: **100, 150, 225, 325, 450** (1→6). Sonrasında gereksinim `450 + (seviye - 5) × 150`: 6→7 için 600 XP.

Her işçi yalnız kendi tamamladığı hasattan **10 işçi XP** alır. İşçi eşiği `100 + (seviye - 1) × 50`. Hasat hızı çarpanı `1 + min((seviye - 1) × 0,02; 1)`: en fazla 2×. Süre ekipman taban süresinin bu çarpana bölünmesiyle hesaplanır; ekipman tanımı değiştirilmez. Seviye 2 makas süresi yaklaşık **4,902 saniye**. İşin süresi atama anında sabitlenir. Hareket hızı değişmez.

`UnlockSystem`, katalogdaki `requiredLevel` bilgisini okur. Çay Motoru **Seviye 6**, fiyatı **2.500 Altın**, taban hasat süresi **2,5 saniye**. Kilit Envanterde görünür ve domain satın alma kontrolünde de uygulanır. Diğer mevcut içerikler Seviye 1'de korunur. Yapı yerleştirme ve eski test satın alma servisleri de seviye kontrolüne hazırdır.

## Rehber ve arayüz

- Öğretici otomasyonu anlatır; hasat ve taşıma emri istemez. Turhan veya Havva ile **bir gerçek hasat ve bir gerçek Alım Yeri teslimatında** biter.
- Ayrı `ObjectiveSystem` serbest oyunda işletme Seviye 2 → fabrika → ilk kuru çay → Seviye 6 / motor hedeflerini gerçek durumdan okur. Kontrolleri kilitlemez, altın ödülü vermez.
- HUD'a kompakt seviye/XP; işçiye bağımsız seviye, XP ve hesaplanan hasat süresi eklendi. Seviye artışı kısa bildirimle gösterilir.
- Haritada işçi/nakliye bekleyen tarlalar, ürün çuvalı, fabrika gereksinimi ve eksik fabrika girdisi görünür. Kuyrukta bekleyen iş, aktif hasat gibi gösterilmez.
- Turhan/Havva görselleri, Turhan'ın 140 ms dört yönlü animasyonu, seçim/derinlik sistemi ve PNG dosyaları değiştirilmedi.

## Dosyalar

Yeni:

- `lib/features/progression/progression_state.dart`
- `lib/game/systems/automation_system.dart`
- `lib/game/systems/objective_system.dart`
- `test/automation_progression_test.dart`
- `test/automation_ui_test.dart`
- `test/browser_milestone9.mjs`
- Bu rapor.

Güncellenen domain/bağlantı dosyaları:

- `game/cay_game.dart`, `systems/world_simulation.dart`, `systems/grid_pathfinder.dart`, `systems/tutorial_system.dart`, `systems/world_status.dart`, `components/world_status_layer.dart`.
- `features/workers/{worker,job_system,equipment,workforce_state}.dart`.
- `features/transport/transport_system.dart`, `features/buildings/tea_factory.dart`.
- `features/builder/{build_catalog,builder_system}.dart`, `features/shop/shop_service.dart`.
- `features/ui/{game_hud,player_panels,field_info_panel,transport_info_panel,factory_info_panel,worker_info_panel,tutorial_coach}.dart`.

Eski test güncellemeleri: `builder_test`, `builder_ui_test`, `milestone8_test`, `shop_inventory_test`, `transport_test`. Manuel servis regresyonları otomasyon kapalı fixture ile korunuyor. Motor testleri gerekli seviyeyi açıkça sağlıyor; normal oyun arayüz testi otomatik hasadı doğruluyor.

## Doğrulama

- `flutter analyze`: temiz.
- `flutter build web`: başarılı; son paket `build/web` altında.
- `flutter build apk --debug`: başarılı. APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Kullanıcı kopyası: `C:/Users/Mehmet Demircioglu/Downloads/cay-simulasyonu-m9-otomasyon-debug.apk`.
- Kaynak APK ve İndirilenler kopyası SHA-256: `2129EA7CEEA69A9505AFD89ACE1874C4733A5170513AA16967004E23A828A7D8`.
- Flutter testleri: **288/288**; önceki 259 teste 29 yeni test eklendi.
- Yeni kapsam: otomatik uçtan uca üretim, FIFO/tek rezervasyon, iki işçi, erişilebilir/en yakın/kararlı atama, eksik ekipman, kopuk/onarılmış yol, yük kaybı olmaması, 100+50 kg kapasite bölünmesi, otomasyonu kapatma, zaman adımı bağımsızlığı, XP tekrar koruması/taşma, işçi hız sınırı, Seviye 6 domain ve canlı UI kilidi, iki işçi seçimiyle tek teslimatlı öğretici ve dünya bekleme göstergeleri.
- Chrome gerçek zaman/dokunmatik senaryosu: kur → işe al → ekipman → ilk dikim; ardından **hiç manuel iş komutu olmadan** hasat, teslimat, fabrika sevkiyatı ve 20 kg kuru çay. Bu senaryoda bakiye **1.500**, işletme **Seviye 2 / 5 XP** oldu.
- Chrome boyutları: **1280×720, 960×540, 844×390**. Envanter, yerleştirme/iptal, uzun basma, taşıma iptali, pan ve pinch geçti. JavaScript çalışma zamanı istisnası yok.
- Görsel kanıtlar: `m9_automatic_worker_walk.png`, `m9_automatic_transport.png`, `m9_automatic_tutorial_completed.png`, `m9_automatic_factory_output.png`, `m9_motor_locked.png`, `m9_inventory_844.png`.

## Sınırlar

- Android emülatörü `offline`; fiziksel Android/iOS cihazında doğrulama yapılmadı. Web geliştirme/test, Android/iOS asıl hedef olmaya devam ediyor.
- Öncelik ayarlama, işçi bölgeleri, yeni araç satın alma, kayıt/yükleme, satış ve yeni üretim sistemi eklenmedi.
- XP/iş geçmişi oturum içinde tutulur; kalıcı kayıt yok. Seviye ve hız değerleri ilk deneme dengeleridir.
