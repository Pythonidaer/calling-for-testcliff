// Keep module dependencies on one release; surface load failures instead of a blank game.
import('./app.js?v=hat-trick-1').catch(error=>{
 console.error(error);
 document.getElementById('message').textContent='The game update could not load. Tap Reload game to try again.';
 const retry=document.getElementById('next');retry.hidden=false;retry.textContent='Reload game';
 retry.onclick=()=>{const url=new URL(location.href);url.searchParams.set('reload',Date.now());location.replace(url);};
});
