# M10.1 — Ölçüm ve denge raporu

## Yöntem ve tekrar üretme

Gerçek CayGame birleşimi oluşturulur; onLoad, Flame render, görsel animasyon veya gerçek zaman bekleme çağrılmaz. Aynı builder, öğretici, işçi, otomasyon, kamyon, üretim, paketleme ve müşteri sistemleri çalışır. Alan saati Duration ile ilerler. Dış ölçüm adımı 250 ms, WorldSimulation iç adımı en çok50 ms ve gerçek olay sınırlarıdır. Bir saniyede bir stok/iş/Altın/işçi XP değişmezleri kontrol edilir. Kullanım oranları 250 ms örneklenmiş tahminlerdir; olay/işlem zamanları alan saatinden alınır.

Tohum **10101** karar aralıklarını belirler. Dünya müşteri aralığı rastgele değildir; 10 saniyedir. Aynı tohumla işlem defteri ve kontrol noktalarının bitişik JSON karşılaştırması otomatik testte aynıdır. 5/15/30/60 dakika tüm 21 senaryoda kaydedilir. Müşteri/ürün/XP/Altın enjekte edilmez. Varsayılan flutter test yalnız doğrulama testlerini çalıştırır; uzun dışa aktarım açık bayrak ister.

Proje kökünden:

```powershell
& C:\codespace\sdk\flutter\bin\flutter.bat test test/simulation/balance_runner_test.dart --dart-define=BALANCE_RUN=true --reporter expanded
```

İsteğe bağlı bayraklar: BALANCE_SCENARIO=A_NORMAL,E_MINIMUM; BALANCE_MINUTES=5/15/30/60; BALANCE_SEED=10101; BALANCE_OUTPUT=balance_results. Komut flutter test ile çalışır çünkü gerçek uygulama bileşimi dart:ui ve Flutter ChangeNotifier kullanır; grafik bağlamı/Chrome gerekmez.

## Değişiklik öncesi kanıt

İkinci tohum **20202**, E_MINIMUM için ayrıca5 dakika çalıştırıldı: ilk satış282,95 saniye, iki paket/300 Altın gelir,0 Altın ödülü; balance_seed20202.json/csv. Bu ek kısa kontrol21 tam koşunun yerine geçmez.

balance_baseline.json/csv, eski 18 saniyelik büyümeyle çalıştırılmış 20 senaryonun çıktısıdır. Parametre değiştirilmeden önce kaydedildi. balance_candidate.json/csv tek değişkenli aday denemesidir. balance_results.json/csv kabul edilen ayarla tam tekrar çalıştırmadır.

Eski tek tarlalı G_SHEARS, 60 dakikada 345 paket satıyordu. Dört tarlalı C_AGGRESSIVE de 345 paket satıyordu: erken genişlemenin ek satış getirisi yoktu. Tek tarlada büyüme dahil üretim müşteri talebini aşıyordu.

## Kabul edilen tek sayısal değişiklik

PlantationConfig.growing2Duration **8 → 40 saniye**; toplam büyüme **18 → 50 saniye**. İlk iki aşama5+5, yenilenmenin ilk aşaması5 saniye olarak kaldı. İlk ekimden sonra tekrar ekim ücreti yok. Fiyat, başlangıç sermayesi, müşteri sıklığı, kapasite, hasat verimi, taşıma süresi, reçete, XP ödülü/eşiği değiştirilmedi.

Gerekçe: müşteriyi iki kat sıklaştırarak Altın üretimini artırmak yerine, mevcut 6 müşteri/dakika talebine göre hammaddeyi anlamlı bir erken kapasite kararına çevirmek. Minimum zincir ilk satışı beş dakikadan önce yapıyor; iki tarla satış açığını kapatıyor. Bu sonuç örnek harita/yerleşim ve bu satın alma politikalarına aittir; her olası harita için denge garantisi değildir.

## Sermaye ve sürdürülebilirlik

