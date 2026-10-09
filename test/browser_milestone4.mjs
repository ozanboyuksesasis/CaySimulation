// Real Chrome clicks and elapsed time only; no changes to gameplay state.
// node --experimental-websocket test/browser_milestone4.mjs 7360 [inspect]
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
  writeFileSync(`milestone4_${name}.png`,Buffer.from(result.data,'base64'));
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
  await call('Runtime.enable');
  await call('Page.navigate',{url:'http://127.0.0.1:7361/?map=dev'});
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
  for (let i=0;i<50;i++) {
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if ((await texts()).includes('Altın:')) break;
    await wait(500);
  }
  await wait(2500);
  await assertText('Altın: 10.000');
  await assertText('Alım Yerindeki Çay: 0 kg');
  await capture('initial');
  if (process.argv[3] !== 'inspect') {
    await click(765,276); await assertText('Çay Kamyonu'); await assertText('Durum: Boşta');
    await assertText('Kapasite: 100 kg'); await capture('truck_idle');
    await click(515,123); await button('Çay Dik');
    await click(765,123); await button('Çay Dik');
    await until('Durum: Hasada Hazır',22000);
    await click(515,123); await button('Hasat Et');
    await click(765,123); await button('Hasat Et');
    await assertText('Hasat sırası bekliyor');
    await click(515,123); await until('Durum: Hasat yapılıyor'); await capture('harvest');
    await until('Tarlada Bekleyen Yaş Çay: 25 kg',7000);
    await assertText('Alım Yerindeki Çay: 0 kg');
    await button('Taşıma Emri Ver'); await assertText('Nakliye: Çay Kamyonu geliyor');
    await capture('truck_to_field');
    await click(765,123); await assertText('Mehmet tarlaya geliyor');
    await capture('simultaneous_movement');
    await wait(1000); await capture('simultaneous_later');
    await click(470,95); await until('Nakliye: Yükleniyor');
    await assertText('Tarlada Bekleyen Yaş Çay: 25 kg'); await capture('loading');
    await until('Tarlada Bekleyen Yaş Çay: 0 kg',4500);
    await assertText('Durum: Yeniden büyüyor');
    await assertText('Alım Yerindeki Çay: 0 kg'); await capture('loaded_regrowth');
    await click(765,123); await until('Tarlada Bekleyen Yaş Çay: 25 kg',8000);
    await button('Taşıma Emri Ver'); await assertText('Nakliye: Taşıma sırası bekliyor');
    await capture('transport_queue');
    await wait(500);
    // First delivery stops at (10,4), outside the collection building footprint.
    await selectOnArrival(890,214,'Durum: Teslimat yapılıyor');
    await assertText('Yük: 25 / 100 kg'); await capture('unloading');
    await click(1014,265); await assertText('Çay Alım Yeri');
    await until('Teslim Alınan Yaş Çay: 25 kg',5000);
    await assertText('Alım Yerindeki Çay: 25 kg'); await assertText('Altın: 9.500');
    await capture('first_delivery');
    await click(765,123); await assertText('Nakliye: Çay Kamyonu geliyor');
    await capture('second_pickup');
    await click(1014,265); await until('Teslim Alınan Yaş Çay: 50 kg',18000);
    await assertText('Alım Yerindeki Çay: 50 kg'); await assertText('Altın: 9.500');
    await capture('second_delivery');
    await wait(2500); await click(765,276); await assertText('Durum: Boşta');
    await assertText('Yük: 0 / 100 kg'); await capture('returned_home');
    await click(960,42); await assertText('Izgara açık'); await capture('debug_roads');
    if (exceptions.length) throw Error(JSON.stringify(exceptions));
    console.log('Milestone 4 fiziksel hasat ve iki FIFO teslimat Chrome kontrolü başarılı.');
  }
} catch(error) { await capture('failure'); throw error; }
finally { ws.close(); }
