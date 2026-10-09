# Milestone 7 — Mobil mağaza, envanter ve işletme arayüzü

## Uygulanan akış

**MAĞAZA → SATIN AL → ENVANTER → YERLEŞTİR → HARİTADA GERÇEK GAMEPLAY ENTITY**

Yeni oyun yine 10.000 Altın, Çiftlik Evi, Mehmet ve temel yollarla açılır.
Ücretsiz üretim yapısı verilmez; yerleştirilebilir envanter boştur.
Satın alınan tarla için 500 Altın yalnız satın almada düşer. Menü kapanabilir;
öğe envanterde bekler. Yerleştirme onayında bir adet tüketilir, Altın tekrar düşmez.
Geçersiz konum veya iptal öğeyi korur. Bakiye sonradan sıfır olsa bile önceden
satın alınmış bir yapı yerleştirilebilir.

**ANDROID/iOS: ana oyun hedefi; yatay ve dokunmatik. WEB: geliştirme/test hedefi.**

## Domain mimarisi

`ShopService` aynı `BuildCatalogItem` listesini kullanır. Katalog kimliğini doğrular,
yerleşik + envanterdeki toplam sahipliği sayar, tekil sınırı ve parayı kontrol eder,
tek `EconomyState` üzerinden bedeli düşer ve `PlayerInventory.addPlaceable` çağırır.
Dünyaya nesne eklemez ve yerleştirme modunu açmaz. Alım yeri/fabrika sınırı 1'dir;
envanterde bekleyen bina da bu sınırı doldurur. Reddedilen işlem para harcamaz.

`PlayerInventory`: katalog kimliği→adet haritası, doğrulanan ekleme/tüketme API'si,
salt okunur görünüm ve JSON uyumlu veri. Negatif veya sıfır işlem miktarı reddedilir;
yetersiz adet tüketimi false döner. `addPlaceable` satın almadan bağımsızdır; gelecekte
yapıyı depoya kaldırma için kullanılabilir. Kaldırma/satma bu aşamada uygulanmadı.

Global kaynaklar için ayrı `GlobalResource` alanı hazırdır ve başlangıçta boştur.
Tarla stoğu, kamyon yükü, alım yeri veya fabrika ürünleri buraya aktarılmaz.
Eski `InventoryState` uyumluluk için kaldı; fiziksel zincir tarafından doldurulmaz.

`BuilderSystem` artık EconomyState kullanmaz. Doğrulanmış yeni yerleştirmede
PlayerInventory'den bir adet tüketir. M6 doluluk, gerçek domain/bileşen oluşturma,
dinamik A*, yol bağlantısı, kimlikler, önizleme ve taşıma sistemi aynı kalır.
Normal oyunda ikinci bir doğrudan satın al/yerleştir yolu yoktur.

Yol karoları da 25 Altına tek tek mağazadan satın alınır. Envanterdeki yol seçilince
tekrarlı yerleştirme açılır; her ayrı dokunuş yalnız bir stok tüketir. Sürükleme/pinch
satın almaz veya yerleştirme yapmaz. Stok bitince yeni yol eklenemez. Bitir/İptal
elde kalan yol stoklarını korur; daha önce onaylanmış karolar geri alınmaz.

## İşletme ve kaynak özeti

`ResourceSummary` saklanan bir toplam değil, mevcut modellerden okuyan getter'lardır:

- Tarla stoklarının toplamı.
- Kamyon yükü.
- Çay Alım Yeri stoğu.
- Fabrikanın yaş çay stoğu.
- Üretimde ayrılmış yaş çay girdisi.
- Fabrikanın kuru çay stoğu.

Toplam yaş çay üretime ayrılmış girdiyi de kapsar; üretim başlatınca çay kaybolmuş
gibi gösterilmez. Üretim tamamlandığında mevcut 100→20 reçetesi uygulanır.
Nakliye kütle korunumunu veya üretim mantığını değiştiren yeni mekanik eklenmedi.
İşletme paneli yalnızca okur; stokları değiştirmez veya gelir üretmez.