Tarla500 + Turhan1000 + makas250 + ekim250 + merkez2500 + fabrika4000 + paketleme2000 + dükkân1500 = **12.000**. Mevcut ücretsiz yol omurgası minimuma yeter. Normal **15.000** sermayeden 20 yol karosu için500 ayrıldığında **2.500 güvenlik payı** vardır. Başlangıç Altını değiştirilmedi. Ara ürün geliri, öğretici Altın yardımı veya tekrar eden kurtarma parası yoktur.

Koruma, eksik gelir binalarının parasını isteğe bağlı alımlara karşı ayırır. D senaryosu bu korumaya çarpar, 0 nakitle tamamladığı zincirden gerçek müşteri geliri elde eder. Yer değiştirme ücretsizdir; ayrıca 0 Altınla bina taşıyıp gelir sürdürülebilirliği test edilir. Bunlar ekonomik çıkmaz değil, zaman kaybıdır. Her karoyu kötü yol/dekorla doldurmanın tüm olası uzamsal kombinasyonları ispatlanmadı; harita tıkanıklığı genelleştirilmiş bir kurtarma sistemi olarak sunulmaz.

Ek olumsuz kontrol: 11.999 Altın ile minimum zincirin eksik bir Altını gerçek bir sermaye yetersizliği olarak doğrulanır; büyümeyi beklemek bunu çözmez. Normal 15.000 başlangıç bu duruma düşmez. E_ROADS kontrolü dört ücretli yolun gerçek kamyon rotasında kullanıldığı 12.100 Altınlık kurulumu ayrıca ölçer.

## Senaryo politikaları

- A_NORMAL: öğreticide her başarılı adımdan sonra 1–2 saniyelik tohumlanmış karar aralığı; tam gelir zinciri; 500 brüt gelirden sonra ikinci tarla; 3.000 gelirden sonra Havva/makas; 6.000 gelirden sonra kamyon hızı ve boş işçi gelişim puanları.
- B_CONSERVATIVE: temel zincir; 30. dakikadan sonra ikinci tarla, başka geliştirme yok.
- C_AGGRESSIVE: temel zincirden hemen sonra dört tarla; yeterli bakiye oluşunca Havva/makas; 6.000 gelirde kamyon hızı/işçi puanları.
- D_POOR: öğretici sonrası güneyde 140 gereksiz yol girişimi; koruma 120 karodan sonra harcamayı durdurur. Erken Havva/motor/dekor girişimleri de denenir. Endüstri kurulumu 180. saniyeye ertelenir. Engellenen işlemler para harcamaz.
- E_MINIMUM: normal başlangıçla aynı alan sistemleri, yalnız 12.000 başlangıç sermayesi; bir tarla/Turhan/makas ve gelir binaları; genişleme yok. Bu, ücretsiz mevcut yol omurgasında kanıtlanan minimumdur. E_ROADS varyantı fabrika ve paketlemeyi daha uzağa kurar; kamyonun gerçekten kullandığı dört ek yol için100 Altın öder.
- F_TURHAN / F_HAVVA / F_BOTH: aynı dört tarla, aynı makas, aynı başlangıç seviye1 istatistikleri. Tek işçi karşılaştırmasında ilk öğretici seçimi değiştirilir; iki işçide Havva yasal satın alımla eklenir. XP doğal olarak çalışana gider; son seviyeler zorla eşitlenmez. Başlangıç dosyasındaki eski F_HAVVA, Turhan ile başlayıp Havva’ya geçmek zorundaydı; doğrudan eşit başlangıç karşılaştırması son dosyadadır.
- G_SHEARS / G_MOTOR: tek tarla, aynı başlangıç; motor yalnız gerçek işletme Seviye6 olduğunda ve işçi boşken normal fiyatıyla alınır. Öncesinde motor etkisi yoktur.
- H_STABILITY: tek tarlalı zincir 60 dakika müdahalesiz sürer.
- U_*: G_SHEARS ile aynı kontrol; 600. saniyeden sonra ilk geçerli boşlukta yalnız adındaki geliştirme bir kez yapılır. Seviye/kasa/meşguliyet denetimleri atlanmaz.

## Kontrol noktaları

