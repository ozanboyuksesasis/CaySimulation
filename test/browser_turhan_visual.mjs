// Development-only route observation; screenshots are not pixel assertions.
import {writeFileSync} from 'node:fs';
const pages=await(await fetch('http://127.0.0.1:7360/json')).json();
const page=pages.find(p=>p.type==='page'&&p.url.includes(':7361'));
const ws=new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r=>ws.addEventListener('open',r,{once:true}));
let seq=0;const pending=new Map(),errors=[];
ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){pending.get(m.id)?.(m);pending.delete(m.id);}if(m.method==='Runtime.exceptionThrown')errors.push(m.params);});
const call=(method,params={})=>new Promise((resolve,reject)=>{const id=++seq;const timer=setTimeout(()=>reject(Error(method)),15000);pending.set(id,m=>{clearTimeout(timer);m.error?reject(m.error):resolve(m.result);});ws.send(JSON.stringify({id,method,params}));});
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const evaluate=async expression=>(await call('Runtime.evaluate',{expression,returnByValue:true})).result.value;
const texts=()=>evaluate("document.body.innerText+'\\n'+[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join('\\n')");
async function tap(x,y){await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait(250);}
async function button(label){const r=await evaluate(`(()=>{const e=[...document.querySelectorAll('[role=button]')].find(e=>e.innerText===${JSON.stringify(label)}||e.getAttribute('aria-label')===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);if(!r)throw Error(label);await tap(r.x,r.y);}
async function capture(key){const shot=await call('Page.captureScreenshot',{format:'png'});writeFileSync(`turhan_${key}.png`,Buffer.from(shot.data,'base64'));}
async function until(value,timeout=30000){const end=Date.now()+timeout;while(Date.now()<end){if((await texts()).includes(value))return;await wait(100);}throw Error('Beklenen durum yok: '+value+'\n'+await texts());}
async function textTap(label){const r=await evaluate(`(()=>{const norm=s=>(s||'').replace(/\\s+/g,' ').trim();const e=[...document.querySelectorAll('flt-semantics')].find(e=>norm(e.innerText)===${JSON.stringify(label)}||norm(e.getAttribute('aria-label'))===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);if(!r)throw Error(label);await tap(r.x,r.y);}
try {
 await call('Runtime.enable');
 await call('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
 await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
 await call('Page.navigate',{url:'http://127.0.0.1:7361/?visualTest=turhan'});
 for(let i=0;i<100;i++){await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");if((await texts()).includes('Yön:'))break;await wait(300);}
 const seen=new Set();const end=Date.now()+45000;
 while(Date.now()<end&&seen.size<16){
   const match=(await texts()).match(/Yön: (SE|SW|NE|NW) • Görsel: (Yürüyor|Bekliyor) • Kare: (IDLE|A|B)/);
   if(match){const key=match[1]+'_'+(match[2]==='Yürüyor'?'walk':'idle')+'_'+match[3];if(!seen.has(key)){await capture(key);seen.add(key);console.log('Gözlendi: '+key);}}
   await wait(25);
 }
 for(const dir of ['SE','SW','NE','NW']) for(const suffix of ['walk_A','walk_IDLE','walk_B','idle_IDLE']){
   if(!seen.has(dir+'_'+suffix))throw Error('Eksik gözlem: '+dir+'_'+suffix);
 }
 // SW endpoint is a clear, unoccluded selection location at this camera zoom.
 for(let i=0;i<500;i++){if((await texts()).includes('Yön: SW • Görsel: Bekliyor'))break;await wait(30);}
 await button('Duraklat');await tap(230,332);await wait(300);
 if(!(await texts()).includes('Seçili: Turhan'))throw Error('Seçim başarısız');
 await capture('selection');
 await button('Yönlü kareleri aç/kapat');await wait(300);
 if(!(await texts()).includes('Yönlü kareler: Kapalı'))throw Error('Görsel kapatma başarısız');
 await capture('disabled');await button('Yönlü kareleri aç/kapat');await button('Devam Et');
 await button('Normal Oyuna Dön');await until('Başlayalım');await wait(6000);
 await button('Başlayalım');await button('Hedefi aç');await button('Envanteri Aç');await button('Kur');
 await tap(681.6,216.32);await button('Yerleştir');await until('Altın: 9.500');
 await button('Envanteri Aç');await button('İşe Al');await button('Paneli kapat');
 await button('Envanteri Aç');await button('Satın Al');await button('Paneli kapat');
 await button('Göster');await button('Ekipman');await wait(400);await textTap('Çay Makası Boşta: 1');
 await until('Ekipman: Çay Makası');await button('Göster');await button('Çay Dik');
 await until('Durum: Hasada Hazır');await button('Hasat Et');await wait(400);await capture('normal_harvest_walk');
 await until('Tarlada Bekleyen Yaş Çay: 25 kg');await until('Altın: 8.000');await capture('normal_harvest_done');
 if(errors.length)throw Error(JSON.stringify(errors));
 writeFileSync('turhan-browser-observation.json',JSON.stringify({observed:[...seen],selection:true,toggle:true,normalGameHarvestKg:25,normalGameGold:8000,exceptions:errors},null,2));
 console.log('Dört yön, üç yürüyüş pozu, dört duruş, seçim ve görsel aç/kapat gözlendi. Sanatsal kalite ayrıca incelenmelidir.');
}catch(e){await capture('failure');throw e;}finally{ws.close();}
