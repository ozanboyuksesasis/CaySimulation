// Local validation helper for flutter build web; not part of the game.
import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';
const root = resolve('build/web');
const types = {'.html':'text/html', '.js':'application/javascript', '.json':'application/json',
  '.wasm':'application/wasm', '.png':'image/png', '.ttf':'font/ttf', '.otf':'font/otf'};
createServer(async (request,response) => {
  const path = resolve(root, '.' + decodeURIComponent(new URL(request.url, 'http://localhost').pathname));
  if (path !== root && !path.startsWith(root + sep)) { response.writeHead(403).end(); return; }
  const file = path === root ? resolve(root,'index.html') : path;
  try { const data = await readFile(file);
    response.writeHead(200, {'Content-Type':types[extname(file)] ?? 'application/octet-stream', 'Cache-Control':'no-store'}).end(data);
  } catch { response.writeHead(404).end(); }
}).listen(7361, '127.0.0.1', () => console.log('Web release: http://127.0.0.1:7361'));