Altın anlık bakiyedir. Gelir ve harcama kümülatiftir. Net nakit akışı = satış geliri − tüm kurulum/geliştirme giderleri; başlangıç sermayesi kazanç sayılmaz. Oyun ücret/yakıt vb. işletme gideri içermediğinden bu muhasebe anlamında net kâr değildir.

Senaryo | Dakika | Altın | Brüt satış | Harcama | Net nakit | Seviye / XP | Satılan paket
--- | --- | --- | --- | --- | --- | --- | ---
A_NORMAL | 5 | 3300 | 300 | 12000 | -11700 | 2 / 148 | 2
A_NORMAL | 15 | 9550 | 9300 | 14750 | -5450 | 5 / 63 | 62
A_NORMAL | 30 | 23050 | 22800 | 14750 | 8050 | 6 / 591 | 152
A_NORMAL | 60 | 50050 | 49800 | 14750 | 35050 | 9 / 156 | 332
B_CONSERVATIVE | 5 | 3300 | 300 | 12000 | -11700 | 2 / 148 | 2
B_CONSERVATIVE | 15 | 11100 | 8100 | 12000 | -3900 | 4 / 120 | 54
B_CONSERVATIVE | 30 | 22350 | 19350 | 12000 | 7350 | 5 / 340 | 129
B_CONSERVATIVE | 60 | 48600 | 46350 | 12750 | 33600 | 8 / 410 | 309
C_AGGRESSIVE | 5 | 1000 | 1500 | 15500 | -14000 | 3 / 201 | 10
C_AGGRESSIVE | 15 | 9250 | 10500 | 16250 | -5750 | 6 / 201 | 70
C_AGGRESSIVE | 30 | 22750 | 24000 | 16250 | 7750 | 8 / 281 | 160
C_AGGRESSIVE | 60 | 49750 | 51000 | 16250 | 34750 | 10 / 1193 | 340
D_POOR | 5 | 300 | 300 | 15000 | -14700 | 2 / 138 | 2
D_POOR | 15 | 8100 | 8100 | 15000 | -6900 | 4 / 110 | 54
D_POOR | 30 | 19350 | 19350 | 15000 | 4350 | 5 / 330 | 129
D_POOR | 60 | 42000 | 42000 | 15000 | 27000 | 7 / 357 | 280
E_MINIMUM | 5 | 300 | 300 | 12000 | -11700 | 2 / 148 | 2
E_MINIMUM | 15 | 8100 | 8100 | 12000 | -3900 | 4 / 120 | 54
E_MINIMUM | 30 | 19350 | 19350 | 12000 | 7350 | 5 / 340 | 129
E_MINIMUM | 60 | 42000 | 42000 | 12000 | 30000 | 7 / 367 | 280
E_ROADS | 5 | 3200 | 300 | 12100 | -11800 | 2 / 148 | 2
E_ROADS | 15 | 11000 | 8100 | 12100 | -4000 | 4 / 120 | 54
E_ROADS | 30 | 22250 | 19350 | 12100 | 7250 | 5 / 340 | 129
E_ROADS | 60 | 44900 | 42000 | 12100 | 29900 | 7 / 367 | 280
F_TURHAN | 5 | 2250 | 1500 | 14250 | -12750 | 3 / 171 | 10
F_TURHAN | 15 | 11250 | 10500 | 14250 | -3750 | 6 / 148 | 70
F_TURHAN | 30 | 24750 | 24000 | 14250 | 9750 | 8 / 128 | 160
F_TURHAN | 60 | 51750 | 51000 | 14250 | 36750 | 10 / 912 | 340
F_HAVVA | 5 | 2250 | 1500 | 14250 | -12750 | 3 / 171 | 10
F_HAVVA | 15 | 11250 | 10500 | 14250 | -3750 | 6 / 148 | 70
F_HAVVA | 30 | 24750 | 24000 | 14250 | 9750 | 8 / 128 | 160
F_HAVVA | 60 | 51750 | 51000 | 14250 | 36750 | 10 / 912 | 340
F_BOTH | 5 | 1000 | 1500 | 15500 | -14000 | 3 / 201 | 10
F_BOTH | 15 | 10000 | 10500 | 15500 | -5000 | 6 / 191 | 70
F_BOTH | 30 | 23500 | 24000 | 15500 | 8500 | 8 / 212 | 160
F_BOTH | 60 | 50500 | 51000 | 15500 | 35500 | 10 / 1029 | 340
G_SHEARS | 5 | 3300 | 300 | 12000 | -11700 | 2 / 148 | 2
G_SHEARS | 15 | 11100 | 8100 | 12000 | -3900 | 4 / 120 | 54
G_SHEARS | 30 | 22350 | 19350 | 12000 | 7350 | 5 / 340 | 129
G_SHEARS | 60 | 45000 | 42000 | 12000 | 30000 | 7 / 367 | 280
G_MOTOR | 5 | 3300 | 300 | 12000 | -11700 | 2 / 148 | 2
G_MOTOR | 15 | 11100 | 8100 | 12000 | -3900 | 4 / 120 | 54
G_MOTOR | 30 | 22350 | 19350 | 12000 | 7350 | 5 / 340 | 129
G_MOTOR | 60 | 43400 | 42900 | 14500 | 28400 | 7 / 412 | 286
H_STABILITY | 5 | 3300 | 300 | 12000 | -11700 | 2 / 148 | 2
H_STABILITY | 15 | 11100 | 8100 | 12000 | -3900 | 4 / 120 | 54
H_STABILITY | 30 | 22350 | 19350 | 12000 | 7350 | 5 / 340 | 129
H_STABILITY | 60 | 45000 | 42000 | 12000 | 30000 | 7 / 367 | 280

