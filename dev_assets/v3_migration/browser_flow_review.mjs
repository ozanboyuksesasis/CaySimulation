// Reuse the real-touch M7 regression without changing its original test.
import {readFileSync} from 'node:fs';
let source=readFileSync('test/browser_milestone7.mjs','utf8');
source=source.replaceAll('milestone7_', 'dev_assets/v3_migration/web_flow_');
source=source.replace("await until('Durum: Hasada Hazır',24000);", "await capture('field_planted'); await until('Durum: Büyüyor — 1. aşama',8000); await capture('field_growing_1'); await until('Durum: Büyüyor — 2. aşama',8000); await capture('field_growing_2'); await until('Durum: Hasada Hazır',12000); await capture('field_ready');");
source=source.replace("await until('Tarlada Bekleyen Yaş Çay: 25 kg',18000);", "await until('Tarlada Bekleyen Yaş Çay: 25 kg',18000); await capture('field_harvested_sack');");
source=source.replace("await until('Tarlada Bekleyen Yaş Çay: 0 kg',20000);", "await until('Tarlada Bekleyen Yaş Çay: 0 kg',20000); await capture('field_regenerating');");
await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
