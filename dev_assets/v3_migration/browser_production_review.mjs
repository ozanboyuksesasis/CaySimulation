import {readFileSync} from 'node:fs';
const source=readFileSync('dev_assets/v2_migration/browser_production_review.mjs','utf8')
  .replaceAll('milestone5_', 'dev_assets/v3_migration/web_production_');
await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
