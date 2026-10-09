// Real Chrome clicks and elapsed time only; no changes to gameplay state.
// node --experimental-websocket test/browser_milestone5.mjs 7360 [inspect]
import {writeFileSync} from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && /(?:localhost|127\.0\.0\.1):7361/.test(p.url));
if (!page) throw Error('Oyun sekmesi bulunamadı');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, {once:true}));
let sequence = 0;
const pending = new Map();
const exceptions = [];
ws.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  if (message.id) { pending.get(message.id)?.(message); pending.delete(message.id); }
  if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params);
});
function call(method, params={}) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    const timeout = setTimeout(() => reject(Error(method)), 15000);
    pending.set(id, data => { clearTimeout(timeout); data.error ? reject(data.error) : resolve(data.result); });
    ws.send(JSON.stringify({id, method, params}));
  });
}
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
const evaluate = async expression => (await call('Runtime.evaluate', {expression, returnByValue:true})).result.value;
async function click(x,y) {
  await call('Input.dispatchMouseEvent', {type:'mousePressed',x,y,button:'left',clickCount:1});
  await call('Input.dispatchMouseEvent', {type:'mouseReleased',x,y,button:'left',clickCount:1});
  await wait(100);
}
async function texts() {
  return evaluate("document.body.innerText + '\\n' + [...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join('\\n')");
}
async function assertText(text) {
  const content = await texts();
  if (!content.includes(text)) throw Error(`Görünmedi: ${text}\n${content}`);
  console.log(`Doğrulandı: ${text}`);
}
async function button(label) {
  const rect = await evaluate(`(() => { const e=[...document.querySelectorAll('[role=button]')].find(e => e.getAttribute('aria-label')===${JSON.stringify(label)} || e.innerText===${JSON.stringify(label)}); if (!e) return null; const r=e.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; })()`);
  if (!rect) throw Error(`Düğme yok: ${label}\n${await texts()}`);
  await click(rect.x,rect.y);
}
async function capture(name) {
  const result = await call('Page.captureScreenshot',{format:'png'});
  writeFileSync(`milestone5_${name}.png`,Buffer.from(result.data,'base64'));
}
async function until(text, timeout=15000) {
  const end=Date.now()+timeout;
  while (Date.now()<end) {
    if ((await texts()).includes(text)) { console.log('Doğrulandı: '+text); return; }
    await wait(100);
  }
  throw Error('Beklenen durum gelmedi: '+text+'\n'+await texts());
}
async function selectOnArrival(x, y, text, timeout=8000) {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    await click(x, y);
    if ((await texts()).includes(text)) { console.log('Doğrulandı: ' + text); return; }
  }
  throw Error('Varış seçilemedi: ' + text + '\n' + await texts());
}
try {
  await call('Runtime.enable'); await call('Emulation.setTouchEmulationEnabled',{enabled:false});
  await call('Page.navigate',{url:'http://127.0.0.1:7361/?map=dev'});
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
  for (let i=0;i<50;i++) {
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if ((await texts()).includes('Altın:')) break;
    await wait(500);
  }
  await wait(2500);
  await assertText('Altın: 10.000');
  await click(723,478); await assertText('Çay Fabrikası');
  await assertText('Üretim için 100 kg daha yaş çay gerekiyor.');
  await capture('factory_empty');
  await click(515,123); await button('Çay Dik');
  await click(765,123); await button('Çay Dik');
  async function harvestPair(total) {
    await click(470,95); await until('Durum: Hasada Hazır',25000); await button('Hasat Et');
    await click(765,123); await until('Durum: Hasada Hazır',25000); await button('Hasat Et');
    await click(470,95); await until('Tarlada Bekleyen Yaş Çay: 25 kg',15000);
    await button('Taşıma Emri Ver');
    await click(765,123); await until('Tarlada Bekleyen Yaş Çay: 25 kg',15000);
    await button('Taşıma Emri Ver');
    await click(1014,265); await until('Teslim Alınan Yaş Çay: '+total+' kg',30000);
    await assertText('Altın: 9.500'); await capture('collection_'+total);
  }
  await harvestPair(50);
  await harvestPair(100);
  await button('Fabrikaya Sevk Et');
  await assertText('Teslim Alınan Yaş Çay: 100 kg');
  await until('Sevkiyat: Yükleniyor',10000);
  await capture('shipment_loading');
  await selectOnArrival(890,214,'Durum: Alım Yerinde yükleme yapılıyor',2000);
  await assertText('Yük: 0 / 100 kg');
  await until('Durum: Çay Fabrikasına gidiyor',5000);
  await assertText('Yük: 100 / 100 kg'); await capture('truck_to_factory');
  await wait(900); await capture('truck_to_factory_later');
  // Dock (12,13) is visible beside the factory, outside its sprite bounds.
  await selectOnArrival(580,440,'Durum: Teslimat yapılıyor',10000);
  await assertText('Yük: 100 / 100 kg'); await capture('factory_unloading');
  await click(750,500); await assertText('Çay Fabrikası');
  await until('Yaş Çay Stoğu: 100 kg',6000);
  await assertText('Kuru Çay Stoğu: 0 kg'); await assertText('Altın: 9.500');
  await assertText('Durum: Üretime Hazır'); await capture('factory_ready');
  await button('Üretimi Başlat');
  await assertText('Durum: Üretim Yapılıyor');
  await assertText('Yaş Çay Stoğu: 0 kg'); await assertText('İşlenen Yaş Çay: 100 kg');
  await assertText('Kuru Çay Stoğu: 0 kg'); await capture('production_started');
  await wait(4000); await assertText('Durum: Üretim Yapılıyor'); await capture('production_progress');
  await until('Kuru Çay Stoğu: 20 kg',9000);
  await assertText('Durum: Bekliyor'); await assertText('Altın: 9.500');
  await capture('dry_tea');
  await click(765,276); await assertText('Çay Kamyonu'); await assertText('Durum: Boşta');
  await assertText('Yük: 0 / 100 kg');
  if (exceptions.length) throw Error(JSON.stringify(exceptions));
  console.log('Milestone 5 gerçek Chrome akışı: dört hasat, 100 kg fiziksel sevkiyat, tek proses, 20 kg kuru çay. Altın değişmedi.');
} catch(error) { await capture('failure'); throw error; }
finally { ws.close(); }

