# Turhan — dört yönlü PNG yürüyüş testi

## Sonuç

- TURHAN GAMEPLAY CHANGED: **NO**
- TURHAN ARTWORK MODIFIED: **NO**
- HAVVA CHANGED: **NO**
- REAL DIRECTIONAL SPRITES ACTIVE: **YES**

Bu bir görsel denemedir. Animasyon kodu çalışıyor; sağlanan paket görsel açıdan henüz yayın kalitesinde değildir. Özellikle alfa kanalı ve SE-B yön hatası çizim ölçeğiyle çözülemez.

## Arşiv ve gerçek dosyalar

Kaynak: `C:\Users\Mehmet Demircioglu\Downloads\CAY_SIMULASYON\turhan.zip`.
Arşivde bir klasör ve beklenen 12 PNG bulundu. Eksik veya beklenmeyen PNG yok. Gerçek adlar alt çizgi değil **boşluk** içeriyor; adlar korunmuştur.

Çalışma zamanı kökü: `assets/images/characters/turhan/`.

| Alt klasör | Gerçek dosya adı | Kaynak boyutu | Şapka üstü Y | Ayak X | Ayak Y |
|---|---|---|---:|---:|---:|
| idle | TURHAN IDLE SE.png | 1088×1445 | 143 | 570 | 1304 |
| idle | TURHAN IDLE SW.png | 1088×1445 | 140 | 510 | 1317 |
| idle | TURHAN IDLE NE.png | 1089×1445 | 104 | 560 | 1295 |
| idle | TURHAN IDLE NW.png | 1088×1445 | 159 | 480 | 1290 |
| walk | TURHAN WALK SE A.png | 1088×1445 | 146 | 560 | 1284 |
| walk | TURHAN WALK SE B.png | 1089×1445 | 194 | 520 | 1249 |
| walk | TURHAN WALK SW A.png | 1088×1445 | 170 | 500 | 1286 |
| walk | TURHAN WALK SW B.png | 1088×1445 | 145 | 520 | 1288 |
| walk | TURHAN WALK NE A.png | 1089×1445 | 70 | 534 | 1292 |
| walk | TURHAN WALK NE B.png | 1089×1444 | 100 | 560 | 1307 |
| walk | TURHAN WALK NW A.png | 1089×1445 | 151 | 464 | 1319 |
| walk | TURHAN WALK NW B.png | 1088×1445 | 168 | 500 | 1286 |

Dosyalar okunuyor ve Flutter/Chrome tarafından çözümleniyor. Arşiv girişleri ile çalışma zamanı kopyalarının **12/12 SHA-256 özeti aynı**. PNG yeniden kaydetme, yeniden örnekleme, aynalama, kalıcı kırpma veya arka plan temizliği yapılmadı. ZIP ve Downloads içindeki kaynaklar korunuyor.

## Kritik görsel bulgular

1. **Yukarıdaki 12 dosyanın tamamı alfa içermeyen RGB PNG (PNG renk türü 2 / 24 bit).** Dış köşe alfa değeri 255. Beyaz/gri dama deseni gerçek şeffaflık değil, resme işlenmiş piksellerdir. Oyunda dikdörtgen olarak görünür. Normalizasyon bunu gidermedi. Gerçek alfa içeren sürümler sağlanmalı.
2. **`TURHAN WALK SE B.png`:** karakter diğer SE karelerinin tersine SW tarafına bakıyor. Döngüde yüz ve sepet tarafı aniden değişiyor; ters yöne bakarak kayma hissi yaratıyor. Yön/kimlik sürekliliği için bu kare yeniden sağlanmalı. Çevirme veya başka kareyle gizli değiştirme yapılmadı.
3. **`TURHAN WALK NE A.png` / `TURHAN WALK NE B.png`** ve **`TURHAN WALK SW A.png` / `TURHAN WALK SW B.png`:** adım pozları birbirine yakın; tam karşılıklı iki adım kadar belirgin değiller. Özellikle B kareleri, zıt bacak fazı bakımından gözden geçirilmeli. Döngü çalışsa da tekrar eden tek adım hissi kalabilir.
4. Sepet, omuz, şapka ve gövde oranları kaynak kareler arasında değişiyor. Ortak boy/zemin hizası büyük tuval sıçramalarını sınırlar; çizilmiş perspektif ve poz farklarını ortadan kaldırmaz.

Test amacıyla tüm 12 kare aktif bırakıldı. Hiçbir sorunlu kare sessizce atlanmadı veya başka sanatla değiştirilmedi.

## Yön ve zamanlama

Hareket, işçinin gerçek sürekli mantıksal konumunun önceki konuma farkından okunur. Bu fark mevcut `IsometricGrid.toWorld` dönüşümünden geçirilir; yön dokunma konumundan gelmez.

| Mantıksal hareket | İzometrik ekran hareketi | Yön |
|---|---|---|
| +gridX | sağ/aşağı | SE |
| +gridY | sol/aşağı | SW |
| −gridY | sağ/yukarı | NE |
| −gridX | sol/yukarı | NW |

İlk yön SE. Hareket yokken son yön korunur ve o yönün IDLE karesi çizilir. Köşede yön anında değişir; sürekli görsel rotasyon yoktur. Yürüyüş sırası **A → IDLE → B → IDLE**. Kare süresi **140 ms**, yaklaşık **7,14 kare/saniye**, döngü **560 ms**. Zamanlama hareket hızına bağlı değildir.

