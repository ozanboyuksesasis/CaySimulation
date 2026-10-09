import {readFileSync} from 'node:fs';
const source=readFileSync('dev_assets/v2_migration/browser_visual_review.mjs','utf8')
  .replaceAll('dev_assets/v2_migration/web_', 'dev_assets/v3_migration/web_');
await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
