# Mobil UX, dünya geri bildirimi ve kısa öğretici

5 Ekim 2026. Mevcut Flutter/Flame projesi üzerinde görsel/etkileşim düzenlemesi; yeni ekonomi veya üretim aşaması eklenmedi.

## Oyuncu deneyimi

- Üst HUD tek satırlık kimlik ve Altın bilgisine indirildi. Kalıcı büyük başlık/alt başlık kaldırıldı. Izgara ve test haritası, sağ üstteki `Geliştirici araçları` menüsünde.
- Envanter alttaki yatay katalog tepsisi oldu. Kategori satırı yatay kayar; kartlar küçük resim, ad, fiyat, sahiplik ve 44 px eylem içerir. Uzun açıklamalar sürekli gösterilmez. Kartlar yatay, gerektiğinde kart içeriği dikey kayar.
- Tepsi yüksekliği en fazla 216 px: 1280×720'de %30, 960×540'ta yaklaşık %36, 844×390'da yaklaşık %42. Güvenli alan ve iç kaydırma korunur. Ana navigasyon Envanter/İşletme olarak kaldı.
- Seçim kartı daraltıldı; işçi panelinden kalıcı `İşçi`, boş görev ve sabit hasat süresi satırları çıkarıldı. `Ekipman` eylemi mevcut gerçek ekipman değişimini açar. Araç ve fabrika kartlarındaki tekrarlar azaltıldı; mevcut dikim, hasat, taşıma, sevkiyat, üretim, tekrar yol deneme ve Taşı eylemleri korundu.
- Hedef kartı varsayılan olarak kapalı/kompakt. Kısa hedef görünür; `Hedefi aç` rehber eylemini açar. Karşılama ve teslimat tamamlama düğmeleri doğrudan görünür. Büyük engelleyici öğretici penceresi yok.

## Dünya göstergeleri

`WorldStatus` salt okunur sunum verisi üretir; `WorldStatusLayer` göstergeleri ayrı bir dünya katmanında çizer. Domain stokları veya saatleri kopyalanmaz/değiştirilmez.

| Nesne | Haritadaki geri bildirim |
|---|---|
| Boş tarla | Yalnız seçili/rehberin hedefi ise `Boş` |
| Ekilmiş/büyüyen/yenilenen tarla | `Büyüyor` ve gerçek toplam ilerleme çubuğu |
| Hazır tarla | Küçük onay işareti ve `Hasada Hazır`; büyüme çubuğu yok |
| Hasat stoğu | Mevcut V3 çuval görseli ve örneğin `25 kg` |
| İşçi | Boştayken etiketsiz; seçilince adı, çalışırken `Hasat`, işe yürürken küçük etkinlik noktası |
| Kamyon | Seçili, yükleme/boşaltmada veya yüklüyken `25 / 100 kg`; boş ve boştayken etiketsiz |
| Fabrika | Üretim sırasında gerçek üretim çubuğu; bitince örneğin `20 kg Kuru Çay` |

Tarla toplam ilerlemesi yapılandırılmış sürelerle ağırlıklandırılır: ilk döngüde **5 + 5 + 8 saniye**, sonraki döngüde ilk aşama yerine mevcut yenilenme süresi. Aşamalar arası sıfırlanmaz. Stok tarlada beklerken büyüme başlamaz. READY %100'dür. Domain GROWING_1/GROWING_2 ve mevcut görseller korunmuştur.

Göstergelerin ekran boyutu kameradan bağımsız tutulur. Zoom 0,6 altındayken ayrıntılı yazı yerine önemli simge/çuval/çubuk kalır. Onay simgesi fontta eksik glif oluşmaması için çizgilerle çizilir; yeni bitmap/art üretilmedi.

## Derinlik ve dokunma

