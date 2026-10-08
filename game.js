export const normalize = name => name.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase();
export function createGame(name) {return {name:normalize(name),guessed:[],misses:0,run:0,bonus:false,status:'playing'};}
export function guess(game, letter) {
 letter=letter.toUpperCase();
 if(game.status!=='playing'||!/^[A-Z]$/.test(letter)||game.guessed.includes(letter)) return game;
 const g={...game,guessed:[...game.guessed,letter]};
 if(g.name.includes(letter)){g.run++;if(g.run>=3)g.bonus=true;}else{g.misses++;g.run=0;}
 const letters=[...g.name].filter(c=>/[A-Z]/.test(c));
 if(letters.every(c=>g.guessed.includes(c)))g.status='won';
 else if(g.misses>=6+Number(g.bonus))g.status='lost';
 return g;
}
export const bodyParts = game => Math.min(6,game.misses - (game.bonus && game.misses>=6 ? 1:0));
