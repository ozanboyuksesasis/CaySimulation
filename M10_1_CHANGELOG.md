# M10.1 — Değişiklik ve doğrulama kaydı

## Ölçüm sırası

1. M10_1_BASELINE.md gerçek kaynaklardan yazıldı.
2. Eski 18 saniyelik büyümeyle 20 adet 60 dakikalık başlangıç koşusu kaydedildi: balance_baseline.json/csv.
3. Tek değişkenli büyüme adayı altı koşuda sınandı: balance_candidate.json/csv.
4. Kabul edilen ayarla A–H, işçi/ekipman varyantları ve mevcut dokuz geliştirme karşılaştırması yeniden çalıştırıldı. Ücretli bağlantı yolu varyantıyla son toplam21 koşu; hepsinde5/15/30/60 dakika kontrol noktası.

## Sayısal denge değişikliği

| Dosya / değer | Eski | Yeni | Ölçülen gerekçe |
|---|---|---|---|
| lib/features/plantation/plantation_config.dart growing2Duration |8 s|40 s|Tek tarla eski ayarda müşteri talebini karşılıyor, bütün erken genişleme satış getirisi kayboluyordu.|
| Aynı dosyada toplam growthDuration |18 s|50 s|İlk iki aşama5+5 saniye; yeni getter testleri merkezi süreye bağlar.|

Başlangıç15.000, tüm fiyatlar, hasat25 kg, işçi/araç hızları, fabrika100→20/10 s, paketleme20→20/8 s, müşteri10 s, satış150, XP ödülleri/eşikleri ve normal seviye kilitleri değişmedi.

Kontrol: eski tek tarla ve agresif dört tarla60 dakikada345'er paket. Yeni tek tarla280, normal iki tarla332, agresif dört tarla340 paket. Minimum ilk satış151,2 →280,95 saniye; beş dakikadan önce gerçek gelir var. Bu değişiklik müşteriyi sıklaştırarak Altın üretimini şişirmedi. Minimum işletmenin yatırım dönüşü20:31; normal genişlemede21:01 civarıdır. Kesin zamanlar balance_results.json içindedir.

## Küçük davranış düzeltmeleri

- objective_system.dart: isteğe bağlı ikinci işçi, gelir zincirini hedef kartında artık gizlemez. Fabrika → paketleme → dükkân → ilk satış → ikinci tarla → işçi geliştirme → Seviye6/motor. Okunan hedefler ödeme veya kilit oluşturmaz.
- cay_game.dart: hedeflere gerçek tarla sayısı, harcanmış işçi puanı ve motor sahipliği bağlandı.
- tutorial_system.dart: yeni hedeflerin kategori eşlemesi; işçi geliştirme için mevcut Göster eylemi doğru işçiyi seçer.
- workforce_state.dart / tutorial_rules.dart / player_panels.dart: ilk öğretici işçisi Turhan veya Havva olabilir. İlk seçimde bir defalık Havva başlangıç istisnası vardır; sonraki Havva normal Seviye2 şartını korur. Domain ve UI aynı hireRestriction sonucunu kullanır. Eş zamanlı ikinci başlangıç işçisi alınamaz.
- tutorial_xp.dart: ikinci işçi artık sabit olarak “Havva” sayılmaz; ilk seçilen işçiden farklı gerçek sahiplik aranır. İlk Havva seçiminde ikinci işçi XP'si yanlış verilmez. Ödül miktarları değişmedi.
- retail_system.dart: sadece gözlem amaçlı toplam doğan/ulaşan/satın alan/kayıp müşteri sayaçları eklendi. Stok ve zamanlama bunlara bağlı değildir.

## Simülatör ve kanıt dosyaları

- test/simulation/balance_harness.dart: gerçek oyun birleşimi; kontrollü zaman; tohumlanmış satın alma kararları; işlem defteri; kullanım/kuşak/stok/XP ölçümü; stok dönüşüm ve iş tekilliği kontrolleri.
- test/simulation/balance_runner_test.dart: komut satırı seçimi, JSON/CSV,5/15/30/60 dakika, seed parametresi. Varsayılan regresyonda dışa aktarım kapalıdır.
- test/simulation/report_balance.mjs: gerçek çıktılardan rapor ve düz işçi/seviye CSV kolonları üretir.
- test/simulation/balance_validation_test.dart: yeniden üretilebilirlik, farklı dış zaman adımı,60 dakika kararlılık, minimum sermaye, ücretli yol, kötü harcama koruması, eşdeğer Turhan/Havva, iki işçinin ayrı XP'si, motor kilidi, yeni hedefler, ücretsiz taşıma ve yetersiz sermaye kontrol örneği.
- test/browser_milestone10_1.mjs: Chrome'da gerçek dokunmatik eylemler; ürün/XP/Altın/saat enjeksiyonu yok.