- Sıralama sprite yüksekliğinden, alfa sınırından veya animasyon karesinden etkilenmez. İşçi ayak ve kamyon taban konumu mantıksal nokta; bina/tarla mantıksal footprint olarak değerlendirilir.
- Ayrık footprint kenarları ön/arka kısıtları oluşturur. Bu, binanın yalnız en ön köşe Y değerine göre sıralanmasındaki yan yaklaşım hatasını giderir. Belirsiz veya döngüsel örtüşmede taban Y/X/benzersiz ID kararlı yedektir.
- Turhan IDLE/A/B geçişleri konumu, hitbox'ı ve derinliği değiştirmez. PNG ve frame metadata değişmedi. Havva'ya yeni animasyon eklenmedi.
- **450 ms uzun basma** mevcut `BuilderSystem.startMove` yolunu kullanır. Kısa bir footprint çizgi vurgusu ve Türkçe bildirim verir. Parmak basılıyken sürükleme, ilk tutulan noktaya göre nesneyi kaydırır; parmak kalkınca otomatik onay yok.
- 12 px üzeri normal sürükleme veya ikinci parmak, bekleyen uzun basmayı iptal eder. Taşıma sırasında ikinci parmak kamera hareketine döner; yerleşimi onaylamaz. Tap seçer, pan kamerayı hareket ettirir, pinch yakınlaştırır. Açık `Onayla / Vazgeç` ve `Taşı` düğmeleri korunur. Haptik zorunluluğu yok.
- Meşgul nesne taşıma kuralları, gerçek stoklar, eski occupancy ve etkileşim noktaları korunur. Vazgeç domain'i değiştirmez; onay yalnız mevcut taşıma API'sini çağırır.

## Öğretici ve serbest oyun

Zorunlu akış artık:

**Tarla kur → Turhan/Havva işe al → makas al/kuşan → dik → büyüt → bir gerçek hasat → 25 kg tarla stoğu → Çay Alım Yeri/yol → bir gerçek kamyon teslimatı → Devam Et → COMPLETED.**

Tamamlama metni: `İlk çayını başarıyla teslim ettin! Artık işletmeni büyütmeye hazırsın.` Gerçek teslim edilmiş transport job kaydı esas alınır; stok ekleme, zaman atlatma veya ödül verilmez. Sonrasında ekipman/yol değişmesi onboarding'i geriye döndürmez.

Fabrika artık zorunlu öğretici değildir. Tamamlanmış öğreticiden bağımsız, salt dünya durumundan türeyen `ProgressionStep` hedefleri:

1. Çay Fabrikası Kur.
2. Gerekiyorsa gerçek yol bağlantısı.
3. Fabrikaya 100 kg Yaş Çay Ulaştır; gerçek fabrika ham stok miktarı gösterilir.
4. İlk Kuru Çayını Üret; mevcut 100 → 20 kg / 10 saniye reçetesi.
5. Küçük tamamlandı geri bildirimi.

Bu hedefler hiçbir edinme/yerleşim/iş komutunu kilitlemez. Ek altın verilmez. Oyuncu hedefi yok sayabilir.

## Kamera ve ölçek incelemesi

Üç yatay Chrome boyutu kontrol edildi: **844×390, 960×540, 1280×720**. Normal yeni oyunun başlangıç odağı çiftlik çevresindeki mantıksal `(7,8)` noktasına alındı; mevcut kamera sınırları uygulanır. Dev test haritasının odağı değişmedi. Başlangıç zoom'u **0,65**, minimum/maksimum zoom ve bütün sprite boyutları korunmuştur.

İşçi tarla/ev yanında okunabilir; mevcut stilize ölçekte ev kapısına göre biraz büyük görünebilir. Kamyon yol üzerinde okunabilir, fabrika alım yerinden daha büyük görünür. Gerçekçi metre ölçeği iddiası yok; toplu sprite büyütme veya footprint değişikliği yapılmadı. En küçük ekranda oyuncu pan/pinch ile çalışma alanını ayarlayabilir.

## Dosyalar

Yeni:

- `lib/game/systems/world_status.dart`
- `lib/game/components/world_status_layer.dart`
- `lib/features/ui/world_move_gesture.dart`
- `test/world_feedback_test.dart`
- `test/long_press_move_test.dart`
- `test/browser_mobile_ux.mjs`
- Bu rapor.

Değişen ana dosyalar:

