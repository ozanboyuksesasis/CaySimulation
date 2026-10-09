// Real Chrome input and elapsed time; never mutates gameplay state.
// node --experimental-websocket test/browser_milestone6.mjs 7360
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
  await call('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});
  await call('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});
  await wait(150);
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
  writeFileSync(`milestone6_${name}.png`,Buffer.from(r.data,'base64'));
}
async function until(value,timeout=20000) {
  const end=Date.now()+timeout;
  while(Date.now()<end){if((await texts()).includes(value)){console.log('Doğrulandı: '+value);return;}await wait(150);}
  throw Error('Beklenen durum gelmedi: '+value+'\n'+await texts());
}
async function choose(category,name) {
  // M7 separates purchase from placement; retain the M6 world regression scenario.
  await button('Mağaza'); await textClick(category); await button('Satın Al');
  if(name==='Toprak Yol') await button('Satın Al');
  await button('Envanter'); await button('Yerleştir');
}
async function tile(x,y) { await click(640+(x-y)*41.6,-47.68+(x+y)*20.8); }
try {
  await call('Runtime.enable');
  await call('Page.navigate',{url:'http://127.0.0.1:7361/'});
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
  for(let i=0;i<60;i++){
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if((await texts()).includes('Altın:'))break;
    await wait(500);
  }
  await wait(3000); await assertText('Altın: 10.000'); await capture('new_game');
  await choose('Tarım','Çay Tarlası'); await tile(3,9);
  await assertText('Başka bir yapıyla çakışıyor.'); await capture('invalid');
  await button('Yerleştir'); await assertText('Altın: 9.500');
  await tile(5,5); await assertText('Yerleştirmeye uygun.'); await capture('valid');
  await call('Input.dispatchMouseEvent',{type:'mouseMoved',x:720,y:530});
  await assertText('Yerleştirmeye uygun.');
  await button('Yerleştir'); await assertText('Altın: 9.500');
  await choose('Tarım','Çay Tarlası'); await tile(4,3); await button('Yerleştir');
  await assertText('Altın: 9.000'); await capture('two_fields');
  await click(640,185); await button('Çay Dik'); await assertText('Altın: 8.750');
  await until('Durum: Hasada Hazır',23000); await button('Hasat Et');
  await button('Taşı'); await assertText('Bu nesne şu anda taşınamaz.');
  await until('Tarlada Bekleyen Yaş Çay: 25 kg',18000);
  await assertText('Çay Alım Yeri gerekli.'); await capture('dynamic_harvest');
  await button('Taşı'); await tile(2,2); await button('Vazgeç');
  await assertText('Tarlada Bekleyen Yaş Çay: 25 kg'); await assertText('Altın: 8.750');
  await button('Taşı'); await tile(4,5); await button('Onayla');
  await assertText('Tarlada Bekleyen Yaş Çay: 25 kg'); await assertText('Altın: 8.750');
  await capture('moved_with_stock');
  await choose('Lojistik','Çay Alım Yeri'); await tile(9,4); await button('Yerleştir');
  await assertText('Altın: 6.250');
  await click(890,244); await assertText('Çay Fabrikası gerekli.'); await capture('collection_built');
  await choose('Üretim','Çay Fabrikası'); await tile(9,8); await button('Yerleştir');
  await assertText('Altın: 2.250');
  await click(598,164); await assertText('Tarlada Bekleyen Yaş Çay: 25 kg');
  await button('Taşıma Emri Ver');
  await until('Tarlada Bekleyen Yaş Çay: 0 kg',20000);
  await click(890,244); await until('Teslim Alınan Yaş Çay: 25 kg',20000);
  await capture('dynamic_delivery'); await button('Fabrikaya Sevk Et');
  await click(682,320); await assertText('Çay Fabrikası');
  await until('Yaş Çay Stoğu: 25 kg',20000);
  await assertText('Üretim için 75 kg daha yaş çay gerekiyor.');
  await assertText('Altın: 2.250'); await capture('dynamic_factory');
  await choose('Altyapı','Toprak Yol'); await tile(13,7); await tile(14,7);
  await assertText('Altın: 2.200'); await button('Bitir');
  await capture('roads');
  if(exceptions.length)throw Error(JSON.stringify(exceptions));
  console.log('Milestone 6 Chrome: yeni oyun, iki tarla, geçersiz/geçerli önizleme, satın alma, gerçek hasat, güvenli taşıma/iptal, dinamik alım yeri/fabrika, gerçek kamyon teslimatları ve tekrarlı yol yapımı doğrulandı.');
} catch(error){await capture('failure');throw error;}
finally{ws.close();}
