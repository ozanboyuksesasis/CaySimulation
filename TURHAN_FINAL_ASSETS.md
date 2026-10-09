# Turhan final şeffaf kareler — 5 Ekim 2026

Bu rapor, `TURHAN_VISUAL_TEST.md` içindeki eski RGB/dama arka planı ve yanlış SE_B bulgularının yerini alır. Animasyon mimarisi yeniden yazılmadı.

## Sonuç

- FINAL TURHAN FILE COUNT: **12 / 12**
- TRUE ALPHA: **YES**
- BAKED CHECKERBOARD REMAINS: **NO** — görünen karelerde yok.
- DAMAGED BACKGROUND-REMOVAL FILES: **NONE** — incelemede belirgin hasar saptanmadı.
- SE_B DIRECTION: **SE**, sağ alt; eski yanlış yönlü kare değiştirildi.
- NE WALK: **acceptable**; A/B pozları benzer, oyun ölçeğinde kullanılabilir.
- SW WALK: **acceptable**; A/B farkı sınırlı, bozuk yön/arka plan görülmedi.
- ALL FOUR DIRECTIONS: **good**, aşağıdaki sınırlamalarla.
- FINAL TRANSPARENT DIRECTIONAL TURHAN ACTIVE: **YES**

## Kaynak ve dosyalar

Kaynak: `C:\Users\Mehmet Demircioglu\Downloads\CAY_SIMULASYON\turhan.zip` ve aynı yerdeki `turhan/` klasörü. Arşivde bir klasör girdisi ve tam 12 PNG var; eksik veya beklenmeyen görsel yok. Gerçek dosya adları alt çizgi değil **boşluk** kullanıyor; adlar korundu.

Çalışma kökü: `assets/images/characters/turhan/`.

| Dosya | Alt klasör | Alfa >128 görünür sınır (sol,üst,sağ,alt) |
|---|---|---|
| TURHAN IDLE SE.png | idle | 301,144,718,1303 |
| TURHAN WALK SE A.png | walk | 300,147,786,1283 |
| TURHAN WALK SE B.png | walk | 306,143,785,1288 |
| TURHAN IDLE SW.png | idle | 336,141,726,1316 |
| TURHAN WALK SW A.png | walk | 310,171,733,1285 |
| TURHAN WALK SW B.png | walk | 301,146,759,1287 |
| TURHAN IDLE NE.png | idle | 269,104,723,1294 |
| TURHAN WALK NE A.png | walk | 264,71,803,1291 |
| TURHAN WALK NE B.png | walk | 273,101,776,1306 |
| TURHAN IDLE NW.png | idle | 321,160,752,1289 |
| TURHAN WALK NW A.png | walk | 207,152,726,1318 |
| TURHAN WALK NW B.png | walk | 251,169,745,1286 |

Tüm dosyalar okunabilir 32-bit RGBA PNG. Her birinde tamamen saydam, kısmen saydam ve tamamen opak pikseller mevcut. Her dosyanın dört dış kenarındaki görünür piksel sayısı **0**. Her karede 1,27–1,32 milyon tamamen saydam piksel var. PNG başlığına ek olarak gerçek çözümlenmiş alfa değerleri test edildi.

Yeşil zemindeki 12 karelik incelemede şapka, krem gömlek/kollar, eller, botlar, sakal, sepet/bitkiler, askılar ve kemer çantasında belirgin silinme veya görünür dama/halo kutusu saptanmadı. Bu görsel değerlendirme, kusursuz sanatsal bütünlük garantisi değildir. Tamamen saydam piksellerin görünmeyen RGB değerleri görsel arka plan olarak değerlendirilmez.

Çalışma dosyaları ve üretilen APK içindeki **12/12 PNG**, verilen klasördeki kaynakların SHA-256 özetiyle birebir eşleşiyor. Kaynak pikseller değiştirilmedi. Eski kareler `dev_assets/turhan_final/previous_test/` altında; runtime bildirimlerine dahil değil. Runtime Turhan klasöründe tam 12 PNG var; pubspec yolları değişmedi.

## Normalizasyon

Ortak 62×95 mantıksal görsel kutu ve ayak noktası korundu. Ölçek `95 / (feetY - bodyTop)`; çizim başlangıcı `(31 - feetX × scale, 95 - feetY × scale)`. Kaynak tuval boyutu seçim veya derinlik hesabını etkilemiyor.

Yalnızca **SE_B** merkezi metadata değişti:

