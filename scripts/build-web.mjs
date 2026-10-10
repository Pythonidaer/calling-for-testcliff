import { cp, mkdir, rm } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const output = join(root, 'dist');
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const asset of ['index.html', 'styles.css', 'bootstrap.js', 'app.js', 'game.js', 'pools.js', 'icon.svg', 'data']) {
  await cp(join(root, asset), join(output, asset), { recursive: true });
}
console.log('Bundled game and roster snapshot into dist/.');