- `game/cay_game.dart`, `components/world_entity.dart`, `systems/depth_sorter.dart`, `systems/tutorial_system.dart`, `camera/management_camera.dart`.
- `features/plantation/tea_field.dart`, `tea_field_component.dart`; `features/transport/vehicle_component.dart`; `features/builder/placement_preview.dart`.
- UI: `game_screen.dart`, `game_hud.dart`, `player_panels.dart`, `tutorial_coach.dart`, `worker_info_panel.dart`, `field_info_panel.dart`, `transport_info_panel.dart`, `factory_info_panel.dart`.
- Güncellenen beklentiler: `milestone8_test.dart`, `game_smoke_test.dart`, `harvest_ui_test.dart`, `transport_ui_test.dart`, `factory_ui_test.dart`. Eski zorunlu dört hasat beklentisi yerine ilk teslimatta tamamlama + isteğe bağlı üretim doğrulanır.
- `browser_turhan_visual.mjs` yeni kamera/kompakt ekipman düğmesine uyarlandı. `browser_milestone8.mjs` giriş noktası yeni kabul senaryosuna yönlenir.

## Kontroller ve kanıtlar

- `flutter analyze`: **No issues found**.
- Flutter testleri: **259/259 geçti**; önceki 248 teste 11 yeni test eklendi. Zaman testleri gerçek saniye beklemez.
- Yeni kapsam: süre ağırlıklı büyüme, hazır/çuval/fabrika göstergeleri, domain'in değişmemesi, dört taraftan footprint/ayak sıralaması, animasyon karesinden bağımsız derinlik, 450 ms giriş, tap/pan/ikinci parmak iptali, gerçek widget uzun basma/sürükleme/iptal/onay ve 25 kg stok korunması.
- Her iki ilk işçi seçeneği için test: **tek hasat ve tek teslimatta**, fabrika henüz yokken öğretici tamamlanır. Daha sonra dört gerçek hasat/nakliye ve üretim zinciri çalışmayı sürdürür.
- `flutter build web`: **başarılı**.
- `flutter build apk --debug`: **başarılı**.
- Chrome dokunmatik kabul akışı: tek hasat → 25 kg gerçek teslimat → `Devam Et` → fabrika yokken `SIRADAKİ HEDEF`. O noktada Altın **5.500**. İsteğe bağlı fabrika ve ek döngülerle **20 kg kuru çay**, Altın **1.500**. Hiçbir gameplay state tarayıcıdan değiştirilmedi, zaman hızlandırılmadı.
- Üç boyutta Envanter/işçi kartları/İşletme, iptal ve gerçek yerleştirme, uzun basma, sürükleme, vazgeç, pan/pinch tekrar çalıştırıldı. JavaScript exception listeleri boş.
- Turhan'ın mevcut dört yön testi yeniden çalıştırıldı: 16 yön/poz/duruş durumu, seçim ve görsel aç/kapat; ardından normal oyunda gerçek 25 kg hasat geçti.
- Kanıtlar: `ux-tests.log`, `ux-browser-observation.json`, `ux-layout-observation.json`, `turhan-browser-observation.json`; `ux_inventory_844.png`, `ux_inventory_960.png`, `ux_inventory_1280.png`, `ux_selection_844.png`, `ux_longpress_844.png`, `ux_one_delivery_completed.png`, `ux_factory_processing.png`, `ux_factory_output.png` ve diğer `ux_*.png` ekran görüntüleri.

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Kullanıcı kopyası: `C:\Users\Mehmet Demircioglu\Downloads\cay-simulasyonu-mobile-ux-debug.apk`.

## Sınırlamalar ve korunmuş kapsam

- Tek parça bina sprite'ı, bir karakteri aynı anda çatının arkasında ve cephenin önünde parça parça gösteremez. Mantıksal sıralama düzeltildi; karmaşık kesişimler için ileride katmanlı sanat gerekebilir. Bu çalışmada görsel bölünmedi.
- Chrome dokunmatik otomasyonu ve ekran görüntüsü incelemesi yapıldı; fiziksel telefon doğrulaması değildir. ADB yalnız `emulator-5554 offline` gösterdi. Android/iOS cihaz testi yapılmadı.
- Mevcut CupertinoIcons font ve Java native-access derleme uyarıları sürüyor; derlemeler başarılı.
- Kaynak PNG'ler, Turhan yön kareleri/140 ms zamanlama, Havva sunumu, hareket hızları, ekipman performansı, hasat miktarı, fiyatlar, üretim reçetesi, yollar ve mantıksal footprint'ler değiştirilmedi.
- Yeni animasyon, ses, kayıt/yükleme, paketleme, satış, hava/gün döngüsü veya ekonomi sistemi eklenmedi.