## İlk gelir ve seviye zamanları

500/1000 sütunları ilk kümülatif brüt satış eşiğidir, Altın bakiyesindeki net artış değildir. İkinci tarla eşiği tarla+ilk ekim750 Altın ve zorunlu bütçe koruması birlikte kontrol edilerek satın alma politikası karar anında kaydedilir. Tam yatırım dönüşü net nakit ilk kez pozitif olduğunda ölçülür; ileride yeni yatırım tekrar düşürebilir.

Senaryo | İlk satış | 500 gelir | 1000 gelir | İkinci tarla alınabilir | Yatırım dönüşü | Sv2 | Sv3 | Sv4 | Sv5 | Sv6
--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---
A_NORMAL | 4:41 | 5:11 | 5:41 | 1:16 | 21:01 | 1:11 | 5:00 | 8:37 | 13:33 | 21:08
B_CONSERVATIVE | 4:41 | 5:11 | 5:41 | 1:16 | 20:31 | 1:11 | 5:00 | 11:31 | 20:27 | 32:01
C_AGGRESSIVE | 3:21 | 3:51 | 4:21 | 1:16 | 21:21 | 1:11 | 3:21 | 5:23 | 8:31 | 13:01
D_POOR | 4:40 | 5:10 | 5:40 | 5:21 | 24:30 | 1:11 | 5:10 | 12:06 | 20:27 | 33:02
E_MINIMUM | 4:41 | 5:11 | 5:41 | 5:21 | 20:31 | 1:11 | 5:00 | 11:31 | 20:27 | 32:54
E_ROADS | 4:41 | 5:11 | 5:41 | 1:16 | 20:31 | 1:11 | 5:00 | 11:31 | 20:29 | 32:54
F_TURHAN | 3:21 | 3:51 | 4:21 | 1:16 | 19:11 | 1:11 | 3:21 | 5:34 | 8:55 | 13:38
F_HAVVA | 3:21 | 3:51 | 4:21 | 1:16 | 19:11 | 1:11 | 3:21 | 5:34 | 8:55 | 13:38
F_BOTH | 3:21 | 3:51 | 4:21 | 1:16 | 20:31 | 1:11 | 3:21 | 5:23 | 8:31 | 13:08
G_SHEARS | 4:41 | 5:11 | 5:41 | 1:16 | 20:31 | 1:11 | 5:00 | 11:31 | 20:27 | 32:54
G_MOTOR | 4:41 | 5:11 | 5:41 | 1:16 | 20:31 | 1:11 | 5:00 | 11:31 | 20:27 | 32:54
H_STABILITY | 4:41 | 5:11 | 5:41 | 1:16 | 20:31 | 1:11 | 5:00 | 11:31 | 20:27 | 32:54

