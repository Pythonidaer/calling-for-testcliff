const {chromium,webkit}=require('playwright');
const assert=require('node:assert/strict');
const url=process.env.QA_BASE_URL||'http://localhost:8000';
(async()=>{for(const engine of [chromium,webkit]){
 const browser=await engine.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await page.emulateMedia({reducedMotion:'reduce'});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(url);await page.waitForFunction(()=>!document.getElementById('play').disabled);
 for(const width of [768,900,1024,1440,1920]){
  await page.setViewportSize({width,height:900});
  assert(await page.locator('.desktop-nav').isVisible());assert.equal(await page.locator('.desktop-nav button').count(),2);assert(!(await page.locator('#menu-toggle').isVisible()));
  assert(await page.locator('.shell').evaluate(el=>el.getBoundingClientRect().width>=innerWidth-1),'Desktop shell still phone width');
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Header or home overflows at '+width);
  assert(await page.locator('.home-controls').evaluate(el=>{const r=el.getBoundingClientRect(),board=document.querySelector('.scoreboard').getBoundingClientRect(),filters=document.querySelector('.filters').getBoundingClientRect(),count=document.querySelector('#roster-count').getBoundingClientRect(),play=document.querySelector('#play').getBoundingClientRect();return r.width<=640&&Math.abs(r.width-board.width)<1&&Math.abs(filters.width-board.width)<1&&board.top-document.querySelector('header').getBoundingClientRect().bottom<=40&&r.top>=board.bottom&&count.top>=filters.bottom&&play.top>=count.bottom&&Math.abs((r.left+r.right-innerWidth)/2)<1;}),'Desktop setup must be centered and ordered');
  assert(await page.locator('#play').evaluate(el=>{const r=el.getBoundingClientRect(),board=document.querySelector('.scoreboard').getBoundingClientRect(),filters=document.querySelector('.filters').getBoundingClientRect(),count=document.querySelector('#roster-count').getBoundingClientRect();return Math.abs((innerHeight-r.bottom)-board.top)<2&&filters.top-board.bottom>=24&&r.top-count.bottom>=24;}),'Unbalanced home spacing '+width);
  assert(await page.locator('#team').evaluate(el=>el.getBoundingClientRect().left>document.querySelector('#decade').getBoundingClientRect().right),'Desktop fields should share a row');
 }
 await page.setViewportSize({width:1440,height:900});await page.screenshot({path:engine.name()+'-desktop-start-preview.png',fullPage:true});
 await page.locator('.desktop-nav [data-nav="rules"]').click();assert(await page.locator('#rules-screen').isVisible());
 assert.equal(await page.locator('.desktop-nav [data-nav="rules"]').getAttribute('aria-current'),'page');
 await page.locator('.desktop-nav [data-nav="rosters"]').click();assert(await page.locator('#rosters-screen').isVisible());
 await page.locator('#home-link').click();assert(await page.locator('#start-screen').isVisible(),'Logo must return home');
 await page.locator('#play').click();await page.getByRole('button',{name:'Guess A',exact:true}).click();
 await page.locator('.desktop-nav [data-nav="rules"]').click();await page.keyboard.press('Escape');
 assert(await page.locator('#game-screen').isVisible());assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled(),'Navigation lost in-progress guess');
 for(const [width,height] of [[1024,768],[1440,900],[1920,1080]]){
  await page.setViewportSize({width,height});
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth&&document.documentElement.scrollHeight<=innerHeight+1),'Desktop game overflow '+width);
  assert(await page.locator('#keyboard').evaluate(el=>el.getBoundingClientRect().top>document.querySelector('.rink').getBoundingClientRect().bottom),'Rink must stay above the keyboard');
 }
 await page.setViewportSize({width:1440,height:900});await page.screenshot({path:engine.name()+'-desktop-game-preview.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});assert(await page.locator('#menu-toggle').isVisible());assert(!(await page.locator('.desktop-nav').isVisible()));
 assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled(),'Resizing cleared game');
 await page.locator('#menu-toggle').click();await page.locator('#exit-home').click();assert(await page.locator('#start-screen').isVisible());
 assert.deepEqual(errors,[]);console.log(engine.name()+': desktop navigation, stacked layout, responsive resizing and mobile fallback pass');await browser.close();
}})().catch(e=>{console.error(e);process.exit(1);});
