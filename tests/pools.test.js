import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import {playerPool,availableTeams,playerDetails} from '../pools.js';
const data=JSON.parse(fs.readFileSync(new URL('../data/rosters.json',import.meta.url)));
const tid=name=>Object.keys(data.teams).find(id=>data.teams[id].name===name);
const names=(d,t)=>playerPool(data,d,t).map(id=>data.players[id]);
test('real historical team/decade membership',()=>{const que=tid('Quebec Nordiques');assert.ok(names('1980',que).includes('Joe Sakic'));assert.ok(!names('1980',que).includes('Wayne Gretzky'));assert.ok(names('1990',tid('Colorado Avalanche')).includes('Joe Sakic'));assert.ok(!availableTeams(data,'1960').includes(que));});
test('all-decade player pool deduplicates careers and team trades',()=>{const ids=playerPool(data,'all','all');assert.equal(ids.length,new Set(ids).size);assert.ok(ids.length>8000);});
test('every pool has valid unique player IDs and full names',()=>{for(const group of Object.values(data.pools))for(const [t,ids] of Object.entries(group)){assert.ok(data.teams[t]);assert.ok(ids.length);assert.equal(ids.length,new Set(ids).size);assert.ok(ids.every(id=>data.players[id]?.includes(' ')));}});
test('current clubs exclude historical-only identities',()=>{assert.equal(availableTeams(data,'current').length,32);assert.ok(!availableTeams(data,'current').includes(tid('Quebec Nordiques')));});

test('loss card uses selected historical team and position',()=>{const id=Object.keys(data.players).find(id=>data.players[id]==='Joe Sakic');const card=playerDetails(data,id,'1980',tid('Quebec Nordiques'));assert.deepEqual(card,[{team:'Quebec Nordiques',positions:['Center']}]);assert.deepEqual(playerDetails(data,id,'1980',tid('Boston Bruins')),[]);});
test('current goalie card has current team and goalie position',()=>{const id=Object.keys(data.players).find(id=>data.players[id]==='Jeremy Swayman');assert.deepEqual(playerDetails(data,id,'current',tid('Boston Bruins')),[{team:'Boston Bruins',positions:['Goalie']}]);});
test('all recorded pool memberships have valid positions',()=>{for(const [d,groups]of Object.entries(data.pools))for(const [t,ids]of Object.entries(groups))for(const id of ids){assert.ok(data.positions[d][t][id].length);assert.ok(data.positions[d][t][id].every(p=>['C','L','R','D','G'].includes(p)));}});
