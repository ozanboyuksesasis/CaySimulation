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
 await wait(600);
 const rect=await evaluate(`(()=>{const a=[...document.querySelectorAll('[role=button]')].filter(e=>e.getAttribute('aria-label')===${JSON.stringify(label)}||e.innerText===${JSON.stringify(label)});const e=a[${index}];if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
 if(!rect)throw Error('Düğme yok: '+label+'\n'+await texts());await tap(rect.x,rect.y);
}
async function textTap(label) {
 const rect=await evaluate(`(()=>{const norm=s=>(s||'').replace(/\\s+/g,' ').trim();const e=[...document.querySelectorAll('flt-semantics')].find(e=>norm(e.getAttribute('aria-label'))===${JSON.stringify(label)}||norm(e.innerText)===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
 if(!rect)throw Error('Metin yok: '+label+'\n'+await texts());await tap(rect.x,rect.y);
}
async function assertText(value) {await until(value,3000);console.log('Doğrulandı: '+value);}
async function until(value,timeout=30000) {const end=Date.now()+timeout;while(Date.now()<end){if((await texts()).includes(value))return;await wait(250);}throw Error('Beklenen durum gelmedi: '+value+'\n'+await texts());}
async function capture(name) {await wait(600);const r=await call('Page.captureScreenshot',{format:'png'});writeFileSync(`m10_${name}.png`,Buffer.from(r.data,'base64'));}
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
 await call('Runtime.enable');if(!process.argv.includes('--resume-retail')){await startup();
 await assertText('Altın: 15.000');await button('Başlayalım');await assertText('Envanteri Aç');
 await build('Tarım',5.2,5.2);await assertText('Altın: 14.500');
 await button('Envanteri Aç');await button('İşe Al');await button('Paneli kapat');
 await button('Envanteri Aç');await button('Satın Al');await button('Paneli kapat');
 await button('Göster');await button('Ekipman');await textTap('Çay Makası Boşta: 1');
 await button('Göster');await button('Çay Dik');
 await until('Tarlada Bekleyen Yaş Çay: 25 kg');await capture('first_harvest');
 await button('Haritayı ortala');await build('Lojistik',9.2,4.2);
 await until('İlk çayını başarıyla teslim ettin!',40000);await assertText('Seviye 2 · 0/150 XP');await assertText('Altın: 10.500');
 await button('Devam Et');await assertText('İkinci işçini işe al');
 await button('Haritayı ortala');await build('Üretim',9.2,8.2);await assertText('Altın: 6.500');
 await button('Haritayı ortala');await build('Üretim',12.2,5.2);await assertText('Altın: 4.500');
 await button('Haritayı ortala');await build('Lojistik',6.2,3.2);await assertText('Altın: 3.000');
 await button('Haritayı ortala');await tap(807,226);await assertText('Çay Dükkânı');await capture('shop_empty');
 await until('Satılan: 1 paket',240000);await assertText('Altın: 3.150');await capture('first_customer_sale');
 await button('Geliştir');await assertText('Reyon Kapasitesi');await capture('shelf_upgrade');}
 await button('Geliştir');await wait(500);
 await assertText('15');await capture('upgraded_shelf');
 for(const [w,h] of [[960,540],[844,390]]) {
  await call('Emulation.setDeviceMetricsOverride',{width:w,height:h,deviceScaleFactor:1,mobile:false});await wait(1000);
  await capture('retail_'+w);await button('İşletme');await capture('business_'+w);await button('Paneli kapat');
 }
 if(exceptions.length)throw Error(JSON.stringify(exceptions));
 writeFileSync('m10-browser-observation.json',JSON.stringify({customerSale:true,firstSaleGold:3150,initialGold:15000,shelfUpgrade:true,sizes:[[1280,720],[960,540],[844,390]],exceptions},null,2));
 console.log('M10: gerçek öğretici → otomatik üretim/paketleme → müşteri satışı geçti.');
}catch(e){await capture('failure');throw e;}finally{ws.close();}
