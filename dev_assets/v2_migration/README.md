# V2 görsel geçişinin geliştirme arşivi

Bu klasör Flutter asset listesinde değildir; oyun paketine eklenmez.

Son güncelleme: İlk geçişte reddedilen altı PNG'nin kullanıcı tarafından
temizlenmiş halleri Downloads'tan alındı. `user_cleaned/` kaynak kopyalarını,
`user_cleaned_audit.json` alfa/boyut/SHA-256 kontrolünü ve
`user_cleaned_review_*.png` orijinal/hasarlı/yeni karşılaştırmalarını içerir.
Altı yeni dosya kabul edilmiştir; oyun artık toplam 28 sağlam şeffaf tekil
görsel kullanır. Aşağıdaki eski ret kayıtları denetim geçmişi olarak korunur.

- `before/`: işlem öncesindeki 40 oyun PNG'sinin birebir yedeği.
- `original/`: V2 ZIP içindeki 40 değiştirilmemiş master.
- `transparent/`: V2 ZIP içindeki 28 şeffaf aday; 6'sı reddedildi.
- `before_hashes.json`: eski oyun PNG'lerinin SHA-256 değerleri.
- `code_before_hashes.json`: işlem öncesi Dart kaynaklarının SHA-256 değerleri.
- `alpha_audit.json`: ad eşleşmesi, alfa sayımı, sınır ve görünür piksel kutuları.
- `decisions.json`: 22 kabul ve 6 ret, açıklamalar, kullanılan dosyanın SHA-256 değeri.
- `review_*.png`: orijinal/şeffaf çiftleri dama zemininde; yalnız inceleme amacıyla.
- `rejected_*.png`: master/V1/V2 karşılaştırması; kaynak PNG'ler değiştirilmedi.

Reddedilenlerde V1'de de aynı nesne kaybı görüldü. Bu nedenle oyun için `original/`
masterları birebir geri alındı; eski hasarlı sürümler yalnız `before/` içinde korundu.
Sayısal alfa kontrolü tek başına yeterli değildir: koyu pikseller korunmuş olsa bile
açık renkli tavan/gömlek alanları silinebilir. Kararlar görsel karşılaştırmaya dayanır.

09 ve 35 dosyalarının kenara değen az sayıdaki opak pikseli bina/çevre çizimine
aittir; dört köşe şeffaftır, büyük arka plan dikdörtgeni yoktur.
