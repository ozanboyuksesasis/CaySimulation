// Read-only Chrome visual review, with real touches for shop/inventory navigation.
import {writeFileSync} from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && p.url.includes(':7361'));
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, {once:true}));
let sequence=0;
const pending=new Map(), errors=[];
ws.addEventListener('message', e => {
  const m=JSON.parse(e.data);
  if(m.id){pending.get(m.id)?.(m);pending.delete(m.id);}
  if(m.method==='Runtime.exceptionThrown')errors.push(m.params);
});
const call=(method,params={})=>new Promise((resolve,reject)=>{
  const id=++sequence;
  const timer=setTimeout(()=>reject(Error(method)),15000);
  pending.set(id,m=>{clearTimeout(timer);m.error?reject(m.error):resolve(m.result);});
  ws.send(JSON.stringify({id,method,params}));
});
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const evaluate=async expression=>(await call('Runtime.evaluate',{expression,returnByValue:true})).result.value;
async function tapLabel(label){
  const selector=label==='Satın Al'?'[role=button]':'flt-semantics';
  const rect=await evaluate(`(()=>{const e=[...document.querySelectorAll(${JSON.stringify(selector)})].find(e=>e.getAttribute('aria-label')===${JSON.stringify(label)}||e.innerText===${JSON.stringify(label)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
  if(!rect)throw Error(label);
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[rect]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(250);
}
async function capture(name){
  await wait(700);
  const r=await call('Page.captureScreenshot',{format:'png'});
  writeFileSync(`dev_assets/v2_migration/web_${name}.png`,Buffer.from(r.data,'base64'));
}
async function open(width,height,dev=false){
  await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
  await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});
  await call('Page.navigate',{url:'http://127.0.0.1:7361/'+(dev?'?map=dev':'')});
  for(let i=0;i<60;i++){
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    if(await evaluate("(document.body.innerText+[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join(' ')).includes('Altın:')"))break;
    await wait(500);
  }
  await wait(6500);
}
try{
  await call('Runtime.enable');
  for(const [w,h] of [[1280,720],[960,540],[844,390]]){
    await open(w,h);await capture('new_game_'+w);
    await tapLabel('Mağaza');await tapLabel('Lojistik');await capture('shop_logistics_'+w);
    await tapLabel('Satın Al');await tapLabel('Envanter');
    if(!await evaluate("(document.body.innerText+[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).join(' ')).includes('Adet: 1')"))throw Error('Envanter kontrolü');
    await capture('inventory_center_'+w);
    await tapLabel('Mağaza');await tapLabel('Üretim');await capture('shop_factory_'+w);
    await open(w,h,true);await capture('dev_map_'+w);
    console.log('Görsel inceleme: '+w+'×'+h);
  }
  await open(1280,720);
  if(errors.length)throw Error(JSON.stringify(errors));
}finally{ws.close();}
