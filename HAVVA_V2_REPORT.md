# Havva V2 — Sekiz kareli görsel entegrasyon

## Kaynak ve doğrulama

Kaynak, kullanıcının verdiği açılmış klasördür:
`C:/Users/Mehmet Demircioglu/Downloads/CAY_SIMULASYON/HAVVA_V2_8_FRAMES_NAMED/havva`.
ZIP varsayılmadı; gerçek dosyalar incelendi. Sekiz PNG ve üst klasörde WALK_B eksiklerini belirten `MISSING_FRAMES.txt` bulundu. Beklenmeyen PNG yok.

**Kabul: 8/8. Ret: 0.** Her PNG 1254×1254, RGBA; 1,27–1,32 milyon tam saydam piksel içeriyor. Dış kenarlarda görünür piksel yok. Otomatik test geniş dış şeritlerde alfa=0 kontrolü yapıyor. Sekiz görsel ayrıca gözle incelendi: başörtüsü, eller, botlar, sepet ve yapraklar korunmuş; görünür dama/kremsi dikdörtgen veya önemli silinmiş bölge saptanmadı. Alfa sayıları ve SHA-256 özetleri `dev_assets/havva_v2/alpha_audit.json` içindedir. Runtime kopyalarının sekizinde de kaynakla SHA-256 eşitliği doğrulandı.

## Dosyalar ve merkezi normalizasyon

Runtime: `assets/images/characters/havva/idle/` ve `walk/`.
Yalnız bu iki klasör pubspec'e eklendi; denetim dosyaları runtime'a dahil edilmedi.

| Dosya | Baş üstü Y | Zemin X | Zemin Y |
|---|---:|---:|---:|
| HAVVA_IDLE_SE.png |38|640|1200|
| HAVVA_WALK_SE_A.png |47|660|1188|
| HAVVA_IDLE_SW.png |53|640|1188|
| HAVVA_WALK_SW_A.png |55|620|1180|
| HAVVA_IDLE_NE.png |45|620|1178|
| HAVVA_WALK_NE_A.png |46|650|1178|
| HAVVA_IDLE_NW.png |41|620|1193|
| HAVVA_WALK_NW_A.png |42|610|1188|

Değerler kaynak piksel koordinatlarıdır; `havva_visual.dart` içinde tutulur. Ölçek =95/(zeminY−başÜstüY). Çizim ötelemesi X=31−zeminX×ölçek, Y=95−zeminY×ölçek. Ek bob/rotasyon, yatay aynalama veya kareye özel başka gizli düzeltme yok. Kaynak PNG kırpılmadı/yeniden örneklenmedi. Mevcut sabit62×95 render/seçim kutusu korunur; çizim bu kutu içinde yapılır. Havva ve Turhan aynı95 mantıksal piksel karakter yüksekliğini kullanır. Başörtüsü ile şapka arasındaki doğal siluet farkı korunur.

## Ortak animasyon

Turhan'ın mevcut konum farkı/yön/durum/zaman mantığı `worker_visual.dart` içine alınarak kare haritası ve döngü parametreleri eklendi. Ayrı Havva animasyon motoru yok. Eski `TurhanVisual` giriş noktası ve frame typedef'i uyum için korundu. Turhan'ın12 dosyası, metadata değerleri ve A→IDLE→B→IDLE davranışı değiştirilmedi.

Havva: **A→IDLE→A→IDLE**, **140 ms/kare**. WALK_B dosyası aranmaz, üretilmez veya taklit edilmez. Durunca son yöndeki IDLE seçilir. A* köşelerinde gerçek hareket vektörü yeni yönü belirler.

Mevcut izometrik izdüşüm:

| Mantıksal hareket | Görsel yön |
|---|---|
| +X | SE |
| +Y | SW |
| −Y | NE |
| −X | NW |

Yön, tıklama konumundan gelmez. Derinlik ve hitbox sprite boyutlarından bağımsızdır. Worker, JobSystem, ekipman, ekonomi, XP, kilit ve öğretici alan kodları değiştirilmedi. `cay_game.dart` yalnız Havva karelerini ön yükler. Havva'nın gerçek kareleri üzerine prosedürel salınım eklenmedi.

## Chrome gözlemleri

`http://127.0.0.1:7361/?visualTest=havva` aynı geliştirme sahnesinin Havva parametresidir. SE→NE→NW→SW rotası, duruşlar ve seçim mevcut altyapıyı kullanır. Normal oyun bu sahneyi oluşturmaz.