## Ankraj ve ölçek

Merkezi tanımlar `lib/features/workers/turhan_visual.dart` içindedir. Her kare için yukarıdaki kaynak piksel işaretleri kullanılır:

```text
scale = visualHeight / (feetY - bodyTop)
offsetX = visualWidth / 2 - feetX * scale
offsetY = visualHeight - feetY * scale
```

Mevcut **62×95 mantıksal çizim/seçim kutusu** korunur. Ayak referansı kutunun alt ortasına, yani işçinin dünyadaki zemin noktasına oturur. Kaynak PNG bütünü ölçeklenerek çizilir; dış boş tuval taşması sabit kutuda çalışma zamanında kesilir. Kaynak PNG piksellerine yazılmaz. X ayak merkezleri pozlara göre yaklaşık hizalama işaretleridir; iskelet tabanlı temas çözümü değildir.

Tüm karelerin boy ve tuval farkları merkezi metadata ile normalize edilir. En büyük göreli düzeltme **SE-B** karesindedir: kendi IDLE karesine göre yaklaşık %10 daha fazla ölçek gerekir. Bu düzeltme boyu eşitler, yanlış bakış yönünü düzeltmez. Ek bileşen içi sihirli ofset, bob, sallanma veya rotasyon eklenmedi.

Mantıksal konum, footprint, derinlik değeri ve hitbox kare seçiminden etkilenmez. `WorldEntity` içindeki mevcut çizim işlemi ayrı bir sprite çizim metoduna ayrılmıştır; diğer nesnelerin çizimi aynı kalır.

## Entegrasyon ve test sahnesi

- `WorkerComponent`, yalnız `worker.id == 'turhan'` için yeni kareleri kullanır.
- Havva ve test haritasındaki eski Mehmet mevcut sunumlarını kullanır.
- Mevcut kodda prosedürel yürüyüş bob/sway yoktu; yeni karelere hiçbir prosedürel transform eklenmedi.
- Hasat sırasında yönlü IDLE kullanılır; hasat sprite animasyonu eklenmedi.
- Normal işçi hızı, A*, görev atama, ekipman, ekonomi, tarla, hasat süreleri ve tutorial alan mantığı değiştirilmedi.
- Ayrı geliştirme sahnesi: `http://127.0.0.1:7361/?visualTest=turhan`.
- Rota: `(6,7) → (10,7) → (10,3) → (6,3) → (6,7)`, yani **SE → NE → NW → SW**. Her köşede kısa bekleme vardır. Bu hareket sürücüsü yalnız test sahnesindeki geçici işçiye aittir; normal HarvestJob sistemine bağlanmaz.
- Sahne dokunmayla seçim, duraklatma/devam ve yönlü kareleri kapatma/açma kontrolleri içerir. Normal oyun için ayrı dönüş düğmesi vardır.

## Doğrulama ve gözlem

- `flutter analyze`: temiz.
- Tüm testler: **248/248**; önceki 237 test ve 11 yeni görsel/entegrasyon testi.
- Yeni testler dört izometrik yönü, A/IDLE/B/IDLE döngüsünü, son yönde beklemeyi, köşeyi, gerçek hareketsizliği, sabit mantıksal konum/derinlik/hitbox'ı, Havva/Mehmet dışlamasını, kapatma yolunu, 12 dosyayı ve görsel bileşensiz gerçek 25 kg hasadı doğrular.
- `flutter build web`: başarılı.
- `flutter build apk --debug`: başarılı. APK içindeki 12 Turhan PNG girişi ayrıca kontrol edildi.
- Chrome'da dört yönün yürüyüş A/IDLE/B ve duruş IDLE durumları gözlendi. Dokunmayla seçim ve yönlü kareleri kapatıp açma çalıştı. Yakalanan çalışma zamanı istisnası yok.
- Normal yeni oyunda Envanter üzerinden tarla kuruldu, Turhan işe alındı, makas alınıp takıldı ve çay dikildi. Gerçek büyüme ve HarvestJob sonunda **25 kg tarla stoğu**, **8.000 Altın** doğrulandı. Turhan görev yerine yeni yönlü karelerle yürüdü; oyun saati hızlandırılmadı. Görseller: `turhan_normal_harvest_walk.png`, `turhan_normal_harvest_done.png`.
- Ekran gözlemleri: `turhan_SE_walk_A.png`, `turhan_SE_walk_B.png`, diğer `turhan_<yön>_<durum>_<kare>.png` dosyaları ve `turhan_selection.png`. Hızlı kare geçişlerinde ekran görüntüsü isteği bir sonraki kareye yetişebilir; görüntünün üzerindeki canlı durum etiketi esas alınmalıdır. Piksel eşitliği testi yapılmaz.
- Gözlem kaydı: `turhan-browser-observation.json`.
- Android cihaz doğrulaması **yapılmadı**: ADB yalnız çevrimdışı `emulator-5554` gösterdi.

APK kopyası: `C:\Users\Mehmet Demircioglu\Downloads\cay-simulasyonu-turhan-test-debug.apk`.

Sonraki bir görsel düzeltme için en önce gerçek alfa kanalları ve SE-B yönü düzeltilmelidir. Bu çalışma kapsamında sanat değiştirilmedi, Havva veya hasat animasyonuna geçilmedi.
