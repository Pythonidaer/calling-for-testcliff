import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
const args = existsSync('ios/App/App.xcodeproj') ? ['sync', 'ios'] : ['add', 'ios', '--packagemanager', 'SPM'];
const result = spawnSync('npx', ['--no-install', 'cap', ...args], { stdio: 'inherit' });
if (result.error) throw result.error;
process.exit(result.status ?? 1);