## Önce / sonra

Senaryo | İlk satış eski → yeni | 60dk satış eski → yeni | 60dk Altın eski → yeni | Sv6 eski → yeni
--- | --- | --- | --- | ---
A_NORMAL | 2:31 → 4:41 | 345 → 332 | 52000 → 50050 | 12:22 → 21:08
B_CONSERVATIVE | 2:31 → 4:41 | 345 → 309 | 54000 → 48600 | 17:15 → 32:01
C_AGGRESSIVE | 2:31 → 3:21 | 345 → 340 | 50500 → 49750 | 12:00 → 13:01
D_POOR | 3:30 → 4:40 | 339 → 280 | 50850 → 42000 | 18:14 → 33:02
E_MINIMUM | 2:31 → 4:41 | 345 → 280 | 51750 → 42000 | 17:15 → 32:54
G_SHEARS | 2:31 → 4:41 | 345 → 280 | 54750 → 45000 | 17:15 → 32:54
G_MOTOR | 2:31 → 4:41 | 345 → 286 | 52250 → 43400 | 17:15 → 32:54
H_STABILITY | 2:31 → 4:41 | 345 → 280 | 54750 → 45000 | 17:15 → 32:54

## Kapasite, darboğaz ve kullanım

Fabrika teorik600 kg yaş/dakika →120 kg kuru/dakika (100→20 kg /10 saniye); paketleme teorik150 paket/dakika (20 paket /8 saniye). Müşteri talebi en çok6 paket/dakika =900 Altın/dakika; yol ve stok varsa. Bunlar nominal makine kapasiteleri, gerçekleşen satış değildir. Kamyon için hız ve rota ayrıca etkilidir; kapasite artışı her seferde25 kg taşıyan bir işte kendiliğinden fayda sağlamaz.

Son30 dakikanın ölçülen hızları:

Senaryo | Yaş hasat kg/dk | Satış paket/dk | Brüt Altın/dk | Kamyon kullanım % (tüm süre) | Fabrika % | Paketleme % | Reyon boş % | 60dk ürün bekliyor (kuru kg / paket) | Darboğaz
--- | --- | --- | --- | --- | --- | --- | --- | --- | ---
A_NORMAL | 50.0 | 6.0 | 900.0 | 53.2 | 7.9 | 5.0 | 5.7 | 120 / 98 | Müşteri talebi
B_CONSERVATIVE | 50.0 | 6.0 | 900.0 | 42.8 | 6.2 | 4.5 | 12.9 | 40 / 81 | Müşteri talebi
C_AGGRESSIVE | 90.8 | 6.0 | 900.0 | 98.9 | 14.7 | 5.0 | 3.6 | 600 / 90 | Müşteri talebi
D_POOR | 25.0 | 5.0 | 755.0 | 28.4 | 4.4 | 3.5 | 20.2 | 0 / 0 | Tarla büyümesi / hammadde
E_MINIMUM | 25.0 | 5.0 | 755.0 | 28.5 | 4.3 | 3.4 | 22.5 | 0 / 0 | Tarla büyümesi / hammadde
E_ROADS | 25.0 | 5.0 | 755.0 | 32.6 | 4.3 | 3.3 | 22.7 | 0 / 0 | Tarla büyümesi / hammadde
F_TURHAN | 85.8 | 6.0 | 900.0 | 98.9 | 13.9 | 5.0 | 3.6 | 540 / 90 | Müşteri talebi
F_HAVVA | 85.8 | 6.0 | 900.0 | 98.9 | 13.9 | 5.0 | 3.6 | 540 / 90 | Müşteri talebi
F_BOTH | 86.7 | 6.0 | 900.0 | 98.9 | 14.2 | 5.0 | 3.6 | 560 / 90 | Müşteri talebi
G_SHEARS | 25.0 | 5.0 | 755.0 | 28.5 | 4.3 | 3.4 | 22.5 | 0 / 0 | Tarla büyümesi / hammadde
G_MOTOR | 25.8 | 5.2 | 785.0 | 29.0 | 4.3 | 3.4 | 20.9 | 0 / 4 | Tarla büyümesi / hammadde
H_STABILITY | 25.0 | 5.0 | 755.0 | 28.5 | 4.3 | 3.4 | 22.5 | 0 / 0 | Tarla büyümesi / hammadde

