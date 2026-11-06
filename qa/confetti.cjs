const {chromium,webkit}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
(async()=>{
 const data=JSON.parse(fs.readFileSync('data/rosters.json','utf8'));
 const {playerPool}=await import('../pools.js');const {normalize}=await import('../game.js');
 const id=Object.keys(data.teams).find(id=>data.teams[id].name==='Boston Bruins');
 const letters=[...new Set(normalize(data.players[playerPool(data,'current',id)[0]]).replace(/[^A-Z]/g,''))];
 const wrong=[...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'].find(letter=>!letters.includes(letter));
 for(const engine of [chromium,webkit]){
  const browser=await engine.launch();const page=await browser.newPage({viewport:{width:390,height:844}});
  await page.addInitScript(()=>{Math.random=()=>0;});await page.emulateMedia({reducedMotion:'no-preference'});
  await page.goto(process.env.QA_BASE_URL||'http://localhost:8000');await page.waitForFunction(()=>!document.querySelector('#decade').disabled);
  const start=async()=>{await page.reload();await page.waitForFunction(()=>!document.querySelector('#decade').disabled);await page.locator('#decade').selectOption('current');await page.locator('#team').selectOption('all');await page.locator('#team').selectOption(id);await page.locator('#play').click();};
  const win=async()=>{for(const letter of letters)await page.getByRole('button',{name:'Guess '+letter,exact:true}).click();assert.equal(await page.locator('#result-title').innerText(),'GOAL');};
  const home=async()=>{await page.getByRole('button',{name:'Open menu',exact:true}).click();await page.locator('#exit-home').click();};
  assert.equal(await page.locator('#test-confetti').count(),0);
  await start();await win();
  await page.waitForFunction(()=>{const c=document.querySelector('#confetti-celebration');return c&&c.width>0&&c.getContext('2d').getImageData(0,0,c.width,c.height).data.some((v,i)=>i%4===3&&v>0);});
  await page.locator('#menu-toggle').click();assert.equal(await page.locator('#confetti-celebration').count(),0);await page.locator('#menu-toggle').click();assert.equal(await page.locator('#confetti-celebration').count(),0,'Returning must not replay celebration');await home();
  await start();await page.getByRole('button',{name:'Guess '+wrong,exact:true}).click();await win();assert.equal(await page.locator('#confetti-celebration').count(),0,'A win with a miss must not celebrate');await home();
  await start();await page.locator('#skip').click();assert.equal(await page.locator('#result-title').innerText(),'Game Over');assert.equal(await page.locator('#confetti-celebration').count(),0);await home();
  await page.emulateMedia({reducedMotion:'reduce'});await start();await win();assert.equal(await page.locator('#confetti-celebration').count(),0,'Reduced motion must suppress confetti');
  console.log(engine.name()+': perfect win, imperfect win, give up, menu cleanup, no replay, reduced motion pass');await browser.close();
 }
})().catch(error=>{console.error(error);process.exit(1);});
