# V2 kontrollü görsel geçişi — 4 Ekim 2026

## Son güncelleme: kullanıcının temizlediği altı PNG

Downloads'a sonradan sağlanan `14_TEA_TRANSPORT_TRUCK.png`,
`15_FARMER_MALE.png`, `19_TEA_MERCHANT.png`, `21_TEA_FACTORY_SUPERVISOR.png`,
`23_VILLAGE_ELDER.png`, `38_DELIVERY_TRUCK.png` görsel olarak kontrol edildi
ve birebir oyuna aktarıldı. Tavanlar, gömlek/kol bölgeleri ve siluetler sağlam;
alfa kanalları mevcut, dört köşe şeffaf, tuval boyutları eski dosyalarla aynı.
Ek arka plan temizliği, yeniden üretim veya PNG düzenlemesi yapılmadı.

**Güncel sonuç: 28 tekil nesnede sağlam şeffaf görsel kullanılıyor. Mehmet ve
Çay Kamyonu dahil raporda sayılan altı sahne nesnesinin krem dikdörtgeni kalktı.**
Anchor, offset, ölçek ve mantıksal geometri değiştirilmedi.
Yeni kaynakların yedeği `dev_assets/v2_migration/user_cleaned/`, kontrol ve
SHA-256 kayıtları `user_cleaned_audit.json`, karşılaştırmalar
`user_cleaned_review_*.png` içindedir. İlk ret kararları ve orijinaller geçmiş
kayıt olarak korunur. Aşağıdaki ilk geçiş raporunun ret/krem arka plan ve APK
özeti bu güncellemeden önceki durumu anlatır.

Altı yeni PNG ile yeniden doğrulama: `flutter analyze` temiz, **218/218 test
başarılı**, `flutter build web` ve `flutter build apk --debug` başarılı.
Güncel mobil deneme paketi: `Downloads/cay-simulasyonu-v2-cleaned-debug.apk`.
APK içindeki altı PNG'nin SHA-256 değerleri yeni kaynaklarla birebir eşleşir.
Chrome'da 1280×720, 960×540 ve 844×390 yeni oyun/test haritası ve menü
incelemesi geçti; Mehmet ve kamyonun krem dikdörtgenlerinin kalktığı görüldü.

## İlk geçiş kaydı

Bu işlem yeni bir oyun aşaması değildir. Milestone 1–7 kodu ve mekaniği korunmuştur.

## Sonuç

`CAY_SIMULASYON_GAME_READY_V2.zip` içinde 40 orijinal master ve 28 şeffaf PNG
bulundu. 28 adayın tamamı mevcut dosyalarla tam ad ve anlam eşleşmesine sahiptir.
**22 şeffaf PNG kabul edildi; 6 hasarlı şeffaf PNG reddedildi.**
Kabul edilenler ZIP'ten birebir kopyalandı. Reddedilenlerde eski V1 görselleri de
aynı nesne kayıplarını taşıdığı için değiştirilmemiş V2 `original/` masterları
kullanıldı. Önceki 40 oyun PNG'si ayrıca birebir yedeklendi.

### Kabul edilen şeffaf PNG'ler

| Dosya | Kullanım |
| --- | --- |
| 05_FARMER_HOUSE.png | Çiftlik Evi |
| 06_TEA_WAREHOUSE.png | Depo ve katalog görseli |
| 07_TEA_DRYING_STATION.png | Mevcut görsel kütüphanesi |
| 08_TEA_PROCESSING_WORKSHOP.png | Mevcut görsel kütüphanesi |
| 09_TEA_FACTORY.png | Çay Fabrikası ve katalog görseli |
| 10_VILLAGE_TEA_SHOP.png | Mevcut görsel kütüphanesi |
| 11_STONE_BRIDGE.png | Mevcut görsel kütüphanesi |
| 12_VILLAGE_WELL.png | Kuyu ve katalog görseli |
| 13_SMALL_TRACTOR.png | Mevcut görsel kütüphanesi |
| 16_FARMER_FEMALE.png | Mevcut görsel kütüphanesi |
| 17_FACTORY_WORKER.png | Mevcut görsel kütüphanesi |
| 18_MECHANIC.png | Mevcut görsel kütüphanesi |
| 20_TEA_FACTORY_WORKER.png | Mevcut görsel kütüphanesi |
| 22_TRUCK_DRIVER.png | Mevcut görsel kütüphanesi |
| 24_TEA_MERCHANT.png | Mevcut görsel kütüphanesi |
| 31_WHEELBARROW.png | Mevcut görsel kütüphanesi |
| 32_TEA_STRETCHER.png | Mevcut görsel kütüphanesi |
| 33_TEA_HARVESTER_MOTOR.png | Mevcut görsel kütüphanesi |
| 34_TEA_SHEARS.png | Mevcut görsel kütüphanesi |
| 35_TEA_COLLECTION_CENTER.png | Çay Alım Yeri ve katalog görseli |
| 36_PACKAGING_FACTORY.png | Mevcut görsel kütüphanesi; yeni mekanik yok |
| 39_MARKET.png | Test haritasındaki Pazar |

### Reddedilen şeffaf sürümler

| Tam dosya adı | Görsel hasar |
| --- | --- |
| 14_TEA_TRANSPORT_TRUCK.png | Kabin tavanı silinmiş |
| 15_FARMER_MALE.png | Açık renk gömleğin omuz/kol kısımları silinmiş |
| 19_TEA_MERCHANT.png | Sağ açık renk kol silinmiş |
| 21_TEA_FACTORY_SUPERVISOR.png | İki kol/omuz bölgesi silinmiş |
| 23_VILLAGE_ELDER.png | Sağ kol/omuz bölgesi silinmiş |
| 38_DELIVERY_TRUCK.png | Yük kasasının tavanı silinmiş |

