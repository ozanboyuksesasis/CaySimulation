// Derived report tables. Run after the baseline and final real-domain runners.
import {readFileSync,writeFileSync} from 'node:fs';
const read=f=>JSON.parse(readFileSync(f,'utf8')).results;
const baseline=read('balance_baseline.json'),final=read('balance_results.json');
const flat=final.flatMap(r=>r.checkpoints.map(c=>{const row={...c};for(const w of c.workers)for(const [k,v] of Object.entries(w))row[w.id+'_'+k]=v;for(const [k,v] of Object.entries(c.levelTimes))row['level_'+k+'_seconds']=v;return row;}));
const csvKeys=[...new Set(flat.flatMap(Object.keys))];
const csv=v=>'"'+(v==null?'':typeof v==='object'?JSON.stringify(v):String(v)).replaceAll('"','""')+'"';
writeFileSync('balance_results.csv',[csvKeys.map(csv).join(','),...flat.map(r=>csvKeys.map(k=>csv(r[k])).join(','))].join('\n'));
const end=r=>r.checkpoints.at(-1),at=(r,m)=>r.checkpoints.find(c=>c.minutes===m);
const num=(v,d=1)=>v==null?'—':Number(v).toFixed(d);
const time=s=>s==null?'ulaşılmadı':`${Math.floor(Math.round(s)/60)}:${String(Math.round(s)%60).padStart(2,'0')}`;
const table=(headers,rows)=>[headers.join(' | '),headers.map(()=> '---').join(' | '),...rows.map(r=>r.join(' | '))].join('\n');
const controls=final.find(r=>r.scenario==='G_SHEARS');
const roiRows=final.filter(r=>r.scenario.startsWith('U_')||r.scenario==='G_MOTOR').map(r=>{
 const e=end(r), c=end(controls),a=at(r,30),b=at(controls,30);
 const marginal=(e.revenue-a.revenue-c.revenue+b.revenue)/30;
 return [r.scenario,time(e.interventionSeconds),e.interventionCost,
   num((e.harvestedRawKg-a.harvestedRawKg)/30),num((e.revenue-a.revenue)/30),num(marginal),
   marginal>0?num(e.interventionCost/marginal)+' dk (tahmin)':'bu pencerede yok',e.revenue-c.revenue];
});
const policies=`- A_NORMAL: öğreticide her başarılı adımdan sonra 1–2 saniyelik tohumlanmış karar aralığı; tam gelir zinciri; 500 brüt gelirden sonra ikinci tarla; 3.000 gelirden sonra Havva/makas; 6.000 gelirden sonra kamyon hızı ve boş işçi gelişim puanları.
- B_CONSERVATIVE: temel zincir; 30. dakikadan sonra ikinci tarla, başka geliştirme yok.
- C_AGGRESSIVE: temel zincirden hemen sonra dört tarla; yeterli bakiye oluşunca Havva/makas; 6.000 gelirde kamyon hızı/işçi puanları.
- D_POOR: öğretici sonrası güneyde 140 gereksiz yol girişimi; koruma 120 karodan sonra harcamayı durdurur. Erken Havva/motor/dekor girişimleri de denenir. Endüstri kurulumu 180. saniyeye ertelenir. Engellenen işlemler para harcamaz.
- E_MINIMUM: normal başlangıçla aynı alan sistemleri, yalnız 12.000 başlangıç sermayesi; bir tarla/Turhan/makas ve gelir binaları; genişleme yok. Bu, ücretsiz mevcut yol omurgasında kanıtlanan minimumdur. E_ROADS varyantı fabrika ve paketlemeyi daha uzağa kurar; kamyonun gerçekten kullandığı dört ek yol için100 Altın öder.
- F_TURHAN / F_HAVVA / F_BOTH: aynı dört tarla, aynı makas, aynı başlangıç seviye1 istatistikleri. Tek işçi karşılaştırmasında ilk öğretici seçimi değiştirilir; iki işçide Havva yasal satın alımla eklenir. XP doğal olarak çalışana gider; son seviyeler zorla eşitlenmez. Başlangıç dosyasındaki eski F_HAVVA, Turhan ile başlayıp Havva’ya geçmek zorundaydı; doğrudan eşit başlangıç karşılaştırması son dosyadadır.
- G_SHEARS / G_MOTOR: tek tarla, aynı başlangıç; motor yalnız gerçek işletme Seviye6 olduğunda ve işçi boşken normal fiyatıyla alınır. Öncesinde motor etkisi yoktur.
- H_STABILITY: tek tarlalı zincir 60 dakika müdahalesiz sürer.
- U_*: G_SHEARS ile aynı kontrol; 600. saniyeden sonra ilk geçerli boşlukta yalnız adındaki geliştirme bir kez yapılır. Seviye/kasa/meşguliyet denetimleri atlanmaz.`;
const main=final.filter(r=>!r.scenario.startsWith('U_'));
const report=`# M10.1 — Ölçüm ve denge raporu

## Yöntem ve tekrar üretme

Gerçek CayGame birleşimi oluşturulur; onLoad, Flame render, görsel animasyon veya gerçek zaman bekleme çağrılmaz. Aynı builder, öğretici, işçi, otomasyon, kamyon, üretim, paketleme ve müşteri sistemleri çalışır. Alan saati Duration ile ilerler. Dış ölçüm adımı 250 ms, WorldSimulation iç adımı en çok50 ms ve gerçek olay sınırlarıdır. Bir saniyede bir stok/iş/Altın/işçi XP değişmezleri kontrol edilir. Kullanım oranları 250 ms örneklenmiş tahminlerdir; olay/işlem zamanları alan saatinden alınır.

Tohum **10101** karar aralıklarını belirler. Dünya müşteri aralığı rastgele değildir; 10 saniyedir. Aynı tohumla işlem defteri ve kontrol noktalarının bitişik JSON karşılaştırması otomatik testte aynıdır. 5/15/30/60 dakika tüm ${final.length} senaryoda kaydedilir. Müşteri/ürün/XP/Altın enjekte edilmez. Varsayılan flutter test yalnız doğrulama testlerini çalıştırır; uzun dışa aktarım açık bayrak ister.

Proje kökünden:

\`\`\`powershell
& C:\\codespace\\sdk\\flutter\\bin\\flutter.bat test test/simulation/balance_runner_test.dart --dart-define=BALANCE_RUN=true --reporter expanded
\`\`\`

İsteğe bağlı bayraklar: BALANCE_SCENARIO=A_NORMAL,E_MINIMUM; BALANCE_MINUTES=5/15/30/60; BALANCE_SEED=10101; BALANCE_OUTPUT=balance_results. Komut flutter test ile çalışır çünkü gerçek uygulama bileşimi dart:ui ve Flutter ChangeNotifier kullanır; grafik bağlamı/Chrome gerekmez.

## Değişiklik öncesi kanıt

İkinci tohum **20202**, E_MINIMUM için ayrıca5 dakika çalıştırıldı: ilk satış282,95 saniye, iki paket/300 Altın gelir,0 Altın ödülü; balance_seed20202.json/csv. Bu ek kısa kontrol21 tam koşunun yerine geçmez.

balance_baseline.json/csv, eski 18 saniyelik büyümeyle çalıştırılmış 20 senaryonun çıktısıdır. Parametre değiştirilmeden önce kaydedildi. balance_candidate.json/csv tek değişkenli aday denemesidir. balance_results.json/csv kabul edilen ayarla tam tekrar çalıştırmadır.

Eski tek tarlalı G_SHEARS, 60 dakikada ${end(baseline.find(r=>r.scenario==='G_SHEARS')).soldUnits} paket satıyordu. Dört tarlalı C_AGGRESSIVE de ${end(baseline.find(r=>r.scenario==='C_AGGRESSIVE')).soldUnits} paket satıyordu: erken genişlemenin ek satış getirisi yoktu. Tek tarlada büyüme dahil üretim müşteri talebini aşıyordu.

## Kabul edilen tek sayısal değişiklik

PlantationConfig.growing2Duration **8 → 40 saniye**; toplam büyüme **18 → 50 saniye**. İlk iki aşama5+5, yenilenmenin ilk aşaması5 saniye olarak kaldı. İlk ekimden sonra tekrar ekim ücreti yok. Fiyat, başlangıç sermayesi, müşteri sıklığı, kapasite, hasat verimi, taşıma süresi, reçete, XP ödülü/eşiği değiştirilmedi.

Gerekçe: müşteriyi iki kat sıklaştırarak Altın üretimini artırmak yerine, mevcut 6 müşteri/dakika talebine göre hammaddeyi anlamlı bir erken kapasite kararına çevirmek. Minimum zincir ilk satışı beş dakikadan önce yapıyor; iki tarla satış açığını kapatıyor. Bu sonuç örnek harita/yerleşim ve bu satın alma politikalarına aittir; her olası harita için denge garantisi değildir.

## Sermaye ve sürdürülebilirlik

Tarla500 + Turhan1000 + makas250 + ekim250 + merkez2500 + fabrika4000 + paketleme2000 + dükkân1500 = **12.000**. Mevcut ücretsiz yol omurgası minimuma yeter. Normal **15.000** sermayeden 20 yol karosu için500 ayrıldığında **2.500 güvenlik payı** vardır. Başlangıç Altını değiştirilmedi. Ara ürün geliri, öğretici Altın yardımı veya tekrar eden kurtarma parası yoktur.

Koruma, eksik gelir binalarının parasını isteğe bağlı alımlara karşı ayırır. D senaryosu bu korumaya çarpar, 0 nakitle tamamladığı zincirden gerçek müşteri geliri elde eder. Yer değiştirme ücretsizdir; ayrıca 0 Altınla bina taşıyıp gelir sürdürülebilirliği test edilir. Bunlar ekonomik çıkmaz değil, zaman kaybıdır. Her karoyu kötü yol/dekorla doldurmanın tüm olası uzamsal kombinasyonları ispatlanmadı; harita tıkanıklığı genelleştirilmiş bir kurtarma sistemi olarak sunulmaz.

Ek olumsuz kontrol: 11.999 Altın ile minimum zincirin eksik bir Altını gerçek bir sermaye yetersizliği olarak doğrulanır; büyümeyi beklemek bunu çözmez. Normal 15.000 başlangıç bu duruma düşmez. E_ROADS kontrolü dört ücretli yolun gerçek kamyon rotasında kullanıldığı 12.100 Altınlık kurulumu ayrıca ölçer.

## Senaryo politikaları

${policies}

## Kontrol noktaları

Altın anlık bakiyedir. Gelir ve harcama kümülatiftir. Net nakit akışı = satış geliri − tüm kurulum/geliştirme giderleri; başlangıç sermayesi kazanç sayılmaz. Oyun ücret/yakıt vb. işletme gideri içermediğinden bu muhasebe anlamında net kâr değildir.

${table(['Senaryo','Dakika','Altın','Brüt satış','Harcama','Net nakit','Seviye / XP','Satılan paket'],main.flatMap(r=>r.checkpoints.map(c=>[r.scenario,c.minutes,c.gold,c.revenue,c.spending,c.netCashFlow,c.businessLevel+' / '+c.businessXp,c.soldUnits])))}

## İlk gelir ve seviye zamanları

500/1000 sütunları ilk kümülatif brüt satış eşiğidir, Altın bakiyesindeki net artış değildir. İkinci tarla eşiği tarla+ilk ekim750 Altın ve zorunlu bütçe koruması birlikte kontrol edilerek satın alma politikası karar anında kaydedilir. Tam yatırım dönüşü net nakit ilk kez pozitif olduğunda ölçülür; ileride yeni yatırım tekrar düşürebilir.

${table(['Senaryo','İlk satış','500 gelir','1000 gelir','İkinci tarla alınabilir','Yatırım dönüşü','Sv2','Sv3','Sv4','Sv5','Sv6'],main.map(r=>{const c=end(r);return [r.scenario,time(c.firstSaleSeconds),time(c.earned500Seconds),time(c.earned1000Seconds),time(c.secondFieldAffordableSeconds),time(c.firstPositiveNetCashFlowSeconds),...['2','3','4','5','6'].map(l=>time(c.levelTimes[l]))]}))}

## Önce / sonra

${table(['Senaryo','İlk satış eski → yeni','60dk satış eski → yeni','60dk Altın eski → yeni','Sv6 eski → yeni'],main.filter(r=>!r.scenario.startsWith('F_')&&baseline.some(b=>b.scenario===r.scenario)).map(r=>{const a=end(baseline.find(b=>b.scenario===r.scenario)),b=end(r);return [r.scenario,time(a.firstSaleSeconds)+' → '+time(b.firstSaleSeconds),a.soldUnits+' → '+b.soldUnits,a.gold+' → '+b.gold,time(a.levelTimes['6'])+' → '+time(b.levelTimes['6'])]}))}

## Kapasite, darboğaz ve kullanım

Fabrika teorik600 kg yaş/dakika →120 kg kuru/dakika (100→20 kg /10 saniye); paketleme teorik150 paket/dakika (20 paket /8 saniye). Müşteri talebi en çok6 paket/dakika =900 Altın/dakika; yol ve stok varsa. Bunlar nominal makine kapasiteleri, gerçekleşen satış değildir. Kamyon için hız ve rota ayrıca etkilidir; kapasite artışı her seferde25 kg taşıyan bir işte kendiliğinden fayda sağlamaz.

Son30 dakikanın ölçülen hızları:

${table(['Senaryo','Yaş hasat kg/dk','Satış paket/dk','Brüt Altın/dk','Kamyon kullanım % (tüm süre)','Fabrika %','Paketleme %','Reyon boş %','60dk ürün bekliyor (kuru kg / paket)','Darboğaz'],main.map(r=>{const c=end(r),a=at(r,30);return [r.scenario,num((c.harvestedRawKg-a.harvestedRawKg)/30),num((c.soldUnits-a.soldUnits)/30),num((c.revenue-a.revenue)/30),num(c.truckUtilization*100),num(c.factoryUtilization*100),num(c.packagingUtilization*100),num(c.shelfStockoutFraction*100),c.factoryDryKg+' / '+c.packagedStockUnits,c.mainBottleneck]}))}

İlk darboğaz tek tarlada hammadde/büyümedir. İki/dört tarla sonrası satış talebi sınırı devreye girer. Kamyon daha yoğun çalışır; işçi ve fabrika ek boş kapasite taşır. Bir sonraki makineyi hızlandırmanın final gelir sağlamadığı durum raporda açıkça sıfır yazılmıştır.

## İşçi karşılaştırması ve XP

${table(['Senaryo','Dakika','İşçi','Seviye / XP / sonraki','Hasat sayısı','Kullanım %','Ekipman','Hasat sn','Boş gelişim puanı'],main.filter(r=>['A_NORMAL','F_TURHAN','F_HAVVA','F_BOTH','G_SHEARS','G_MOTOR'].includes(r.scenario)).flatMap(r=>r.checkpoints.filter(c=>c.minutes>=15).flatMap(c=>c.workers.map(w=>[r.scenario,c.minutes,w.id,w.level+' / '+w.xp+' / '+w.nextXp,w.harvests,num(w.utilization*100),w.equipment,num(w.harvestSeconds,3),w.points]))))}

Turhan ve Havva tek işçi testlerinde aynı ekipmanla aynı başlangıç istatistiklerine sahiptir; farklı verim bonusu yoktur. Çift işçi örneğinde yalnız gerçek hasadı bitiren XP alır. Motor ilk gerçek Seviye6 anından önce satın alınmaz. F ve G için5 dakikada motor karşılaştırması uygulanabilir değildir: motor henüz kilitlidir; kontrol noktası yine kaydedilir ve ekipman makas olarak görünür.

## Geliştirme marjinal getirisi

Kontrol G_SHEARS. Tüm geliştirmeler mevcut alan servisiyle satın alındı; sıfır Altınlı işçi puanı da gerçek kazanılmış puandır. Altın/dk farkı30–60 dakika penceresindendir. Parti/müşteri zamanlaması yüzünden küçük farklar uzun dönem garantisi değildir. Tahmini geri ödeme = maliyet / pozitif marjinal hız; gözlenen60 dakikada geri ödenmiş olduğu anlamına gelmez.

${table(['Geliştirme','Uygulama zamanı','Maliyet','Hasat kg/dk','Altın/dk','Ek Altın/dk','Tahmini geri ödeme','60dk ek brüt gelir'],roiRows)}

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

${table(['Senaryo','Müşteri doğdu / ulaştı / aldı / kayıp','En çok aktif','En yaşlı aktif iş sn','Değişmez kontrolü'],main.map(r=>{const c=end(r);return [r.scenario,[c.customersSpawned,c.customersArrived,c.customersServed,c.customersLost].join(' / '),c.maxActiveCustomers,num(c.maxActiveJobAgeSeconds),c.invariantChecks]}))}

## Doğrulama durumu

Son doğrulama bilgisi M10_1_CHANGELOG.md içinde yer alır. Derleme veya cihaz testi yapılmadıysa başarılı olarak gösterilmez. Chrome kayıtları m10_1-browser-observation.json ve m10_1_*.png dosyalarıdır. APK yolu build/app/outputs/flutter-apk/app-debug.apk.

## Sınırlar ve sonraki öncelikler

Bu ${final.length} politika olası tüm oyuncu davranışlarını tüketmez. 60 dakika bir denge penceresidir, sonsuz koşu kanıtı değildir. Parti sınırından kaynaklanan küçük ROI farkları için daha uzun gözlem gerekir. Dünya yolu kısa ve başlangıç omurgasına bağlıdır; farklı yerleşimler ilk satışı ve kamyon kullanımını değiştirir. Henüz işletme gideri yoktur. İç endüstriyel aktarım korunur; yeni araç eklenmedi. İş geçmişi/ödül kimliği listeleri uzun oturumda büyür; müşteri aktif sayısı sınırlı olsa da gelecekte kayıt politikası ayrıca ele alınmalıdır. M11, yeni içerik veya animasyon başlanmadı.
`;
writeFileSync('M10_1_BALANCE_REPORT.md',report);
console.log('M10_1_BALANCE_REPORT.md üretildi; '+final.length+' senaryo.');