| Değer | Eski | Final |
|---|---:|---:|
| bodyTop | 194 | 143 |
| feetX | 520 | 570 |
| feetY | 1249 | 1289 |
| 95 birim yükseklikte ölçek | 0,0900474 | 0,0828970 |

Final çizim başlangıcı yaklaşık `(-16,2513; -11,8543)`; ayrı ek offset yok. Diğer 11 karenin mevcut metadata değerleri yeni alfa sınırlarıyla uyumluydu, korundu. Şapka–bot yüksekliği 95 birime eşitlendi; SE_B kaynak kadraj farkının boy sıçraması yaratması önlendi. Pozlara özgü kol/sepet/siluet farkları korunuyor.

Yön eşlemesi aynı: `+gridX → SE`, `+gridY → SW`, `-gridY → NE`, `-gridX → NW`. Gerçek hareket vektörü kullanılıyor. Döngü **A → IDLE → B → IDLE**, **140 ms/kare**. Durunca son yöndeki IDLE; köşede anlık yön değişimi. Turhan yönlü yürüyüşüne prosedürel bob/sway/rotation eklenmedi. Havva sunumu değişmedi.

## Değişen dosyalar

- `assets/images/characters/turhan/idle/` ve `walk/`: 12 PNG değişimi.
- `lib/features/workers/turhan_visual.dart`: yalnız SE_B metadata.
- `lib/game/turhan_test_scene.dart`: eski alfa-yok uyarısı yerine doğru final kare bilgisi.
- `test/turhan_visual_test.dart`: eski RGB beklentisi yerine 12 gerçek PNG decode, alfa, saydam dış kenar ve opak nesne pikseli doğrulaması.
- Bu rapor; eski karelerin geliştirme yedeği. Gameplay dosyalarına değişiklik yok.

## Doğrulama

- `flutter analyze`: **No issues found**.
- Tüm testler: **248/248 geçti** (`turhan-final-tests.log`). Mevcut yön, döngü, son yön, köşe, mantıksal konum, derinlik, seçim kutusu, Havva ve animasyonsuz gerçek hasat testleri korundu.
- `flutter build web`: **başarılı**.
- `flutter build apk --debug`: **başarılı**.
- Chrome `?visualTest=turhan`: dört yönde yürüyüş A/IDLE/B ve duruş IDLE olmak üzere **16 durum** gözlendi. Seçim ve yönlü kareleri kapat/aç kontrolü geçti. Kare ekran görüntüleri yeşil zeminde incelendi; beyaz/gri/dama dikdörtgen yok.
- Chrome normal yeni oyun: tarla kur → Turhan işe al → makas satın al/kuşan → çay dik → büyüme → hasat emri → gerçek yürüyüş → **25 kg tarla stoğu**. Altın **8.000**, hasat ek gelir yaratmadı. Tutorial gerçek hasat sonucuna ilerledi.
- Tarayıcı akışı dokunmatik olaylarla çalıştırıldı. `turhan-browser-observation.json`: seçim true, toggle true, 25 kg, 8.000 Altın, JS exception listesi boş.
- Görsel kanıtlar: `turhan_SE_walk_B.png`, `turhan_NE_walk_B.png`, `turhan_NW_walk_B.png`, `turhan_SW_walk_B.png`, `turhan_selection.png`, `turhan_normal_harvest_walk.png`, `turhan_normal_harvest_done.png` ve diğer rota kareleri.

APK: `build/app/outputs/flutter-apk/app-debug.apk`; kullanıcı kopyası `C:\Users\Mehmet Demircioglu\Downloads\cay-simulasyonu-turhan-final-debug.apk`.

## Sınırlamalar

- Fiziksel Android cihaz testi yapılmadı: ADB yalnız `emulator-5554 offline` gösteriyor. iOS cihaz testi yapılmadı.
- Görsel değerlendirme Chrome rota örnekleri/ekran görüntüleriyle yapıldı; piksel mükemmelliği veya sürekli insan video gözlemi iddiası yok. NE/SW çiftlerinin benzerliği nedeniyle adım çeşitliliği sınırlı; sırf bu nedenle kare reddedilmedi.
- Derlemede mevcut CupertinoIcons font ve Java native-access uyarıları var; derlemeyi engellemiyor.

**TURHAN GAMEPLAY CHANGED: NO**  
**TURHAN ARTWORK MODIFIED: NO**  
**HAVVA CHANGED: NO**  
**HARVEST SPRITE ANIMATION ADDED: NO**