Bu altı dosyada sağlam masterın krem arka planı bilinçli olarak korunur.
Arka plan silme, yeniden çizim veya kaynak PNG üzerinde onarım yapılmadı.

## Kontrol ve yedekler

- 28 adayda gerçek alfa kanalı ve şeffaf dış alan sayısal olarak doğrulandı.
- Orijinal/şeffaf çiftleri dama zemininde görsel olarak karşılaştırıldı.
- Kabul edilen 22 görselin dört köşesi şeffaftır; büyük krem dikdörtgen yoktur.
- 09 ve 35'in kenara değen az sayıdaki opak pikseli çevre çizimine aittir.
- Sayısal alfa testi açık renk nesne kaybını tek başına yakalayamaz; ret kararları
  görsel incelemeye dayanır. Orijinal/V1/V2 karşılaştırmaları saklandı.
- `dev_assets/v2_migration/before/`: işlem öncesindeki 40 oyun PNG'si.
- `dev_assets/v2_migration/original/`: ZIP'teki 40 değiştirilmemiş master.
- `dev_assets/v2_migration/transparent/`: 28 aday, reddedilenler dahil.
- Aynı klasörde SHA-256 kayıtları, alfa ölçümleri, dosya kararları, inceleme
  betikleri ve ekran görüntüleri bulunur.
- Bu geliştirme klasörü pubspec asset listesinde değildir. Son APK içinde
  geliştirme yedeği/inceleme dosyası bulunmadığı doğrulandı.

## Geometri ve çizim

**Anchor değişikliği: yok. Offset değişikliği: yok. Görsel ölçek değişikliği: yok.**
Yeni PNG'ler mevcut tuval boyutlarını korur; oran koruyan çizim kullanılmaya devam
eder. Yeni oyun ve test haritasında zemin hizası mevcut ayarlarla kontrol edildi.
Mağaza/envanter aynı yolları kullandığından kabul edilen şeffaf görselleri alır.

**Mantıksal footprint, grid konumu, etkileşim karosu, yol/doluluk, ekonomi ve
oynanış değişmedi.** `lib/` kaynaklarının işlem öncesi/sonrası SHA-256 karşılaştırması:
0 değişen Dart dosyası. Korunan 12 PNG (01–04, 25–30, 37, 40) birebir aynı.
Mevcut testler değiştirilmedi.

| Haritadaki nesne | Krem/beyaz dikdörtgen kalktı mı? |
| --- | --- |
| Çiftlik Evi | Evet |
| Mehmet | Hayır; hasarlı şeffaf yerine sağlam master |
| Çay Alım Yeri | Evet |
| Çay Fabrikası | Evet |
| Çay Kamyonu | Hayır; hasarlı şeffaf yerine sağlam master |
| Depo | Evet |

## Doğrulama

- `flutter analyze`: sorun yok.
- `flutter test --reporter expanded`: **218/218 başarılı**.
- `flutter build web`: başarılı.
- `flutter build apk --debug`: başarılı; APK v2 imzası doğrulandı.
- Yeni oyun, test haritası, mağaza ve envanter küçük resimleri Chrome'da 1280×720,
  960×540 ve 844×390 boyutlarında incelendi. Küçük ekranda haritanın tamamı
  aynı anda görünmez; mevcut kaydırma/yakınlaştırma kontrolleri korunur.
- Chrome dokunma olaylarıyla yeni oyun, satın alma, envanter, iptal, yerleştirme,
  yol, tarla yaşam döngüsü, Mehmet/hasat, kamyon, alım yeri, fabrika sevkiyatı ve
  İşletme özeti doğrulandı. Taşıma/iptal ve geometri regresyonları mevcut testlerde geçti.
- Test haritasında dört hasat → 100 kg alım yeri stoğu → fiziksel fabrika
  sevkiyatı → 10 saniye üretim → 20 kg kuru çay doğrulandı. Altın değişmedi;
  kamyon garaja boş döndü. Tarayıcıda çalışma zamanı istisnası görülmedi.
- İlk eski fare testinin dokunma emülasyonu açıkken tıklaması işlenmedi;
  geliştirme inceleme kopyasında emülasyon sıfırlanarak aynı senaryo geçti.
  Oyun kodunda düzeltme gerekmedi.
- Android cihaz testi yapılmadı: mevcut `emulator-5554` çevrimdışı. iOS bu
  Windows ortamında çalıştırılmadı.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
Kolay erişim kopyası: `Downloads/cay-simulasyonu-v2-assets-debug.apk` (183 MiB).
APK SHA-256: `93172FF267DB1F60893F55379F026C76A0F8E6585A288A90E05944FBE7D57DF6`.
Web yerel geliştirme adresi: `http://127.0.0.1:7361/`; test haritası: `?map=dev`.

## Sınırlar

Altı hasarlı şeffaf sürüm ileride sağlam varlık sağlanana kadar kullanılmayacak.
Tarla/set arka planları kullanıcı talebiyle korunmuştur; bu geçişte işlenmedi.
Kütüphanede bulunan ama sahneye yerleştirilmemiş varlıklar karşılaştırma panolarında
incelendi; bunlar için yeni oyun nesnesi veya mekanik eklenmedi. Milestone 8 başlatılmadı.
