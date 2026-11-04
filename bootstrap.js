// Keep module dependencies on one release; surface load failures instead of a blank game.
import('./app.js?v=menu-close-1').catch(error=>{
 console.error(error);
 document.getElementById('load-status').textContent='The game update could not load. Tap Reload game to try again.';
 const retry=document.getElementById('play');retry.disabled=false;retry.classList.add('retry');retry.textContent='Reload game';
 retry.onclick=()=>{const url=new URL(location.href);url.searchParams.set('reload',Date.now());location.replace(url);};
});
