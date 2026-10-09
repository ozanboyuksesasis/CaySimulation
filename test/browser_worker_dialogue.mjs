// Chrome touch-only acceptance test. No gameplay state mutation or fake time.
import {writeFileSync} from 'node:fs';
const pages = await (await fetch('http://127.0.0.1:7364/json')).json();
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
async function capture(name) {await wait(600);const r=await call('Page.captureScreenshot',{format:'png'});writeFileSync(`dev_assets/m11_1_1/${name}.png`,Buffer.from(r.data,'base64'));}
async function startup(width=1280,height=720) {
 await call('Page.bringToFront');
 await call('Emulation.setFocusEmulationEnabled',{enabled:true});
 try {const {windowId}=await call('Browser.getWindowForTarget',{targetId:page.id});
 await call('Browser.setWindowBounds',{windowId,bounds:{windowState:'normal'}});}catch{}
 await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
 await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
 await call('Page.navigate',{url:'http://127.0.0.1:7361/?visualTest=dialogue'});
 await call('Page.bringToFront');
 await wait(1500);
 for(let i=0;i<120;i++){await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");await call('Page.captureScreenshot',{format:'png'}).catch(()=>{});if((await texts()).includes('Konuşma bekleniyor'))break;await wait(500);}
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





const evidence={checks:[],natural:[],exceptions};
function record(s){console.log(s);evidence.checks.push(s);writeFileSync('dev_assets/m11_1_1/browser_observation.json',JSON.stringify(evidence,null,2));}
try {
 await call('Runtime.enable');await startup();
 const start=Date.now();let previous='';
 while(Date.now()-start<70000) {
   const t=await texts();const speech=t.split('\n').find(s=>/^(Turhan|Havva):/.test(s));
   if(speech && speech!==previous){previous=speech;evidence.natural.push({seconds:(Date.now()-start)/1000,text:speech});record('Doğal: '+speech);await capture('natural_'+evidence.natural.length);}
   await wait(200);
 }
 if(!evidence.natural.some(s=>s.text.startsWith('Turhan:'))||!evidence.natural.some(s=>s.text.startsWith('Havva:')))throw Error('İki işçi de doğal konuşmalı');
 for(const [mode,phrase] of [['Turhan','Bu sevdaluk yedi beni!'],['Havva','Bugün çay topliyamam çişelidur çişeli!'],['Yakında','Havva bunu Turhan desein!'],['Yürüyüş','Haydin çayluğa!'],['Hasat','Bezdum da!']]){
  await button(mode);await until(phrase,10000);await button('Duraklat');
  const paused=await texts();await wait(800);if(!(await texts()).includes(phrase))throw Error('Duraklatılan konuşma kayboldu');
  for(const [width,height] of [[844,390],[960,540],[1280,720]]){
   await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});await capture(mode+'_'+width);
  }
  record(mode+': bağlam, duraklatma ve üç ekran boyutu');
 }
 await button('Uzak');await assertText('Konuşma bekleniyor');await capture('far_zoom');
 await button('Normal');await button('Havva');await until('Bugün çay topliyamam',5000);await button('Yakın');await capture('close_zoom');
 await button('Konuşmalar: Açık');await assertText('Konuşma bekleniyor');record('Uzak zoom ve kapatma baloncuğu kaldırıyor');
 if(exceptions.length)throw Error(JSON.stringify(exceptions));record('Konuşma görsel doğrulaması tamamlandı');
}catch(e){record(String(e));await capture('failure');throw e;}finally{ws.close();}