Eski M1–M10 testleri silinmedi. Büyüme için sabit18 saniye kullanan hazırlıklar PlantationConfig.growthDuration'a bağlandı. Aşama sınırı, bağımsız tarla ve dünya ilerleme testleri40 saniyelik son aşamayla aynı davranışı sınar. Eski zorunlu ikinci işçi hedefi ve Havva başlangıç kilidi beklentileri yeni taleple güncellendi.

## Doğrulama

- flutter analyze: başarılı, sorun yok.
- flutter test: **329/329 başarılı** (316 önceki test +13 yeni doğrulama/dışa aktarım testi).
- flutter build web: başarılı.
- flutter build apk --debug: başarılı;208.542.764 bayt.
- APK: build/app/outputs/flutter-apk/app-debug.apk.
- Mobil kopya: C:/Users/Mehmet Demircioglu/Downloads/cay-simulasyonu-m10-1-debug.apk.
- ADB cihaz listesi boş; Android fiziksel cihaz/emülatör oynanış testi yapılmadı.
- Chrome: gerçek NEW GAME, dokunmatik CDP eylemleri ve ekran görüntüsü incelemesiyle öğretici → otomatik hasat → ilk teslimat → Seviye2 → fabrika/paketleme/dükkân → müşteri satın alması (3.000→3.150 Altın) → ikinci tarla → kazanılmış işçi gelişim puanı → dört tarlada gerçek ilerleme → Seviye6 →2.500 Altın motor satın alımı doğrulandı. Ürün/Altın/XP/zaman enjeksiyonu yapılmadı.
- 844×390,960×540,1280×720: dünya, Envanter ve İşletme ekran görüntüleri incelendi; panel içerikleri kaydırılabilir, harita görünür. Yeni panel tasarımı yapılmadı.
- Kanıt: m10_1-browser-observation.json ilk adımlar/zaman aşımı; m10_1-browser-resume.json gerçek ilk satış; m10_1-browser-finish.json gelişim/Seviye6/motor; m10_1_motor_purchased.png. Son CDP oturumunda yakalanan JavaScript istisnası0.
- Başlangıç Chrome profilinin ilk kurulum ekranı ve arka plan durumu test akışını aksattı. Ayrı --no-first-run profili, görünür pencere ve odak emülasyonu ile aynı kayıtlı olmayan canlı oyun üzerinden devam edildi. İlk zaman aşımı başarı sayılmadı; satış daha sonra gerçek HUD değişimiyle doğrulandı. Bu nedenle Chrome duvar saati ekonomi süre ölçümü olarak kullanılmaz; denge süreleri deterministik simülasyondandır.
- Chrome’da bulunan işçi hedefi kategori hatası düzeltildikten sonra tüm329 test, analiz, web ve APK yeniden çalıştırıldı. Mevcut canlı oyunda işçi puanı harita seçimiyle kullanıldı; düzeltilmiş hedef bağlantısının category/targetEntityId sözleşmesi regresyon testinde ayrıca doğrulandı.
- Ek seed20202/E_MINIMUM/5dk kontrolü: ilk satış282,95 saniye;300 Altın gerçek gelir; test başarılı.

## Chrome’da bulunan ek düzeltme

İşçi gelişimi hedefinin kategori bağlantısı, mevcut işçiye ait Göster eylemini gölgeliyordu. workerUpgrade kategorisi null yapıldı; hedef mevcut gelişim puanlı işçiye yönelir. Gerçek altı dakikalık alan simülasyonu ve ikinci tarla yerleşimiyle hedef/category/targetEntityId regresyon beklentileri eklendi. Ekonomi değeri değişmedi.

## Kapsam

Yeni bina, ürün, sanat, animasyon, hava, ses, kayıt/yükleme veya para kazanma sistemi eklenmedi. Paketleme ve reyonun mevcut iç aktarımı korundu. M11 başlatılmadı.
