import {playerPool,availableTeams,playerDetails} from './pools.js?v=spacing-1';
import {createGame,guess,bodyParts} from './game.js?v=spacing-1';
const $=id=>document.getElementById(id);
let dataset,game,playerId,lastName='',bag=[],round=0,settled=false,screen='start',returnScreen='start';
let stats={wins:0,streak:0,best:0};
let preferences={decade:'all',team:'all'};
try{const saved=JSON.parse(localStorage.getItem('ice-time-stats'));if(saved)for(const key of Object.keys(stats))if(Number.isSafeInteger(saved[key])&&saved[key]>=0)stats[key]=saved[key];}catch{}
try{const saved=JSON.parse(localStorage.getItem('ice-time-options'));if(saved&&typeof saved.decade==='string'&&typeof saved.team==='string')preferences=saved;}catch{}
function save(){try{localStorage.setItem('ice-time-stats',JSON.stringify(stats));}catch{}}
function showScreen(value){screen=value;document.body.dataset.screen=value;for(const name of ['start','game','result','menu','rules','rosters'])$(name+'-screen').hidden=name!==value;$('back').hidden=value==='start';$('back').setAttribute('aria-label',['rules','rosters'].includes(value)?'Back to menu':value==='menu'?'Close menu':'Change game options');const inMenu=['menu','rules','rosters'].includes(value);$('menu-toggle').setAttribute('aria-expanded',String(inMenu));$('menu-toggle').setAttribute('aria-label',inMenu?'Close menu':'Open menu');window.scrollTo(0,0);const heading=$(value==='game'?'round':value+'-title');heading.focus({preventScroll:true});}
function openMenu(){if(['menu','rules','rosters'].includes(screen)){showScreen(returnScreen);return;}returnScreen=screen;$('resume').textContent=screen==='game'?'Resume round':screen==='result'?'Back to result':'Back to start';showScreen('menu');}
function renderStats(){for(const key of Object.keys(stats))$(key).textContent=String(stats[key]).padStart(2,'0');}
function pool(){return [...new Set(playerPool(dataset,$('decade').value,$('team').value).map(id=>dataset.players[id]))];}
function saveOptions(){preferences={decade:$('decade').value,team:$('team').value};try{localStorage.setItem('ice-time-options',JSON.stringify(preferences));}catch{}}
function updateOptions(){bag=[];saveOptions();$('roster-count').textContent=`${pool().length.toLocaleString()} players available`;$('data-note').textContent=$('decade').value==='current'?`Roster snapshot updated ${dataset.updated}.`:`Historical records updated ${dataset.updated}.`;}
function teamOptions(){const previous=$('team').value;const ids=availableTeams(dataset,$('decade').value);$('team').replaceChildren(new Option('All teams','all'));for(const id of ids){const team=dataset.teams[id];const historic=!dataset.pools.current[id];$('team').add(new Option(team.name+(historic?' (historical)':''),id));}$('team').value=ids.includes(previous)?previous:'all';}
function refill(){bag=[...pool()];for(let i=bag.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[bag[i],bag[j]]=[bag[j],bag[i]];}if(bag.at(-1)===lastName&&bag.length>1)[bag[0],bag[bag.length-1]]=[bag.at(-1),bag[0]];}
function next(){if(!dataset)return;if(!bag.length)refill();lastName=bag.pop();playerId=playerPool(dataset,$('decade').value,$('team').value).find(id=>dataset.players[id]===lastName);game=createGame(lastName);round++;settled=false;renderGame();showScreen('game');}
function settle(){if(settled||game.status==='playing')return;settled=true;if(game.status==='won'){stats.wins++;stats.streak++;stats.best=Math.max(stats.best,stats.streak);}else stats.streak=0;save();renderStats();}
function renderName(){const name=$('name');name.replaceChildren();for(const word of game.name.split(' ')){const group=document.createElement('div');group.className='word';group.style.setProperty('--letter-count',word.length);for(const character of word){const letter=document.createElement('span');const alphabetical=/[A-Z]/.test(character);letter.className='letter'+(!alphabetical?' punctuation':'');letter.textContent=!alphabetical||game.guessed.includes(character)?character:'';letter.setAttribute('aria-label',letter.textContent||'Blank letter');group.append(letter);}name.append(group);}}
function renderGame(){
 $('round').textContent=`FACEOFF ${String(round).padStart(2,'0')}`;
 $('chances').textContent=`${6+Number(game.bonus)-game.misses} MISSES LEFT`;
 $('bonus').textContent=game.bonus?'Bonus earned':`Hat trick: ${Math.min(3,game.run)} / 3`;
 renderName();
 const parts=bodyParts(game);document.querySelectorAll('[data-part]').forEach(el=>el.classList.toggle('shown',Number(el.dataset.part)<=parts));$('drawing').setAttribute('aria-label',`Gallows with ${parts} of 6 body parts`);
 document.querySelectorAll('.key').forEach(el=>{const used=game.guessed.includes(el.textContent);el.disabled=used||game.status!=='playing';el.className='key'+(used?(game.name.includes(el.textContent)?' hit':' miss'):'');});
 $('message').textContent=game.bonus?'Bonus earned: one extra miss.':'';
 if(game.status!=='playing'){settle();renderResult();showScreen('result');}
}
function renderResult(){const won=game.status==='won';$('result-title').textContent=won?'Goal!':'Game Over';$('result-name').textContent=lastName;const decade=$('decade').value;$('reveal-details').replaceChildren();for(const detail of playerDetails(dataset,playerId,decade,$('team').value)){const row=document.createElement('div');const team=document.createElement('dt');const position=document.createElement('dd');team.textContent=detail.team;position.textContent=detail.positions.join(' / ');row.append(team,position);$('reveal-details').append(row);}}
function chooseLetter(letter){if(screen!=='game'||!game)return;const previous=game;game=guess(game,letter);if(game!==previous)renderGame();}
function goToOptions(){if(['rules','rosters'].includes(screen)){showScreen('menu');return;}if(screen==='menu'){showScreen(returnScreen);return;}requestOptions(screen);}
function requestOptions(from){if(from==='game'&&game?.status==='playing'&&game.guessed.length){$('leave').showModal();return;}showScreen('start');}
$('leave').addEventListener('close',()=>{if($('leave').returnValue==='leave'){game={...game,status:'lost'};settle();showScreen('start');}});
$('back').onclick=goToOptions;$('change-options').onclick=()=>requestOptions(returnScreen);
$('play').onclick=next;$('next').onclick=next;
$('skip').onclick=()=>{game={...game,status:'lost',misses:6+Number(game.bonus)};renderGame();};
$('decade').onchange=()=>{teamOptions();updateOptions();};$('team').onchange=updateOptions;
$('menu-toggle').onclick=openMenu;$('resume').onclick=()=>showScreen(returnScreen);$('open-rules').onclick=()=>showScreen('rules');$('open-rosters').onclick=()=>showScreen('rosters');for(const button of document.querySelectorAll('.info-back'))button.onclick=()=>showScreen('menu');
$('reset').onclick=()=>{if(confirm('Reset your wins, streak, and best streak?')){stats={wins:0,streak:0,best:0};save();renderStats();}};
for(const key of document.querySelectorAll('.key'))key.onclick=()=>chooseLetter(key.textContent);
document.addEventListener('keydown',event=>{if(screen!=='game'||$('leave').open||event.ctrlKey||event.metaKey||event.altKey||event.target.matches('select,input,textarea'))return;if(/^[a-z]$/i.test(event.key))chooseLetter(event.key);});
async function load(){
 $('play').disabled=true;$('play').classList.remove('retry');$('play').innerHTML='<span>Play</span><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m8 4 12 8-12 8Z"/></svg>'; $('load-status').textContent='Loading NHL records…';$('decade').disabled=true;$('team').disabled=true;
 const controller=new AbortController();const timeout=setTimeout(()=>controller.abort(),15000);
 try{
  const response=await fetch('./data/rosters.json',{cache:'no-store',signal:controller.signal});if(!response.ok)throw new Error('Roster fetch failed');dataset=await response.json();if(!dataset.positions?.current||!dataset.pools.current||!Object.keys(dataset.players).length)throw new Error('Invalid roster data');
  $('decade').replaceChildren(new Option('All decades','all'),new Option('Current roster','current'));for(const decade of Object.keys(dataset.pools).filter(d=>d!=='current').sort((a,b)=>b-a))$('decade').add(new Option(decade+'s',decade));
  $('decade').value=[...$('decade').options].some(option=>option.value===preferences.decade)?preferences.decade:'all';
  teamOptions();if([...$('team').options].some(option=>option.value===preferences.team))$('team').value=preferences.team;updateOptions();
  $('decade').disabled=false;$('team').disabled=false;$('play').disabled=false;$('play').onclick=next;$('load-status').textContent='';
 }catch(error){console.error(error);$('load-status').textContent='NHL records could not load. Try loading them again.';$('play').textContent='Retry loading records';$('play').classList.add('retry');$('play').disabled=false;$('play').onclick=load;}
 finally{clearTimeout(timeout);}
}
renderStats();load();
