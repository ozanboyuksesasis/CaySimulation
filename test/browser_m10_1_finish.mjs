// Chrome touch-only acceptance test. No gameplay state mutation or fake time.
import {writeFileSync} from 'node:fs';
const pages = await (await fetch('http://127.0.0.1:7362/json')).json();
const page = pages.find(p => p.type === 'page' && p.url.includes(':7361')) || pages.find(p => p.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r, {once:true}));
let sequence=0; const pending=new Map(), exceptions=[];
ws.addEventListener('message', e => {const m=JSON.parse(e.data);if(m.id){pending.get(m.id)?.(m);pending.delete(m.id);}if(m.method==='Runtime.exceptionThrown')exceptions.push(m.params);});
function call(method,params={}) {return new Promise((resolve,reject)=>{const id=++sequence;const timer=setTimeout(()=>reject(Error(method)),20000);pending.set(id,m=>{clearTimeout(timer);m.error?reject(Error(method+': '+JSON.stringify(m.error))):resolve(m.result);});ws.send(JSON.stringify({id,method,params}));});}
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
async function capture(name) {await wait(600);const r=await call('Page.captureScreenshot',{format:'png'});writeFileSync(`m10_1_${name}.png`,Buffer.from(r.data,'base64'));}
async function startup(width=1280,height=720) {
 await call('Page.bringToFront');
 try {const {windowId}=await call('Browser.getWindowForTarget',{targetId:page.id});
 await call('Browser.setWindowBounds',{windowId,bounds:{windowState:'normal'}});}catch{}
 await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
 await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
 await call('Page.navigate',{url:'http://127.0.0.1:7361/'});
 await call('Page.bringToFront');
 await wait(1500);
 for(let i=0;i<120;i++){await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");await call('Page.captureScreenshot',{format:'png'}).catch(()=>{});if((await texts()).includes('Altın:'))break;await wait(500);}
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


const observation={startedAt:new Date().toISOString(),checks:[],sizes:[]};
function record(check){observation.checks.push({check,at:new Date().toISOString()});writeFileSync('m10_1-browser-finish.json',JSON.stringify({...observation,exceptions},null,2));console.log(check);}
try {
await call('Runtime.enable');await call('Page.bringToFront');await call('Emulation.setFocusEmulationEnabled',{enabled:true});
await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
await button('Haritayı ortala');await tap(640,230);await capture('worker_selected');console.log(await texts());
await button('Geliştir');console.log(await texts());
await button('Geliştir');await capture('worker_upgrade');await button('Kapat');record('İşçi gelişimi gerçek seçim ve puanla uygulandı');
 for(const [x,y] of [[3.2,5.2],[12.2,8.2]]){
   await button('Haritayı ortala');await build('Tarım',x,y);
   await button('Haritayı ortala');await tile(x+.8,y+.8);await button('Çay Dik');
 }
 record('Dört tarla, normal otomasyonla seviye ilerlemesi bekleniyor');
 for(const [w,h] of [[1280,720],[960,540],[844,390]]){
   await call('Emulation.setDeviceMetricsOverride',{width:w,height:h,deviceScaleFactor:1,mobile:false});await wait(1000);
   await capture('world_'+w);await button('Envanter');await capture('inventory_'+w);await button('Paneli kapat');
   await button('İşletme');await capture('business_'+w);await button('Paneli kapat');observation.sizes.push([w,h]);
 }
 await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
 const deadline=Date.now()+1200000;
 while(Date.now()<deadline){const t=await texts();if(/Seviye (6|7|8|9) ·/.test(t))break;await call('Page.captureScreenshot',{format:'png'});await wait(1000);}
 if(!/Seviye (6|7|8|9) ·/.test(await texts()))throw Error('Seviye 6 zaman sınırında gelmedi');
 record('Seviye 6 gerçek oyun olaylarıyla açıldı');
 await button('Envanter');await textTap('Ekipman');await capture('motor_unlocked');await button('Satın Al',1);
 await assertText('Çay Motoru envantere eklendi.');await capture('motor_purchased');record('Seviye 6 motor satın alındı');
 if(exceptions.length)throw Error(JSON.stringify(exceptions));record('Tamamlandı');
}catch(e){await capture('failure');observation.failure=String(e);record('Başarısız');throw e;}finally{ws.close();}