## Arayüz, gezinme ve dokunma

`GameNavigation` tek `GamePanel` tutar: none/shop/inventory/business.
Bir panel açılınca diğeri kapanır. Yerleştirme/taşıma büyük panelleri kapatır;
bir ana panel açılması da mevcut önizlemeyi stok kaybı olmadan iptal eder.
`opened` ve `ShopService.purchases` olayları ile sabit widget anahtarları gelecekte
eğitim yönlendirmelerine uygundur. Eğitim veya ilerleme sistemi uygulanmadı.

Alt gezinme: Mağaza / Envanter / İşletme; en az 48 mantıksal piksel yükseklik.
Mağaza kategorileri kaydırılabilir; kartlarda master PNG, ad, fiyat, sahiplik,
adet sınırı, açıklama ve Satın Al düğmesi bulunur. Tekil sınırda düğme devre dışıdır
ve Zaten sahip gösterir. Envanter yalnız adedi pozitif öğeleri listeler.
Kaynaklar için yanıltıcı global çay listesi oluşturulmadı.

Paneller yatay ekranda sınırlı yüksekliğe ve kaydırılabilir içeriğe sahiptir.
SafeArea kesikleri ve sistem gezinme alanlarını dışarıda tutar. Yerleştirme
Yerleştir/İptal, yol Bitir/İptal, taşıma Onayla/Vazgeç düğmeleriyle yönetilir.
Fare hover, sağ tık, tekerlek veya klavye hiçbir oyun eylemi için gerekli değildir.

Seçim kartı kapatılabilir; ana menü açıkken gizlenir. Mevcut hasat/nakliye/üretim
eylemleri korunur. Meşgul Taşı düğmesi devre dışıdır; dokununca kısa neden gösterilir.
Normal karttaki hasat sayısı ve yinelenen geliştirici ayrıntıları debug'a alındı.
Koordinatlar ve yollar Izgara ile açılır; test haritası seçimi normal oyunda
debug açıkken görünür. `?map=dev` erişimi korunur.

`GameNotifications` önceki bildirimi değiştirir ve üç saniye sonra kaldırır.
Bildirimler IgnorePointer altında dokunmayı engellemez; satın alma/başarısız işlem
ve yerleştirme yönlendirmesi için kullanılır. Altın ve envanter sayısı hemen güncellenir.
Karmaşık efekt veya animasyon eklenmedi.

UI dinleyicileri ilgili modelleri izler. Para/menü/envanter değişimi Flame dünyasını
yeniden oluşturmaz. BusinessPanel yalnız açıkken fiziksel stok değişimlerini izler.

## Dosyalar

Oluşturulanlar:

- `lib/features/shop/shop_service.dart`
- `lib/features/economy/player_inventory.dart`
- `lib/features/economy/resource_summary.dart`
- `lib/features/ui/game_navigation.dart`
- `lib/features/ui/game_notifications.dart`
- `lib/features/ui/player_panels.dart`
- `test/shop_inventory_test.dart`
- `test/mobile_panels_test.dart`
- `test/browser_milestone7.mjs`
- `MILESTONE_7.md`

Değiştirilenler:

- `lib/features/builder/builder_system.dart`: satın alma yerine stok tüketimi.
- `lib/game/cay_game.dart`: mağaza/envanter/özet/gezinme/bildirim bağlama ve dispose.
- `lib/features/ui/builder_overlay.dart`: sadece dokunmatik yerleştirme kontrolleri.
- `lib/features/ui/game_hud.dart`: alt paneller, kompakt normal HUD, kapatılabilir seçim,
  devre dışı meşgul taşıma, dokunmayı engellemeyen bildirim.