İlk darboğaz tek tarlada hammadde/büyümedir. İki/dört tarla sonrası satış talebi sınırı devreye girer. Kamyon daha yoğun çalışır; işçi ve fabrika ek boş kapasite taşır. Bir sonraki makineyi hızlandırmanın final gelir sağlamadığı durum raporda açıkça sıfır yazılmıştır.

## İşçi karşılaştırması ve XP

Senaryo | Dakika | İşçi | Seviye / XP / sonraki | Hasat sayısı | Kullanım % | Ekipman | Hasat sn | Boş gelişim puanı
--- | --- | --- | --- | --- | --- | --- | --- | ---
A_NORMAL | 15 | turhan | 3 / 10 / 175 | 16 | 8.8 | teaShears | 4.545 | 0
A_NORMAL | 15 | havva | 2 / 30 / 100 | 8 | 9.7 | teaShears | 4.762 | 0
A_NORMAL | 30 | turhan | 3 / 170 / 175 | 32 | 8.4 | teaShears | 4.545 | 0
A_NORMAL | 30 | havva | 3 / 80 / 175 | 23 | 8.4 | teaShears | 4.545 | 0
A_NORMAL | 60 | turhan | 5 / 20 / 400 | 62 | 7.9 | teaShears | 4.167 | 0
A_NORMAL | 60 | havva | 4 / 205 / 275 | 53 | 7.8 | teaShears | 4.348 | 0
F_TURHAN | 15 | turhan | 4 / 145 / 275 | 47 | 36.5 | teaShears | 4.717 | 3
F_TURHAN | 30 | turhan | 5 / 370 / 400 | 97 | 37.6 | teaShears | 4.630 | 4
F_TURHAN | 60 | turhan | 7 / 475 / 650 | 200 | 37.9 | teaShears | 4.464 | 6
F_HAVVA | 15 | havva | 4 / 145 / 275 | 47 | 36.5 | teaShears | 4.717 | 3
F_HAVVA | 30 | havva | 5 / 370 / 400 | 97 | 37.6 | teaShears | 4.630 | 4
F_HAVVA | 60 | havva | 7 / 475 / 650 | 200 | 37.9 | teaShears | 4.464 | 6
F_BOTH | 15 | turhan | 3 / 130 / 175 | 28 | 23.3 | teaShears | 4.808 | 2
F_BOTH | 15 | havva | 3 / 50 / 175 | 20 | 16.3 | teaShears | 4.808 | 2
F_BOTH | 30 | turhan | 4 / 215 / 275 | 54 | 22.9 | teaShears | 4.717 | 3
F_BOTH | 30 | havva | 4 / 135 / 275 | 46 | 15.7 | teaShears | 4.717 | 3
F_BOTH | 60 | turhan | 6 / 60 / 525 | 106 | 22.7 | teaShears | 4.545 | 5
F_BOTH | 60 | havva | 5 / 380 / 400 | 98 | 15.3 | teaShears | 4.630 | 4
G_SHEARS | 15 | turhan | 3 / 0 / 175 | 15 | 8.2 | teaShears | 4.808 | 2
G_SHEARS | 30 | turhan | 3 / 150 / 175 | 30 | 8.1 | teaShears | 4.808 | 2
G_SHEARS | 60 | turhan | 5 / 0 / 400 | 60 | 8.0 | teaShears | 4.630 | 4
G_MOTOR | 15 | turhan | 3 / 0 / 175 | 15 | 8.2 | teaShears | 4.808 | 2
G_MOTOR | 30 | turhan | 3 / 150 / 175 | 30 | 8.1 | teaShears | 4.808 | 2
G_MOTOR | 60 | turhan | 5 / 10 / 400 | 61 | 6.3 | teaHarvesterMotor | 2.315 | 4

