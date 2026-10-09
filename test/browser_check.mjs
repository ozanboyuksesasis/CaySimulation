// Optional local Chrome smoke capture: node --experimental-websocket test/browser_check.mjs PORT
import { writeFileSync } from 'node:fs';
const pages = await (await fetch(`http://127.0.0.1:${process.argv[2]}/json`)).json();
const page = pages.find(p => p.type === 'page' && p.url.includes('localhost:'));
if (!page) throw Error('Oyun sekmesi bulunamadı');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, {once: true}));
let id = 0;
const pending = new Map();
ws.addEventListener('message', event => {
  const data = JSON.parse(event.data);
  if (data.id) { pending.get(data.id)?.(data); pending.delete(data.id); }
  else if (data.method === 'Runtime.exceptionThrown') console.error(JSON.stringify(data.params));
});
function call(method, params = {}) {
  return new Promise((resolve, reject) => {
    const next = ++id;
    const timer = setTimeout(() => reject(Error(`Timeout: ${method}`)), 15000);
    pending.set(next, data => { clearTimeout(timer); data.error ? reject(data.error) : resolve(data.result); });
    ws.send(JSON.stringify({id: next, method, params}));
  });
}
await call('Runtime.enable');
await call('Emulation.setDeviceMetricsOverride', {width: 1280, height: 720, deviceScaleFactor: 1, mobile: false});
await new Promise(resolve => setTimeout(resolve, 1500));
// Reset to the same starting view before capturing.
await call('Input.dispatchMouseEvent', {type: 'mousePressed', x: 1188, y: 674, button: 'left', clickCount: 1});
await call('Input.dispatchMouseEvent', {type: 'mouseReleased', x: 1188, y: 674, button: 'left', clickCount: 1});
await new Promise(resolve => setTimeout(resolve, 300));
const screenshot = await call('Page.captureScreenshot', {format: 'png'});
writeFileSync('preview.png', Buffer.from(screenshot.data, 'base64'));
console.log('preview.png kaydedildi');
ws.close();
