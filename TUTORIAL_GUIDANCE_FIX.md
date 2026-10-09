# Öğretici, XP ve ikinci işçi düzeltmesi

Normal yeni oyun, yalnızca mevcut öğretici adımının işlemlerini kabul eder.
Kontrol yalnızca düğmelerde değildir: edinme, yerleştirme, ekim, ekipman
değişimi ve taşıma komutları da aynı `TutorialRules` politikasını kullanır.
Dev test haritası ve açıkça rehbersiz oluşturulan regresyon senaryoları korunur.

## Akış

İlk tarla → Turhan → makas → ekipman ata → ekim → otomatik büyüme/hasat
→ Alım Yeri/yol → otomatik teslimat → Seviye 2 → Havva → ikinci makas
→ Havva'ya ekipman ata → serbest oyun.

Havva Seviye 2'de açılır. İlk işçi adımında yalnızca Turhan alınabilir.
Seviye yeterli olsa dahi başka öğretici adımında Havva satın alınamaz.
Envanteri Aç/Göster eylemleri hedef kartı daraltılmışken de görünür.

## Bir defalık öğretici XP

| Başarı | XP |
|---|---:|
| İlk tarla | 20 |
| İlk işçi | 10 |
| İlk makas | 10 |
| İlk ekipman atama | 10 |
| İlk ekim | 10 |
| İlk büyüme tamamlandı | 5 |
| İlk gerçek hasat (mevcut işletme ödülü) | 10 |
| Alım Yeri | 15 |
| Gerçek yol bağlantısı | 5 |
| İlk gerçek teslimat (mevcut işletme ödülü) | 5 |
| **İlk teslimat toplamı** | **100: Seviye 2** |
| Havva işe alındı | 10 |
| İkinci makas alındı | 10 |
| Havva ekipmanını aldı | 10 |

Ödüller gerçek durumdan çıkarılır, olay kimliğiyle tekrar verilmesi engellenir.
Başlayalım veya Envanteri Aç gibi düğmeler XP üretmez. İptal/başarısız işlem
ödül vermez. Bildirimde eylem ve +XP miktarı görünür; aynı işlemdeki satın
alma başarı mesajı XP bildirimini örtemez. İşçi XP'si ayrıca gerçek hasada bağlıdır.

## Bütçe ve çalışanlar

Başlangıç 10.000 Altın; tüm fiyatlar aynı. İki işçi ve iki makas dahil zorunlu
kurulum fabrika ile 9.750 Altın tutar. Bağlantı yollarına 250 Altın ayrılabilir.
İlk tarla başlangıç yoluna erişebilir bir yerde kurulmalıdır. Sonraki zorunlu
alımların bütçesi korunur. İlk fabrika kurulana kadar 4.000 Altın başka alımlarda
harcanamaz; para verilmez veya stoktan düşülmez. Yol harcanmazsa öğretici
sonunda 4.250, fabrika kurulunca 250 Altın kalır.

İş dağıtımı ulaşabilen, ekipmanlı, boş işçiler arasından en uzun süredir görev
almamış olanı seçer; eşitlikte yol uzunluğu ve sabit kimlik kullanılır. Böylece
uzaktaki Havva, sırayla olgunlaşan tek tarlada sürekli Turhan'ın arkasında kalmaz.
İki işçinin eşzamanlı farklı tarlalarda çalışması korunur. Hız, verim ve sanat değişmez.

## Dosyalar ve doğrulama

- Yeni: `tutorial_rules.dart`, `tutorial_xp.dart`, `guided_tutorial_test.dart`,
  `browser_guided_tutorial.mjs`.
- Güncellenen: tutorial/progression, CayGame, builder/shop/plantation/workforce/job
  servisleri; tutorial coach, katalog, işçi/tarla kartları ve bildirimler.
- Önceki bağımsız senaryolar açık rehbersiz test kurulumu kullanır. Yeni öğretici
  testleri gerçek varsayılan yeni oyunla tüm kısıtları ve bütçeyi doğrular.
- `flutter analyze`: temiz.
- Testler: 299/299.
- `flutter build web`: başarılı.
- Android debug APK: başarılı. ADB emülatörü offline; fiziksel Android testi yok.
- Chrome gerçek dokunmatik akış: ilk teslimat, Seviye 2, Havva + ekipman,
  fabrika ve otomatik 20 kg kuru çay üretimi geçti.
- Chrome boyutları: 844×390, 960×540, 1280×720. Eylem görünürlüğü, iptal,
  adım dışı taşıma engeli, pan/pinch ve taşmayan Envanter kontrol edildi.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
Kolay erişim kopyası: `Downloads/cay-simulasyonu-ogretici-debug.apk`.
Kayıt/yükleme eklenmedi; yeni öğretici yeni oyun oturumunda başlar.