Turhan ve Havva tek işçi testlerinde aynı ekipmanla aynı başlangıç istatistiklerine sahiptir; farklı verim bonusu yoktur. Çift işçi örneğinde yalnız gerçek hasadı bitiren XP alır. Motor ilk gerçek Seviye6 anından önce satın alınmaz. F ve G için5 dakikada motor karşılaştırması uygulanabilir değildir: motor henüz kilitlidir; kontrol noktası yine kaydedilir ve ekipman makas olarak görünür.

## Geliştirme marjinal getirisi

Kontrol G_SHEARS. Tüm geliştirmeler mevcut alan servisiyle satın alındı; sıfır Altınlı işçi puanı da gerçek kazanılmış puandır. Altın/dk farkı30–60 dakika penceresindendir. Parti/müşteri zamanlaması yüzünden küçük farklar uzun dönem garantisi değildir. Tahmini geri ödeme = maliyet / pozitif marjinal hız; gözlenen60 dakikada geri ödenmiş olduğu anlamına gelmez.

Geliştirme | Uygulama zamanı | Maliyet | Hasat kg/dk | Altın/dk | Ek Altın/dk | Tahmini geri ödeme | 60dk ek brüt gelir
--- | --- | --- | --- | --- | --- | --- | ---
G_MOTOR | 32:55 | 2500 | 25.8 | 785.0 | 30.0 | 83.3 dk (tahmin) | 900
U_growth | 10:08 | 300 | 28.3 | 855.0 | 100.0 | 3.0 dk (tahmin) | 4650
U_collectionCapacity | 10:16 | 500 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 0
U_truckCapacity | 11:32 | 750 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 0
U_truckSpeed | 11:32 | 750 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 150
U_factorySpeed | 10:00 | 1000 | 25.0 | 750.0 | -5.0 | bu pencerede yok | 0
U_packagingSpeed | 10:00 | 600 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 0
U_shelfCapacity | 10:00 | 400 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 0
U_workerHarvest | 10:00 | 0 | 25.0 | 750.0 | -5.0 | bu pencerede yok | 0
U_workerMovement | 10:00 | 0 | 25.0 | 755.0 | 0.0 | bu pencerede yok | 0

Büyüme geliştirmesi tek tarlada anlamlıdır. Talep sınırına ulaşmış çok tarlalı işletmede aynı getiriyi vaat etmez. Motor iş süresini azaltır fakat tek tarlada büyüme baskın olduğu için yüksek fiyatının dönüşü yavaştır. Depo yeni üretim/satış etkisi taşımadığından ROI hesabına yeni bir davranış eklenmedi.

## Kilitler, öğretici ve hedefler

İkinci tarla için ayrıca B_CONSERVATIVE ile tek-tarla kontrolünün30–60 dakika penceresi karşılaştırılabilir: ikinci tarla+ekim750 Altın, ek brüt gelir4.350 Altın, ölçülen ortalama ek145 Altın/dakika; yaklaşık5,2 dakika basit geri ödeme tahmini. Bu değer yerleşim/müşteri erişimi aynı olduğunda geçerlidir; talep sınırına ulaşıldıktan sonraki üçüncü/dördüncü tarlalara genellenmez.

Seviye2: fabrika/paketleme/dükkân/Havva; Seviye3: depo/işçi gelişimi; Seviye4: kamyon geliştirmeleri; Seviye6: motor. Gelir öncesi XP hasat/teslimat/gerçek öğretici adımlarından kazanılır; retail→XP→retail döngüsel kilidi yoktur. Havva yalnız ilk öğretici işçi seçiminde bir defalık başlangıç alternatifi olarak alınabilir; sonraki satın alma normal Seviye2 kapısını kullanır. UI ve domain aynı işe alım kısıtını okur. Bu istisna “Turhan veya Havva” öğretici talebini, sonraki Havva kilidini kaldırmadan karşılar.

