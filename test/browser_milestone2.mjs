// Real UI check, without modifying game state or bypassing elapsed time.
// node --experimental-websocket test/browser_milestone2.mjs DEBUG_PORT [inspect|loop]
import {writeFileSync} from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && /(?:localhost|127\.0\.0\.1):(7359|7361)/.test(p.url));
if (!page) throw Error('Milestone 2 sekmesi bulunamadı');
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
  writeFileSync(`milestone2_${name}.png`,Buffer.from(result.data,'base64'));
}
try {
  await call('Runtime.enable');
  if (['release','initial'].includes(process.argv[3])) {
    await call('Page.navigate', {url:'http://127.0.0.1:7361/?map=dev'});
    await wait(1000);
  }
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
  for (let attempt=0; attempt<30; attempt++) {
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if ((await texts()).includes('Altın:')) break;
    await wait(500);
  }
  await wait(2500); // HUD mounts before Flame finishes decoding its PNGs.
  if (!['loop','release'].includes(process.argv[3])) {
    console.log(await texts()); await capture('initial');
  } else {
    await assertText('Altın: 10.000'); await assertText('Alım Yerindeki Çay: 0 kg');
    await click(640,60); await assertText('Durum: Boş');
    await button('Çay Dik'); await assertText('Altın: 9.750');
    await assertText('Durum: Ekildi'); await capture('planted');
    await wait(5200); await assertText('Durum: Büyüyor — 1. aşama'); await capture('growing1');
    await wait(5000); await assertText('Durum: Büyüyor — 2. aşama'); await capture('growing2');
    await click(765,123); await button('Çay Dik');
    await click(640,60);
    await wait(8000); await assertText('Durum: Hasada Hazır'); await capture('ready');
    await button('Hasat Et'); await assertText('Mehmet tarlaya geliyor');
    await wait(12000); await assertText('Alım Yerindeki Çay: 0 kg');
    await assertText('Tarlada Bekleyen Yaş Çay: 25 kg');
    await assertText('Durum: Hasat Edildi'); await capture('harvested');
    await wait(5200); await assertText('Durum: Hasat Edildi'); await capture('waiting_stock');
    await click(515,123); await assertText('Durum: Boş');
    // Collection center: the asset's visual center in the initial camera view.
    await click(1014,265); await assertText('Çay Alım Yeri');
    await assertText('Durum: Açık'); await assertText('Teslim Alınan Yaş Çay: 0 kg');
    await capture('collection');
    if (exceptions.length) throw Error(JSON.stringify(exceptions));
    console.log('Tarayıcı hasat döngüsü başarılı; çalışma zamanı hatası yok.');
  }
} finally { ws.close(); }
