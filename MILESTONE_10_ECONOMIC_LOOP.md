# M10 — Otomatik üretimden müşteri satışına

## Sonuç

Altın yalnızca müşterinin reyona ulaşıp mevcut ürünü satın almasıyla kazanılır. Hasat, taşıma, fabrika ve paketleme gelir oluşturmaz. Mevcut otomasyon, işçiler, Turhan animasyonu, yol bulma, kurma/taşıma ve Türkçe arayüz korunmuştur.

Çay Tarlası → otomatik hasat → tarla stoğu → kamyon → Çay Alım Yeri → kamyon → Çay Fabrikası → kuru çay → Paketleme Tesisi → reyon → yürüyen müşteri → satış → Altın.

## Başlangıç ekonomisi ve erişim

Normal yeni oyun 15.000 Altın ile başlar. Geliştirici haritasının eski başlangıcı korunur.

| Zorunlu kalem | Altın |
|---|---:|
| İlk tarla | 500 |
| Turhan | 1.000 |
| Çay Makası | 250 |
| İlk ekim | 250 |
| Çay Alım Yeri | 2.500 |
| Çay Fabrikası | 4.000 |
| Paketleme Tesisi | 2.000 |
| Çay Dükkânı | 1.500 |
| Temel zincir toplamı | 12.000 |
| 20 yol karosu payı | 500 |
| Güvenlik payı | 2.500 |
| Başlangıç | 15.000 |

Çiftlik evi, başlangıç yol omurgası ve alım yeri kurulunca kullanılabilen ilk kamyon ücretsiz başlangıç altyapısıdır. Tekrarlanan Altın yardımı veya ara ürün satış ödemesi yoktur.

Gelir erişimi için A seçeneği uygulandı: fabrika, paketleme ve dükkân birlikte Seviye 2'de açılır. Yalnız dükkânı erken açıp fabrikayı Seviye 5'te bırakmak gelir zincirini geciktireceğinden bütün temel zincir erkene alındı. Havva Seviye 2'de isteğe bağlıdır; Depo ve işçi gelişimi Seviye 3, kamyon geliştirmeleri Seviye 4, Çay Motoru Seviye 6'dadır.

İlk gerçek teslimat öğreticiyi bitirir ve mevcut öğretici XP ödülleri oyuncuyu Seviye 2'ye ulaştırır. İkinci işçi hedefi zorunlu değildir. Eksik gelir binalarının bütçesi, isteğe bağlı satın alma/geliştirme ve ek tarla ekimiyle tüketilemez. Ayrılan bütçe ayrı bir para bakiyesi değildir; işlem anında hesaplanan harcama korumasıdır.

## Fiziksel stok ve otomasyon

- Fabrika: 100 kg yaş çay → 10 saniye → 20 kg kuru çay.
- Paketleme: 20 kg kuru çay → 8 saniye → 20 adet 1 kg Paket Çay. Paketleme çıkış kapasitesi 100 adettir.
- Fabrikadan paketlemeye aktarım bu sürümde **yol bağlantısı doğrulanan iç endüstriyel aktarım** kullanır. Yeni kuru çay kamyon işi uygulanmadı.
- Paketlemeden reyona ikmal de bağlantı kontrolünden geçen basitleştirilmiş stok aktarımıdır. Gelecekte dağıtım aracı eklenebilir.
- Aktarım önce kaynak stoktan düşer, sonra tek hedefe geçer. Paketleme sırasında 20 kg açıkça işlem girdisinde tutulur. Reyon stoğu başka bir global envantere kopyalanmaz.
- Dolu çıkış/raf yeni işi veya ikmali sınırlar; negatif stok ve kapasite aşımı engellenir.
- Otomasyon kapalıyken yeni otomatik iş/müşteri başlatılmaz; başlamış süreçler güvenle tamamlanabilir.

## Müşteriler ve satış

Müşteri aralığı 10 saniye, azami aktif müşteri 5, alışveriş beklemesi 2 saniyedir. Müşteriler mevcut yaya A* kurallarıyla dükkânın bitişik etkileşim noktasına yürür ve ayrılır. Binaların içinden geçmezler. Yol bulunmazsa yeni ziyaretçi oluşturulmaz.

Reyon başlangıçta 10 paket alır. Müşteri başına 1 paket, paket başına 150 Altın kazanılır. Boş rafta gelir yoktur. Aynı müşteri işleminin tekrar çağrılması ikinci satış oluşturmaz. Dünya üzerinde kısa +150 geri bildirimi, reyon miktarı ve stok yok bilgisi gösterilir.

## XP ve gelişim

Altın, işletme XP ve işçi XP ayrı kalır. Ödüller olay kimliğiyle tekilleştirilir; görsel animasyonlardan XP verilmez.

