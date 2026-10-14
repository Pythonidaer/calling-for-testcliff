const {chromium,webkit}=require('playwright');
const assert=require('node:assert/strict');
(async()=>{for(const engine of [chromium,webkit]){
 const browser=await engine.launch({headless:true});const page=await browser.newPage({viewport:{width:390,height:844}});
 await page.route('**/data/rosters.json',route=>route.abort());await page.goto(process.env.QA_BASE_URL||'http://localhost:8000');
 await page.getByRole('button',{name:'Retry loading records'}).waitFor();assert(await page.locator('#start-screen').isVisible());assert.equal(await page.locator('.key:enabled').count(),0);
 await page.unroute('**/data/rosters.json');await page.getByRole('button',{name:'Retry loading records'}).click();await page.waitForFunction(()=>!document.getElementById('decade').disabled);
 await page.getByRole('button',{name:'Play',exact:true}).click();assert.equal(await page.locator('.key:enabled').count(),26);
 await page.getByRole('button',{name:'Guess A',exact:true}).click();assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled());
 await page.route('**/pools.js',route=>route.fulfill({contentType:'text/javascript',body:'export function playerPool() {}'}));await page.reload();
 await page.waitForFunction(()=>!document.getElementById('decade').disabled);await page.getByRole('button',{name:'Play',exact:true}).click();assert.equal(await page.locator('.key:enabled').count(),26);
 console.log(engine.name()+': failed load, retry, screen transition, versioned modules pass');await browser.close();
}})().catch(error=>{console.error(error);process.exit(1);});
