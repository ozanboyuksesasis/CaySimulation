// Chrome touch-only acceptance test. No gameplay state mutation or fake time.
import {writeFileSync} from 'node:fs';
const pages = await (await fetch('http://127.0.0.1:7360/json')).json();
const page = pages.find(p => p.type === 'page' && p.url.includes(':7361'));
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r, {once:true}));
let sequence=0; const pending=new Map(), exceptions=[];
ws.addEventListener('message', e => {const m=JSON.parse(e.data);if(m.id){pending.get(m.id)?.(m);pending.delete(m.id);}if(m.method==='Runtime.exceptionThrown')exceptions.push(m.params);});
function call(method,params={}) {return new Promise((resolve,reject)=>{const id=++sequence;const timer=setTimeout(()=>reject(Error(method)),20000);pending.set(id,m=>{clearTimeout(timer);m.error?reject(m.error):resolve(m.result);});ws.send(JSON.stringify({id,method,params}));});}
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const evaluate=async expression=>(await call('Runtime.evaluate',{expression,returnByValue:true})).result.value;
const texts=()=>evaluate("document.body.innerText+'\\n'+[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join('\\n')");
async function tap(x,y) {await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait(220);}
async function button(label, index=0) {
 const rect=await evaluate(`(()=>{const a=[...document.querySelectorAll('[role=button]')].filter(e=>e.getAttribute('aria-label')===${JSON.stringify(label)}||e.innerText===${JSON.stringify(label)});const e=a[${index}];if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
 if(!rect)throw Error('Düğme yok: '+label+'\n'+await texts());await tap(rect.x,rect.y);
}
async function textTap(label) {
 const rect=await evaluate(`(()=>{const norm=s=>(s||'').replace(/\\s+/g,' ').trim();const e=[...document.querySelectorAll('flt-semantics')].find(e=>norm(e.getAttribute('aria-label'))===${JSON.stringify(label)}||norm(e.innerText)===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
 if(!rect)throw Error('Metin yok: '+label+'\n'+await texts());await tap(rect.x,rect.y);
}
async function assertText(value) {await until(value,3000);console.log('Doğrulandı: '+value);}
async function until(value,timeout=30000) {const end=Date.now()+timeout;while(Date.now()<end){if((await texts()).includes(value))return;await wait(250);}throw Error('Beklenen durum gelmedi: '+value+'\n'+await texts());}
async function capture(name) {await wait(600);const r=await call('Page.captureScreenshot',{format:'png'});writeFileSync(`guided_${name}.png`,Buffer.from(r.data,'base64'));}
async function startup(width=1280,height=720) {
 await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
 await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
 await call('Page.navigate',{url:'http://127.0.0.1:7361/'});
 for(let i=0;i<60;i++){await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");if((await texts()).includes('Altın:'))break;await wait(500);}
 for(let i=0;i<60;i++){if(!await evaluate("!!document.querySelector('[role=progressbar]')"))break;await wait(500);}await wait(4000);
}
async function tile(x,y) {await tap(681.6+(x-y)*41.6,(x+y)*20.8);}
async function build(category,x,y) {
 await button('Envanter');await textTap(category);await button('Kur');
 // Placement retains camera controls; reset to the known initial projection.
 await tile(x,y);await button('Yerleştir');
}
async function selectField() {await button('Haritayı ortala');await tap(681,241);}
async function selectCenter() {await button('Haritayı ortala');await tap(931,300);}
async function selectFactory() {await button('Haritayı ortala');await tap(723,376);}

async function guide() {if((await texts()).includes('Hedefi aç'))await button('Hedefi aç');}
async function hold(x,y) {
 await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});await wait(600);
 await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x+25,y:y+10}]});await wait(100);
 await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait(300);
}
try {
 await call('Runtime.enable');await startup();
 if (process.argv.includes('--rewards-only')) {
 await button('Başlayalım');await assertText('Envanteri Aç');
 await build('Tarım',5.2,5.2);await assertText('İlk tarla kuruldu: +20 XP');
 await button('Envanteri Aç');await button('İşe Al');await button('Paneli kapat');
 await assertText('İlk işçi işe alındı: +10 XP');await capture('hire_xp');
 await button('Envanteri Aç');await button('Satın Al');await button('Paneli kapat');
 await assertText('Çay Makası alındı: +10 XP');await capture('equipment_xp');
 } else if (!process.argv.includes('--layouts-only')) {
 await assertText('Altın: 10.000');await capture('welcome');await button('Başlayalım');
 await build('Tarım',5.2,5.2);await assertText('Altın: 9.500');
 await button('Envanter');await textTap('İşçiler');await button('İşe Al');await button('Paneli kapat');
 await button('Envanter');await textTap('Ekipman');await button('Satın Al');await button('Paneli kapat');
 await guide();await button('Göster');await button('Ekipman');await wait(400);
 await textTap('Çay Makası Boşta: 1');await assertText('Ekipman: Çay Makası');
 await button('Göster');await button('Çay Dik');await capture('growth');

 if((await texts()).includes('Hasat Et'))throw Error('Normal UI has manual harvest button');
 await until('tarlaya geliyor',25000);await capture('automatic_worker_walk');
 await until('Tarlada Bekleyen Yaş Çay: 25 kg');await capture('automatic_stock');
 await assertText('Seviye 1 · 75/100 XP');
 await button('Haritayı ortala');await build('Lojistik',9.2,4.2);await assertText('Altın: 5.500');
 await selectField();
 if((await texts()).includes('Taşıma Emri Ver'))throw Error('Normal UI has manual transport button');
 await capture('automatic_transport');
 await until('Seviye 2! Havva açıldı.',40000);await capture('havva_unlocked');
 await assertText('Seviye 2 · 0/150 XP');
 await button('Envanteri Aç');await button('İşe Al');await button('Paneli kapat');
 await assertText('Altın: 4.500');
 await button('Envanteri Aç');await button('Satın Al');await button('Paneli kapat');
 await button('Göster');await button('Ekipman');await textTap('Çay Makası Boşta: 1');
 await until('İlk çayını başarıyla teslim ettin!');await capture('two_workers_ready');
 await assertText('Altın: 4.250');await button('Devam Et');await assertText('SIRADAKİ HEDEF');
 await button('Haritayı ortala');await build('Üretim',9.2,8.2);await assertText('Altın: 250');
 await selectFactory();
 if((await texts()).includes('Üretimi Başlat'))throw Error('Normal UI has manual production button');
 await until('Durum: Üretim Yapılıyor',180000);await capture('automatic_factory_processing');
 await until('Kuru Çay Stoğu: 20 kg',16000);await capture('automatic_factory_output');
 await assertText('Altın: 250');await until('Seviye 2',4000);
 await button('Envanter');await textTap('Ekipman');await assertText("Seviye 6'da açılır");await capture('motor_locked');await button('Paneli kapat');
 console.log('Physical factory shipment and production completed without any manual work commands.');

 }
 if(!process.argv.includes('--rewards-only')) for(const [w,h] of [[1280,720],[960,540],[844,390]]) {
  await startup(w,h);await capture('welcome_'+w);await button('Başlayalım');await assertText('Envanteri Aç');
  await button('Envanter');await capture('inventory_'+w);await button('Kur');await assertText('Altın: 10.000');await button('İptal');
  const baseY=Math.min(h/2-312,0);
  await button('Envanter');await button('Kur');await tap(w/2+41.6,baseY+216.32);await button('Yerleştir');await assertText('Altın: 9.500');
  await tap(w/2+41.6,baseY+241);await capture('selection_'+w);
  await hold(w/2+41.6,baseY+241);if((await texts()).includes('Onayla'))throw Error('Tutorial allowed move outside current step');await capture('move_locked_'+w);await assertText('Altın: 9.500');
  // Touch pan and pinch never confirm placement.
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:w*.55,y:h*.55}]});
  for(let n=1;n<=4;n++){await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:w*.55+15*n,y:h*.55}]});await wait(40);}
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait(600);
  if((await texts()).includes('Onayla'))throw Error('Pan taşıma modunu açtı');
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:1,x:w*.5,y:h*.52},{id:2,x:w*.7,y:h*.52}]});
  for(let n=1;n<=4;n++){await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{id:1,x:w*.5-12*n,y:h*.52},{id:2,x:w*.7+12*n,y:h*.52}]});await wait(40);}
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await capture('pinch_'+w);
  await button('Envanter');await textTap('İşçiler');await capture('workers_'+w);await button('İşletme');await capture('business_'+w);
 }
 if(exceptions.length)throw Error(JSON.stringify(exceptions));
 const result=process.argv.includes('--rewards-only')
   ? {sizes:[[1280,720]],xpFeedback:true,exceptions}
   : {sizes:[[1280,720],[960,540],[844,390]],tutorialMoveLocked:true,pan:true,pinch:true,exceptions};
 if(!process.argv.includes('--layouts-only')&&!process.argv.includes('--rewards-only'))Object.assign(result,{guidedSecondWorker:true,optionalFactoryOutputKg:20});
 writeFileSync(process.argv.includes('--rewards-only')?'guided-rewards-observation.json':process.argv.includes('--layouts-only')?'guided-layout-observation.json':'guided-browser-observation.json',JSON.stringify(result,null,2));
 console.log('Dokunmatik öğretici doğrulaması geçti.');
} catch(e) {await capture('failure');throw e;} finally {ws.close();}
