const {chromium,webkit}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const url=process.env.QA_BASE_URL||'http://localhost:8000';
(async()=>{
 const data=JSON.parse(fs.readFileSync(path.join(__dirname,'../data/rosters.json'),'utf8'));
 const {playerPool}=await import('../pools.js');
 const {normalize}=await import('../game.js');
 for(const engine of [chromium,webkit]){
  const browser=await engine.launch({headless:true});
  const page=await browser.newPage({viewport:{width:390,height:844}});
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto(url);await page.waitForFunction(()=>!document.getElementById('decade').disabled);
  assert(await page.locator('#start-screen').isVisible());assert(!(await page.locator('#game-screen').isVisible()));
  assert.equal(await page.locator('#sound').count(),0);
  await page.screenshot({path:engine.name()+'-start-preview.png',fullPage:true});
  await page.getByRole('button',{name:'Play',exact:true}).click();
  for(const [width,height] of [[320,667],[375,812],[390,844],[430,932],[768,1024],[1280,900]]){
   await page.setViewportSize({width,height});
   assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Horizontal overflow '+width);
   assert(await page.evaluate(()=>document.documentElement.scrollHeight<=innerHeight+1),'Vertical overflow '+width+'x'+height);
   assert(await page.locator('#keyboard').evaluate(el=>el.getBoundingClientRect().bottom<=innerHeight),'Keyboard below screen');
   assert(await page.locator('.key').first().evaluate(el=>el.getBoundingClientRect().width>=44&&el.getBoundingClientRect().height>=44),'Small tap target');
  }
  await page.setViewportSize({width:390,height:844});
  await page.getByRole('button',{name:'How to play'}).click();await page.getByRole('button',{name:'Close rules'}).click();
  await page.screenshot({path:engine.name()+'-game-preview.png',fullPage:true});
  // Empty rounds can return to setup without changing scores.
  await page.getByRole('button',{name:'Change game options'}).click();
  assert(await page.locator('#start-screen').isVisible());assert.equal(await page.locator('#wins').innerText(),'00');
  await page.locator('#decade').selectOption('1980');await page.locator('#team').selectOption({label:'Quebec Nordiques (historical)'});
  assert(parseInt(await page.locator('#roster-count').innerText().then(t=>t.replaceAll(',','')))>10);
  await page.getByRole('button',{name:'Play',exact:true}).click();
  await page.getByRole('button',{name:'Guess A',exact:true}).click();
  await page.getByRole('button',{name:'Change game options'}).click();assert(await page.locator('#leave').isVisible());
  await page.getByRole('button',{name:'Keep playing'}).click();assert(await page.locator('#game-screen').isVisible());
  assert(await page.getByRole('button',{name:'Guess A',exact:true}).isDisabled());
  await page.getByRole('button',{name:'Give up & reveal'}).click();assert(await page.locator('#result-screen').isVisible());
  assert.equal(await page.locator('#result-title').innerText(),'Final whistle.');
  const loss=await page.locator('#reveal-details').innerText();assert(loss.includes('Quebec Nordiques')&&!loss.includes('Colorado Avalanche'));
  await page.getByRole('button',{name:'Play again'}).click();assert(await page.locator('#game-screen').isVisible());assert(!(await page.locator('#result-screen').isVisible()));
  await page.getByRole('button',{name:'Change game options'}).click();
  await page.evaluate(()=>{Math.random=()=>0});await page.locator('#decade').selectOption('current');await page.locator('#team').selectOption({label:'Boston Bruins'});
  const teamId=Object.keys(data.teams).find(id=>data.teams[id].name==='Boston Bruins');const player=data.players[playerPool(data,'current',teamId)[0]];
  await page.getByRole('button',{name:'Play',exact:true}).click();
  for(const letter of new Set(normalize(player).replace(/[^A-Z]/g,'')))await page.getByRole('button',{name:'Guess '+letter,exact:true}).click();
  assert(await page.locator('#result-screen').isVisible());assert.equal(await page.locator('#result-title').innerText(),'Goal!');
  const result=await page.locator('#reveal-details').innerText();assert(result.includes('Boston Bruins')&&/(Center|Left wing|Right wing|Defenseman|Goalie)/.test(result));
  await page.screenshot({path:engine.name()+'-result-preview.png',fullPage:true});
  await page.reload();await page.waitForFunction(()=>!document.getElementById('decade').disabled);
  for(const id of ['wins','streak','best'])assert.equal(await page.locator('#'+id).innerText(),'01');
  assert.equal(await page.locator('#decade').inputValue(),'current');assert.equal(await page.locator('#team').inputValue(),teamId);
  // Confirmed abandonment settles one loss and never increments wins.
  await page.getByRole('button',{name:'Play',exact:true}).click();await page.getByRole('button',{name:'Guess A',exact:true}).click();
  await page.getByRole('button',{name:'Change game options'}).click();await page.locator('#leave').getByRole('button',{name:'Change options',exact:true}).click();
  await page.locator('#start-screen').waitFor({state:'visible'});
  assert(await page.locator('#start-screen').isVisible());assert.equal(await page.locator('#wins').innerText(),'01');assert.equal(await page.locator('#streak').innerText(),'00');assert.equal(await page.locator('#best').innerText(),'01');
  await page.getByRole('button',{name:'Play',exact:true}).click();
  await page.setViewportSize({width:320,height:568});
  await page.evaluate(()=>{const word=document.querySelector('.word');word.style.setProperty('--letter-count',18);word.replaceChildren(...Array.from('LAVALLEE-SMOTHERMAN',c=>{const el=document.createElement('span');el.className='letter';el.textContent=c;return el;}));});
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Long name overflow');
  await page.locator('#skip').scrollIntoViewIfNeeded();assert(await page.locator('#skip').isVisible());
  assert.deepEqual(errors,[]);console.log(engine.name()+': three screens, six screen sizes, visible keyboard, 44px targets, options, win/loss cards, persistence, abandonment, small-screen fallback pass');
  await browser.close();
 }
})().catch(error=>{console.error(error);process.exit(1);});