- İşletme eşikleri: 100, 150, 225, 325, 450 ek XP; taşan XP korunur.
- İlk hasat toplam 10, sonraki hasat 3 XP.
- İlk alım yeri teslimatı toplam 15, sonraki teslimatlar 5 XP.
- Fabrika teslimatı 10, fabrika kurulumu 30, üretim 15, paketleme 15 XP.
- İlk müşteri satışı toplam 22, sonraki satışlar 2 XP.
- Öğreticinin başarılı tek seferlik eylem ödülleri ayrıca merkezi TutorialXp tanımından gelir; ilk teslimata kadar toplam ilerleme Seviye 2'yi sağlar.
- İşçi yalnız kendi tamamladığı hasattan 10 XP alır. Eşikler 50, 100, 175, 275; sonraki eşikler yapılandırılmış artışla devam eder.
- Her işçi seviyesinde bir gelişim puanı; otomatik seviye bonusu +%2 hasat hızı, harcanan hasat puanı +%3, hareket puanı +%2. Ekipmanın temel değerleri değiştirilmez.

## Altyapı geliştirmeleri

Geliştirmeler en fazla Seviye 3'e çıkar. İkinci geliştirme ilk maliyetin iki katıdır. İşlem anında seviye, Altın, öğretici/bütçe kısıtı ve gerekli meşguliyet kontrolü tekrar yapılır.

| Geliştirme | İlk maliyet | Kademe etkisi |
|---|---:|---|
| Tarla büyümesi | 300 | +%15 hız |
| Alım yeri kapasitesi | 500 | 1.000 → 1.500 → 2.000 kg |
| Kamyon kapasitesi | 750 | 100 → 125 → 150 kg |
| Kamyon hareketi | 750 | +%15 hız |
| Fabrika üretimi | 1.000 | +%20 hız |
| Paketleme | 600 | +%20 hız |
| Reyon kapasitesi | 400 | 10 → 15 → 20 paket |

İşçi gelişimi ve bina geliştirmeleri küçük bağlamsal panellerden erişilir. Mevcut stok geliştirmeyle silinmez; uygun olmayan işlem Altın düşürmez.

## Dosyalar

Yeni çalışma dosyaları:

- lib/features/economy/business_config.dart
- lib/features/buildings/packaging_facility.dart
- lib/features/buildings/tea_shop.dart
- lib/game/systems/retail_system.dart
- lib/game/systems/upgrade_system.dart
- lib/game/components/customer_component.dart
- lib/features/ui/business_controls.dart
- test/retail_economy_test.dart
- test/browser_milestone10.mjs

Mevcut oyun birleşimi, WorldSimulation, GameAssets, merkezi BuildCatalog, fabrika/alım yeri/tarla/araç/işçi modelleri, taşıma kapasite kontrolü, progression ve öğretici kuralları, hedef sistemi, HUD/Envanter/İşletme ve ilgili eski test beklentileri güncellendi. Temel hasat/yaya/araç fiziği yerine paralel bir üretim dünyası kurulmadı.

Kullanılan mevcut sanat dosyaları:

- Paketleme: 36_PACKAGING_FACTORY.png
- Dükkân: 10_VILLAGE_TEA_SHOP.png
- Müşteri: 23_VILLAGE_ELDER.png

Kaynak sanat değiştirilmedi. Paketleme ve dükkânın dış pikselleri saydamdır; Chrome görüntüsünde krem arka plan kutusu görünmez. Önizleme aracındaki krem görünüm oyun içi saydamlık sorunu değildi.

## Doğrulama

- flutter analyze: başarılı, sorun yok.
- Tüm testler: **316/316 başarılı**.
- Yeni ekonomi testleri: stok aktarımı ve dönüşüm, müşteri tekilleştirmesi/boş raf, kapasite, gerçek tam otomatik zincir, bütçe koruması, otomasyon kapatma, müşteri sınırı, taşıma sırasında stok koruma, yükseltmeler ve ayrı XP hesapları.
- flutter build web: başarılı.
- flutter build apk --debug: başarılı; APK 208.541.607 bayt.
- Chrome: gerçek yeni oyun üzerinden hasat, teslimat, fabrika, paketleme, yürüyen müşteri ve ilk satış doğrulandı. Temel zincir sonrası 3.000 Altın, ilk müşteri alışverişinde 3.150 oldu. Ara aşamalar gelir üretmedi.
- Reyon yükseltmesi 10 → 15 doğrulandı.
- 1280×720, 960×540 ve 844×390 görüntüleri incelendi; tarayıcı gözlem raporunda çalışma zamanı istisnası yok.
- Android cihaz testi yapılmadı: emulator-5554 çevrimdışı. APK derleme başarısı cihaz testi olarak sunulmaz.

Çıktılar: m10-browser-observation.json, m10_first_customer_sale.png, m10_retail_844.png ve diğer m10_*.png gözlem görüntüleri. APK ayrıca Downloads/cay-simulasyonu-m10-debug.apk konumuna kopyalandı.

## Bilinen sınırlar

Kuru çay ve paketli ürün için görünür dağıtım aracı henüz yok; bağlantı kontrollü iç aktarım kullanılır. Müşteri mevcut sabit köylü sprite'ı ile yürür, yönlü müşteri animasyonu yoktur. Tek paket türü, bir paketleme tesisi ve bir dükkân desteklenir. Depoya yeni stok mekanikleri eklenmedi. Kayıt/yükleme, yeni sanat ve sonraki aşama içerikleri eklenmedi.