- Havva: dört yönde WALK_A, yürürken IDLE ve dururken IDLE gözlendi (12 durum). Yön değiştirme, seçme ve yönlü görselleri kapatıp açma doğrulandı.
- Turhan: aynı Chrome koşusunda dört yönde A/IDLE/B yürüyüşü ve son yön duruşu gözlendi (16 durum).
- Karelerde beyaz/dama kutusu görünmedi. Oyun ölçeğinde belirgin yeniden boyutlanma veya baş/sepet sıçraması saptanmadı. Tek adım pozu nedeniyle yürüyüş, Turhan'ın iki farklı adımına göre daha tekrarlayıcıdır.
- Test rotası1280×720,960×540,844×390 boyutlarında görüntülendi. Dar geliştirme sahnesinde sabit büyük test zoom'u aktörü üstteki test kontrollerine yaklaştırabilir; normal oyun arayüzü ayrı incelenir.
- Normal oyunda gerçek ilk teslimat sonrası Seviye2 Havva işe alımı ve makas takılması doğrulandı. İlk otomasyon denemesinin seçim hedefi değiştiği için yürüyüş bekleme kontrolü geçerli kanıt sayılmadı. Ayrı headless Chrome oturumunda mevcut ilk-işçi Havva seçimiyle tam gerçek akış tekrar çalıştırıldı: makas → ekim → otomatik fiziksel yürüyüş →25 kg hasat → Havva10/50 XP → otomatik kamyon teslimatı →Seviye2. Hasat Altın vermedi (13.000 sabit); merkezin2.500 bedeli sonrası10.500 korundu. Normal dünya/Envanter/İşletme üç yatay boyutta incelendi. JS istisnası yok. Bu kontrol simülasyon enjeksiyonu değil, gerçek Flutter uygulamasındaki dokunmatik eylemlerdir.

## Otomatik doğrulama

**338/338 test başarılı**: önceki329 test ve9 yeni Havva testi. Eski “Havva yönlü kare kullanmaz” beklentisi yeni gereksinime göre güncellendi; test silinmedi. Yeni kapsam:8 PNG decode/alfa/normalizasyon, dört yön, A/IDLE tekrarı ve eksik B, son yön, köşe değişimi, mantıksal konum/derinlik/seçim değişmezliği, bina ön/arka sıralaması, gerçek Havva hasat/XP/ekonomi eşdeğerliği. M10.1 deterministik ekonomi ve60 dakika kararlılık regresyonları geçti.

- flutter analyze: temiz.
- flutter test:338/338.
- flutter build web: başarılı.
- flutter build apk --debug: başarılı; APK içinde8 Havva PNG'si doğrulandı.
- ADB listesi boş: fiziksel Android/emülatör testi yapılmadı.
- Normal Chrome son sonucu: başarılı; `dev_assets/havva_v2/normal_observation.json` ve normal_*.png kanıtları.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`; mobil kopya `C:/Users/Mehmet Demircioglu/Downloads/cay-simulasyonu-havva-v2-debug.apk`.
- Tekrar çalıştırma: web sunucusu7361 ve Chrome CDP7364 açıkken `node --experimental-websocket test/browser_havva_visual.mjs`, ardından `node --experimental-websocket test/browser_havva_normal.mjs`.

## Değişen kaynaklar

Yeni: `worker_visual.dart`, `havva_visual.dart`, `test/havva_visual_test.dart`, Chrome doğrulama betikleri ve8 runtime PNG.
Güncellenen: `turhan_visual.dart` (uyumlu ortak sınıf), `worker_component.dart`, `cay_game.dart` (yükleme), `turhan_test_scene.dart` (karakter parametresi), `main.dart` (görsel test URL'si), `pubspec.yaml`, `test/turhan_visual_test.dart` (Havva etkinlik beklentisi).

## Sınırlar

WALK_B yok; dönüşümlü iki farklı ayak basışı gösterilemez. Gerçek piksel deformasyonu/ayna veya yapay B yapılmadı. Tek parça bina sprite'larının mevcut kısmi örtüşme sınırları korunur; mantıksal ön/arka derinlik doğrulaması geçti. Cihaz performansı bu Chrome gözlemleriyle kanıtlanmış sayılmaz.

HAVVA ASSETS ACTIVE: YES

HAVVA WALK_B FRAMES AVAILABLE: NO

HAVVA GAMEPLAY CHANGED: NO

TURHAN ANIMATION CHANGED: NO

M10.1 ECONOMY CHANGED: NO

Hasat/müşteri animasyonu ve M11 başlatılmadı.
