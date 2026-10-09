// Real Chrome input and elapsed time; never mutates gameplay state.
// node --experimental-websocket test/browser_milestone7.mjs 7360
import {writeFileSync} from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && /(?:localhost|127\.0\.0\.1):7361/.test(p.url));
if (!page) throw Error('Oyun sekmesi bulunamadı');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, {once:true}));
let sequence = 0;
const pending = new Map(), exceptions = [];
ws.addEventListener('message', event => {
  const m = JSON.parse(event.data);
  if (m.id) { pending.get(m.id)?.(m); pending.delete(m.id); }
  if (m.method === 'Runtime.exceptionThrown') exceptions.push(m.params);
});
function call(method, params={}) {
  return new Promise((resolve,reject) => {
    const id=++sequence, timeout=setTimeout(()=>reject(Error(method)),15000);
    pending.set(id,m=>{clearTimeout(timeout);m.error?reject(m.error):resolve(m.result);});
    ws.send(JSON.stringify({id,method,params}));
  });
}
const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const evaluate=async expression=>(await call('Runtime.evaluate',{expression,returnByValue:true})).result.value;
async function click(x,y) {
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(180);
}
const texts=()=>evaluate("document.body.innerText+'\\n'+[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join('\\n')");
async function assertText(value) {
  if (!(await texts()).includes(value)) throw Error('Görünmedi: '+value+'\n'+await texts());
  console.log('Doğrulandı: '+value);
}
async function button(label) {
  const rect=await evaluate(`(()=>{const e=[...document.querySelectorAll('[role=button]')].find(e=>e.getAttribute('aria-label')===${JSON.stringify(label)}||e.innerText===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
  if(!rect)throw Error('Düğme yok: '+label+'\n'+await texts());
  await click(rect.x,rect.y);
}
async function textClick(label) {
  const rect=await evaluate(`(()=>{const e=[...document.querySelectorAll('flt-semantics')].find(e=>e.getAttribute('aria-label')===${JSON.stringify(label)}||e.innerText===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
  if(!rect)throw Error('Metin yok: '+label+'\n'+await texts());
  await click(rect.x,rect.y);
}
async function capture(name) {
  const r=await call('Page.captureScreenshot',{format:'png'});
  writeFileSync(`milestone7_${name}.png`,Buffer.from(r.data,'base64'));
}
async function until(value,timeout=20000) {
  const end=Date.now()+timeout;
  while(Date.now()<end){if((await texts()).includes(value)){console.log('Doğrulandı: '+value);return;}await wait(150);}
  throw Error('Beklenen durum gelmedi: '+value+'\n'+await texts());
}

async function choose(category) { await button('Mağaza'); await textClick(category); }
async function buy(category) { await choose(category); await button('Satın Al'); }
async function placeInventory(x,y) { await button('Envanter'); await button('Yerleştir'); await tile(x,y); await button('Yerleştir'); }
async function tile(x,y) { await click(640+(x-y)*41.6,-47.68+(x+y)*20.8); }
async function swipe(x,y,dx,dy) {
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});
  for(let i=1;i<=12;i++){ await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x+dx*i/12,y:y+dy*i/12}]});await wait(20); }
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait(350);
}
async function startup(width=1280,height=720) {
  await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
  await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
  await call('Page.navigate',{url:'http://127.0.0.1:7361/'});
  for(let i=0;i<60;i++){await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");if((await texts()).includes('Altın:'))break;await wait(500);}
  await wait(2500);
}
try {
  await call('Runtime.enable'); await startup();
  await assertText('Altın: 10.000');await capture('new_game');
  await buy('Tarım');await assertText('Altın: 9.500');await assertText('Çay Tarlası envantere eklendi.');await capture('purchased_unplaced');
  await button('Paneli kapat');await capture('still_empty');
  await button('Envanter');await assertText('Adet: 1');await capture('inventory');
  await button('Yerleştir');await tile(3,9);await assertText('Başka bir yapıyla çakışıyor.');
  await tile(5,5);await button('Yerleştir');await assertText('Altın: 9.500');
  await button('Envanter');await assertText('Envanterin boş. Mağazadan bir yapı satın al.');await button('Paneli kapat');
  await buy('Tarım');await assertText('Altın: 9.000');
  await button('Envanter');await button('Yerleştir');await button('İptal');
  await button('Envanter');await assertText('Adet: 1');await capture('cancel_preserves_item');
  await button('Yerleştir');await tile(4,3);await button('Yerleştir');await assertText('Altın: 9.000');
  await buy('Lojistik');await assertText('Altın: 6.500');await assertText('Zaten sahip');await placeInventory(9,4);
  await buy('Üretim');await assertText('Altın: 2.500');await placeInventory(9,8);
  await click(640,185);await button('Çay Dik');await assertText('Altın: 2.250');
  await until('Durum: Hasada Hazır',24000);await button('Hasat Et');await until('Tarlada Bekleyen Yaş Çay: 25 kg',18000);
  await button('İşletme');await assertText('Toplam Yaş Çay');await assertText('Tarlalarda');await capture('business_field_stock');await button('Paneli kapat');
  await button('Taşıma Emri Ver');await until('Tarlada Bekleyen Yaş Çay: 0 kg',20000);
  await click(890,244);await until('Teslim Alınan Yaş Çay: 25 kg',20000);
  await button('Fabrikaya Sevk Et');await click(682,320);await until('Yaş Çay Stoğu: 25 kg',20000);
  await button('İşletme');await swipe(900,590,0,-160);await assertText('Fabrikada Yaş Çay');await capture('business_factory_stock');await button('Paneli kapat');
  await buy('Altyapı');await button('Satın Al');await assertText('Altın: 2.200');
  await button('Envanter');await button('Yerleştir');await tile(13,7);await tile(14,7);await button('Bitir');await assertText('Altın: 2.200');
  for(const [w,h] of [[960,540],[844,390]]) {
    await startup(w,h);await button('Mağaza');await button('Satın Al');await assertText('Altın: 9.500');await capture('shop_'+w);
    await button('Envanter');await assertText('Adet: 1');await capture('inventory_'+w);
    await button('Yerleştir');
    const before=await texts();await swipe(w*.7,h*.36,40,20);await assertText('Envanter: 1');await assertText('Altın: 9.500');
    await button('İptal');await button('İşletme');await capture('business_'+w);await button('Paneli kapat');
  }
  if(exceptions.length)throw Error(JSON.stringify(exceptions));
  console.log('Milestone 7 Chrome dokunmatik akışı: ayrı satın alma, envanter, iptal, gerçek tarla/işçi/nakliye/fabrika, kaynak özeti, stoktan yol ve üç yatay ekran doğrulandı.');
} catch(error){await capture('failure');throw error;}
finally{ws.close();}