- `lib/features/ui/field_info_panel.dart`: bildirim ve debug ayrıntısı ayrımı.
- `lib/main.dart`: ana düğmeler için 48 piksel dokunma hedefi teması.
- `test/builder_test.dart`, `test/builder_ui_test.dart`, `test/browser_milestone6.mjs`:
  eski M6 yerleştirme senaryoları önce satın alma yapacak şekilde uyarlandı;
  konum, doluluk, stok, hareket, yol ve fiyat doğrulamaları korundu.
- `README.md`.

## Assetler

Yeni çizim üretilmedi, PNG değiştirilmedi. Menü görselleri aynı master kütüphanedir:
01_FIELD_EMPTY, 06_TEA_WAREHOUSE, 09_TEA_FACTORY, 35_TEA_COLLECTION_CENTER,
25_DIRT_ROAD_SET, 12_VILLAGE_WELL. Dünya 05_FARMER_HOUSE, 14_TEA_TRANSPORT_TRUCK,
15_FARMER_MALE ve mevcut tarla gelişim PNG'lerini kullanmaya devam eder.

## Test ve manuel doğrulama

- `flutter analyze`: sorun yok.
- Tüm Dart/Flutter testleri: **218/218 başarılı**. Önceki 177 + 38 yeni domain testi
  + 3 farklı ekran ölçüsünde yeni kapsamlı widget testi.
- Domain testleri satın alma, yetersiz para, tekil sahiplik, stok tüketme/iptal,
  ikinci kez ödeme olmaması, negatif stok engeli, kaynak toplamları ve üretimdeki
  girdi, bağımsız envanter API'si, JSON, olaylar, gerçek hasat/nakliye/üretimi kapsar.
- Mobil widget testleri 1280×720, 960×540, 844×390 ölçülerinde kenar/bottom safe area,
  minimum dokunma hedefleri, bildirim süresi, menülerin birbirini kapatması,
  pinch sırasında kazara yerleştirmeme, iptal ve gerçek tarla oluşturmayı kapsar.
- `flutter build web`: başarılı.
- Chrome'da `browser_milestone7.mjs` gerçek dokunma olayları ve gerçek geçen zamanla
  çalıştırıldı; oyun durumuna test verisi enjekte edilmedi. İlk 500 Altınlık satın
  alma haritayı boş bıraktı; envanterden yerleştirme yeniden ücret almadı. İkinci
  tarla iptalinde adet korundu. Alım yeri/fabrika satın alındı ve gerçek modeller
  oluşturuldu. Mehmet hasat etti; 25 kg çay aynı kamyonla alım yerine, ardından
  fabrikaya taşındı. İşletme özeti fiziksel yer değişimini gösterdi. İki satın
  alınan yol stoktan yerleştirildi. Üç yatay çözünürlükte menüler kontrol edildi.
- Görsel kayıtlar: `milestone7_*.png`.

- `flutter build apk --debug`: başarılı; APK imzası `apksigner verify` ile doğrulandı.
  Çıktı: `build/app/outputs/flutter-apk/app-debug.apk`.
  Kolay erişim kopyası: `Downloads/cay-simulasyonu-m7-debug.apk`.

ADB kontrolünde `emulator-5554 offline` görüldü; bağlı/çalışır Android cihaz yoktu.
Fiziksel Android/iOS cihaz doğrulaması yapılmış olarak raporlanmaz.

## Sınırlar

Kayıt sistemi yok; yenileme veya harita değişimi yeni oturum başlatır. Envanterdeki
öğeler de oturumla sınırlıdır. Yol görselleri M6 genel karo çizimini kullanır.
Bazı kaynak PNG arka planları korunur. Dekorasyon mevcut kuyu ile sınırlıdır.
Kaldırma/satma/yükseltme, global çay envanteri, ayrıntılı eğitim, seviye, paketleme,
satış, ses, ek animasyon, backend veya sonraki milestone mekanikleri eklenmedi.