İlk gerçek teslimat öğreticiyi bitirir. Hedefler artık fabrika → paketleme → dükkân → ilk satış → ikinci tarla → işçi gelişimi → Seviye6/motor sırasındadır. İşçi gelişimi Seviye3 olmadan önerilmez; hedefler satın alma zorunluluğu veya para ödülü değildir. Hareket/seçim/panel açma XP vermez. İlk Havva seçimi ikinci işçi ödülünü yanlışlıkla tetiklemez.

## Muhasebe ve uzun koşu

Her bir saniyelik doğrulamada:

- Toplam hasat kg = tarlalar + kamyon + merkez + fabrika ham/işlem girdisi + tamamlanan fabrika partisi×100.
- Fabrika partisi×20 = fabrika kuru + paketleme girdisi + paket stok×1 + reyon×1 + satılan paket×1.
- Altın = başlangıç + müşteri geliri − gider; gelir = satılan paket×150. Altın ödülü0.
- Aktif tarla başına en çok bir hasat/taşıma işi; kapasite sınırları; negatif stok yok.
- Her işçinin ödüllü iş kimliği sayısı kendi tamamladığı hasat sayısına eşit.
- En çok5 aktif müşteri; aynı müşteri işlemi tekrarında ikinci stok/Altın/XP yok.
- Erişilebilir aktif iş300 saniyeden uzun beklerse koşu hata verir. Rafın bir üretim partisini beklerken boş kalması bu sınıfa sokulmaz.

Senaryo | Müşteri doğdu / ulaştı / aldı / kayıp | En çok aktif | En yaşlı aktif iş sn | Değişmez kontrolü
--- | --- | --- | --- | ---
A_NORMAL | 352 / 352 / 332 / 19 | 2 | 16.7 | 3600
B_CONSERVATIVE | 352 / 352 / 309 / 42 | 2 | 14.4 | 3600
C_AGGRESSIVE | 352 / 352 / 340 / 11 | 2 | 26.0 | 3600
D_POOR | 341 / 341 / 280 / 60 | 2 | 15.8 | 3600
E_MINIMUM | 352 / 352 / 280 / 71 | 2 | 9.2 | 3600
E_ROADS | 352 / 352 / 280 / 71 | 2 | 9.8 | 3600
F_TURHAN | 352 / 352 / 340 / 11 | 2 | 26.0 | 3600
F_HAVVA | 352 / 352 / 340 / 11 | 2 | 26.0 | 3600
F_BOTH | 352 / 352 / 340 / 11 | 2 | 26.0 | 3600
G_SHEARS | 352 / 352 / 280 / 71 | 2 | 9.2 | 3600
G_MOTOR | 352 / 352 / 286 / 65 | 2 | 9.2 | 3600
H_STABILITY | 352 / 352 / 280 / 71 | 2 | 9.2 | 3600

## Doğrulama durumu

Son doğrulama bilgisi M10_1_CHANGELOG.md içinde yer alır. Derleme veya cihaz testi yapılmadıysa başarılı olarak gösterilmez. Chrome kayıtları m10_1-browser-observation.json ve m10_1_*.png dosyalarıdır. APK yolu build/app/outputs/flutter-apk/app-debug.apk.

## Sınırlar ve sonraki öncelikler

Bu 21 politika olası tüm oyuncu davranışlarını tüketmez. 60 dakika bir denge penceresidir, sonsuz koşu kanıtı değildir. Parti sınırından kaynaklanan küçük ROI farkları için daha uzun gözlem gerekir. Dünya yolu kısa ve başlangıç omurgasına bağlıdır; farklı yerleşimler ilk satışı ve kamyon kullanımını değiştirir. Henüz işletme gideri yoktur. İç endüstriyel aktarım korunur; yeni araç eklenmedi. İş geçmişi/ödül kimliği listeleri uzun oturumda büyür; müşteri aktif sayısı sınırlı olsa da gelecekte kayıt politikası ayrıca ele alınmalıdır. M11, yeni içerik veya animasyon başlanmadı.
