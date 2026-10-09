// Real UI check, without modifying game state or bypassing elapsed time.
// node --experimental-websocket test/browser_milestone3.mjs DEBUG_PORT [inspect|loop]
import {writeFileSync} from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && /(?:localhost|127\.0\.0\.1):(7359|7361)/.test(p.url));
if (!page) throw Error('Milestone 3 sekmesi bulunamadı');
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
  await wait(150);
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
  writeFileSync(`milestone3_${name}.png`,Buffer.from(result.data,'base64'));
}

async function until(text, timeout=12000) {
  const end=Date.now()+timeout;
  while (Date.now()<end) {
    if ((await texts()).includes(text)) { console.log('Doğrulandı: '+text); return; }
    await wait(150);
  }
  throw Error('Beklenen durum gelmedi: '+text+'\n'+await texts());
}
try {
  await call('Runtime.enable');
  await call('Page.navigate',{url:'http://127.0.0.1:7361/?map=dev'});
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
  for (let i=0;i<40;i++) {
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if ((await texts()).includes('Altın:')) break;
    await wait(500);
  }
  await wait(2000);
  await assertText('Altın: 10.000');
  await click(515,246); await assertText('Mehmet'); await assertText('Durum: Boşta'); await capture('worker_idle');
  await click(515,123); await button('Çay Dik');
  await click(765,123); await button('Çay Dik');
  await until('Durum: Hasada Hazır',22000);
  await click(515,123); await assertText('Durum: Hasada Hazır');
  await button('Hasat Et'); await assertText('Mehmet tarlaya geliyor');
  await assertText('Alım Yerindeki Çay: 0 kg'); await capture('moving');
  await wait(650); await capture('moving_later');
  await click(765,123); await button('Hasat Et');
  await assertText('Hasat sırası bekliyor'); await capture('queued');
  await click(515,123); await until('Durum: Hasat yapılıyor');
  await capture('working');
  await click(557,142); await assertText('Mehmet'); await assertText('Durum: Çay topluyor');
  await capture('worker_working'); await click(515,123);
  await until('Tarlada Bekleyen Yaş Çay: 25 kg',7000);
  await assertText('Alım Yerindeki Çay: 0 kg'); await assertText('Altın: 9.500'); await capture('first_stock');
  await click(765,123);
  await assertText('Mehmet tarlaya geliyor'); await capture('moving_to_second');
  await until('Tarlada Bekleyen Yaş Çay: 25 kg',12000);
  await assertText('Alım Yerindeki Çay: 0 kg'); await capture('second_stock');
  await click(515,123); await wait(5500);
  await assertText('Durum: Hasat Edildi'); await assertText('Tarlada Bekleyen Yaş Çay: 25 kg');
  await capture('stock_blocks_regrowth');
  await click(1014,265); await assertText('Çay Alım Yeri');
  await assertText('Durum: Açık'); await assertText('Teslim Alınan Yaş Çay: 0 kg');
  await capture('collection');
  if (exceptions.length) throw Error(JSON.stringify(exceptions));
  console.log('Milestone 3 gerçek süreli fiziksel hasat akışı başarılı.');
} finally { ws.close(); }
