import confetti from './vendor/canvas-confetti/confetti.module.mjs';

// Temporary manual preview, using canvas-confetti 1.9.4's Realistic Look demo.
// https://catdad.github.io/canvas-confetti/ — no perfect-game trigger yet.
let canvas,burst;
export function previewConfetti(){
 stopConfetti();
 if(matchMedia('(prefers-reduced-motion: reduce)').matches)return;
 if(!canvas){
  canvas=document.createElement('canvas');canvas.id='confetti-preview';
  canvas.setAttribute('aria-hidden','true');document.body.append(canvas);
  burst=confetti.create(canvas,{resize:true,disableForReducedMotion:true});
 }
 const count=200,defaults={origin:{y:0.7}};
 const fire=(ratio,options)=>burst({...defaults,...options,particleCount:Math.floor(count*ratio)});
 const effects=[
  fire(0.25,{spread:26,startVelocity:55}),
  fire(0.2,{spread:60}),
  fire(0.35,{spread:100,decay:0.91,scalar:0.8}),
  fire(0.1,{spread:120,startVelocity:25,decay:0.92,scalar:1.2}),
  fire(0.1,{spread:120,startVelocity:45})
 ];
 const activeCanvas=canvas;
 Promise.all(effects).then(()=>{if(canvas===activeCanvas){canvas.remove();canvas=undefined;burst=undefined;}});
}
export function stopConfetti(){burst?.reset();canvas?.remove();canvas=undefined;burst=undefined;}

document.addEventListener('visibilitychange',()=>{if(document.hidden)stopConfetti();});
