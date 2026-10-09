import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import {playerPool,availableTeams} from '../pools.js';
const data=JSON.parse(fs.readFileSync(new URL('../data/rosters.json',import.meta.url)));
const tid=name=>Object.keys(data.teams).find(id=>data.teams[id].name===name);
const names=(d,t)=>playerPool(data,d,t).map(id=>data.players[id]);
test('real historical team/decade membership',()=>{const que=tid('Quebec Nordiques');assert.ok(names('1980',que).includes('Joe Sakic'));assert.ok(!names('1980',que).includes('Wayne Gretzky'));assert.ok(names('1990',tid('Colorado Avalanche')).includes('Joe Sakic'));assert.ok(!availableTeams(data,'1960').includes(que));});
test('all-decade player pool deduplicates careers and team trades',()=>{const ids=playerPool(data,'all','all');assert.equal(ids.length,new Set(ids).size);assert.ok(ids.length>8000);});
test('every pool has valid unique player IDs and full names',()=>{for(const group of Object.values(data.pools))for(const [t,ids] of Object.entries(group)){assert.ok(data.teams[t]);assert.ok(ids.length);assert.equal(ids.length,new Set(ids).size);assert.ok(ids.every(id=>data.players[id]?.includes(' ')));}});
test('current clubs exclude historical-only identities',()=>{assert.equal(availableTeams(data,'current').length,32);assert.ok(!availableTeams(data,'current').includes(tid('Quebec Nordiques')));});
