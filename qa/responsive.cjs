const {chromium,webkit}=require('playwright');
const assert=require('node:assert/strict');
const url=process.env.QA_BASE_URL||'http://localhost:8000';
(async()=>{for(const engine of [chromium,webkit]){
 const browser=await engine.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(url);await page.waitForFunction(()=>!document.getElementById('play').disabled);
 for(const width of [768,900,1024,1440,1920]){
  await page.setViewportSize({width,height:900});
  assert(await page.locator('.desktop-nav').isVisible());assert(!(await page.locator('#menu-toggle').isVisible()));
  assert(await page.locator('.shell').evaluate(el=>el.getBoundingClientRect().width>=innerWidth-1),'Desktop shell still phone width');
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Header or home overflows at '+width);
  assert(await page.locator('.home-controls').evaluate(el=>el.getBoundingClientRect().left>document.querySelector('.scoreboard').getBoundingClientRect().right),'Desktop home needs two columns');
 }
 await page.setViewportSize({width:1440,height:900});await page.screenshot({path:engine.name()+'-desktop-start-preview.png',fullPage:true});
 await page.locator('.desktop-nav [data-nav="rules"]').click();assert(await page.locator('#rules-screen').isVisible());
 assert.equal(await page.locator('.desktop-nav [data-nav="rules"]').getAttribute('aria-current'),'page');
 await page.locator('.desktop-nav [data-nav="rosters"]').click();assert(await page.locator('#rosters-screen').isVisible());
 await page.locator('.desktop-nav [data-nav="menu"]').click();assert(await page.locator('#start-screen').isVisible(),'Close menu must return home');
 await page.locator('#play').click();await page.getByRole('button',{name:'Guess A',exact:true}).click();
 await page.locator('.desktop-nav [data-nav="rules"]').click();await page.locator('.desktop-nav [data-nav="menu"]').click();
 assert(await page.locator('#game-screen').isVisible());assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled(),'Navigation lost in-progress guess');
 for(const [width,height] of [[1024,768],[1440,900],[1920,1080]]){
  await page.setViewportSize({width,height});
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth&&document.documentElement.scrollHeight<=innerHeight+1),'Desktop game overflow '+width);
  assert(await page.locator('#keyboard').evaluate(el=>el.getBoundingClientRect().left>document.querySelector('.rink').getBoundingClientRect().right));
 }
 await page.setViewportSize({width:1440,height:900});await page.screenshot({path:engine.name()+'-desktop-game-preview.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});assert(await page.locator('#menu-toggle').isVisible());assert(!(await page.locator('.desktop-nav').isVisible()));
 assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled(),'Resizing cleared game');
 await page.locator('#menu-toggle').click();await page.locator('#exit-home').click();assert(await page.locator('#start-screen').isVisible());
 assert.deepEqual(errors,[]);console.log(engine.name()+': desktop navigation, two-column layout, responsive resizing and mobile fallback pass');await browser.close();
}})().catch(e=>{console.error(e);process.exit(1);});
