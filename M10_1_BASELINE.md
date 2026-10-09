# M10.1 — Değişiklik öncesi kaynak denetimi

Denetim: 9 Ekim 2026. Aşağıdaki değerler M10 kaynak kodundan okundu; eski rapor varsayımları kullanılmadı. Bu belge denge değişikliklerinden önce oluşturuldu.

| Konu | Gerçek başlangıç değeri | Kaynak |
|---|---|---|
| Normal başlangıç Altını | 15.000; dev harita 10.000 | lib/game/cay_game.dart; lib/features/economy/business_config.dart |
| Tarla / ekim | 500 / 250 | lib/features/builder/build_catalog.dart; lib/features/plantation/plantation_config.dart |
| Turhan / Havva | 1.000; seviye 1 / 2 | lib/features/workers/workforce_state.dart |
| Makas / motor | 250 / 2.500; motor seviye 6 | lib/features/workers/equipment.dart |
| Yol / dekoratif köy kuyusu | 25 / 50 | lib/features/builder/build_catalog.dart |
| Alım yeri / fabrika | 2.500 / 4.000 | aynı katalog |
| Paketleme / dükkân / depo | 2.000 / 1.500 / 1.500 | katalog ve business_config.dart |
| Büyüme | 5 + 5 + 8 = 18 saniye; yenilenme ilk 5 saniyeyi değiştirir | plantation_config.dart; tea_field.dart |
| Hasat | 25 kg; makas 5 s, motor 2,5 s | plantation_config.dart; equipment.dart |
| İşçi | 2 mantıksal karo/s; seviye başına +%2 hasat hızı (otomatik çarpan en çok 2) | worker_config.dart; worker.dart; progression_state.dart |
| Kamyon | 100 kg, 2,5 karo/s; yükleme 3 s, boşaltma 3 s | transport_config.dart |
| Alım yeri | 1.000 kg başlangıç kapasitesi | tea_collection_center.dart |
| Fabrika | 100 kg yaş → 20 kg kuru, 10 s | factory_config.dart; tea_factory.dart |
| Paketleme | 20 kg kuru → 20 adet 1 kg, 8 s, çıkış kapasitesi 100 | business_config.dart; packaging_facility.dart |
| Reyon | 10 paket | business_config.dart; tea_shop.dart |
| Müşteri | 10 s aralık; 2 s bekleme; 1,8 karo/s; en çok 5 aktif | business_config.dart; retail_system.dart |
| Satış | müşteri başına 1 paket × 150 Altın | business_config.dart; tea_shop.dart |

## Minimum gerçek gelir zinciri

Tarla 500 + işçi 1.000 + makas 250 + ekim 250 + alım yeri 2.500 + fabrika 4.000 + paketleme 2.000 + dükkân 1.500 = **12.000 Altın**. Mevcut ücretsiz yol omurgasına doğru yerleşimle ücretli yol zorunlu değildir. 20 ek karo için 500 ayırınca 15.000 başlangıçtan **2.500 hata payı** kalır. Çiftlik evi, yol omurgası ve alım yeri sonrası kamyon başlangıç altyapısıdır.

Ara aşamalarda Altın yok. Öğretici/objektiflerin Altın ödülü yok. Eksik fabrika/paketleme/dükkân fiyatları isteğe bağlı harcamalara karşı TutorialRules.acquisition tarafından korunur; yol onarım bütçesi bu korumaya dahil değildir. Bunun kötü yerleşim senaryosunda ölçülmesi gerekir.

## XP, kilitler ve öğretici

Kaynaklar: lib/features/progression/progression_state.dart; lib/game/systems/tutorial_xp.dart, tutorial_rules.dart, tutorial_system.dart, objective_system.dart.

İşletme ek XP eşikleri: 100,150,225,325,450; sonrasında 450+(seviye-5)×150. İşçi eşikleri: 50,100,175,275; sonrasında 275+(seviye-4)×125. Taşan XP korunur.

İşletme: ilk hasat 10, tekrarı 3; ilk alım teslimatı 15, tekrarı 5; fabrika teslimatı 10; fabrika kurma 30; fabrika partisi 15; paketleme partisi 15; ilk satış 22, tekrarı 2. İşçi kendi hasadından 10 XP.

Tek seferlik öğretici XP: tarla10, işçi10, makas10, donatım10, ekim10, hazır5, merkez15, bağlantı5; isteğe bağlı ikinci işçi10, ikinci makas10, ikinci donatım10. İlk hasat/teslimatla ilk teslimata kadar toplam100 XP. Olay kimlikleri ödülü tekilleştirir. Hedefler ödül vermez.

Seviye1: ilk tarla, Turhan, makas, yol, merkez. Seviye2: Havva, ek tarlalar, fabrika, paketleme, dükkân. Seviye3: depo, işçi gelişimi. Seviye4: kamyon geliştirmeleri. Seviye6: motor. İlk öğretici mevcut kodda yalnız Turhan'a izin verir; Havva seviye2 gerektirir. Kullanıcıdaki “Turhan veya Havva” talebiyle bu noktada fark vardır; kilidi hileyle atlamadan ayrıca değerlendirilecektir.

Mevcut isteğe bağlı hedef sırası: Seviye2 → ikinci işçi → fabrika → ilk kuru çay → paketleme → dükkân → ilk satış → Seviye6. İkinci işçi alınmayınca gelir hedeflerinin görünmemesi olası yönlendirme sorunudur.

## Geliştirmeler

Kaynak: lib/game/systems/upgrade_system.dart; ilgili modelde türetilen istatistikler. En çok seviye3; fiyat ilk maliyet × 2^(mevcut seviye−1).

| Dal | İlk fiyat | Kademe etkisi |
|---|---:|---|
| Tarla büyümesi |300|+%15 hız|
| Alım kapasitesi |500|+500 kg|
| Kamyon kapasitesi |750|+25 kg|
| Kamyon hızı |750|+%15|
| Fabrika hızı |1000|+%20|
| Paketleme hızı |600|+%20|
| Reyon |400|+5 paket|

Her işçi seviyesi bir gelişim puanı; hasat puanı +%3, hareket puanı +%2. Bunlar ekipman tabanını değiştirmez. Puan harcama işletme seviye3 ve boşta işçi gerektirir.

## Saat, yollar ve sahiplik

WorldSimulation.advance gerçek alan sistemlerini çalıştırır; perakende varsa iç adımlar en çok50 ms, ayrıca işçi/nakliye/tarla/fabrika olay sınırlarında bölünür. Müşteri sistemi rastgele değil deterministiktir. Fabrika→paketleme ve paketleme→reyon, gerçek yol bağlantısı arayan iç transferlerdir. Yaş çay kamyonla fiziksel taşınır. Her konteyner tek otoritedir; işlem girdileri ayrıca sayılır. Simülatör bu gerçek bileşimi render/load çağırmadan kullanacaktır.
