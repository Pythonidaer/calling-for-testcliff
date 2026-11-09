const STANDARD_MISSES = 6;
const HAT_TRICK_LENGTH = 3;

const PLAYING = 'playing';
const WON = 'won';
const LOST = 'lost';

const SINGLE_LETTER = /^[A-Z]$/;
const NAME_LETTER = /[A-Z]/;
const COMBINING_MARKS = /[\u0300-\u036f]/g;

// NFD leaves o and l with stroke intact, so fold them before stripping marks.
const STROKE_LETTER_FOLDS = [
  ['ø', 'o'],
  ['Ø', 'O'],
  ['ł', 'l'],
  ['Ł', 'L'],
];

export function normalize(name) {
  const folded = foldStrokeLetters(name);
  return folded.normalize('NFD').replace(COMBINING_MARKS, '').toUpperCase();
}

export function createGame(name) {
  return {
    name: normalize(name),
    guessed: [],
    misses: 0,
    run: 0,
    bonus: false,
    status: PLAYING,
  };
}

export function guess(game, letter) {
  const guessLetter = letter.toUpperCase();
  if (!isGuessAllowed(game, guessLetter)) return game;

  const next = recordGuess(game, guessLetter);
  return resolveStatus(next);
}

// Cap at six parts. Once six misses are reached, a bonus hides one of them.
export function bodyParts(game) {
  const undrawnBonusMiss =
    game.bonus && game.misses >= STANDARD_MISSES ? 1 : 0;

  return Math.min(STANDARD_MISSES, game.misses - undrawnBonusMiss);
}

function foldStrokeLetters(name) {
  let folded = name;

  for (const [strokeLetter, plainLetter] of STROKE_LETTER_FOLDS) {
    folded = folded.replaceAll(strokeLetter, plainLetter);
  }

  return folded;
}

function isGuessAllowed(game, letter) {
  return (
    game.status === PLAYING &&
    SINGLE_LETTER.test(letter) &&
    !game.guessed.includes(letter)
  );
}

function recordGuess(game, letter) {
  const next = {
    ...game,
    guessed: [...game.guessed, letter],
  };

  if (next.name.includes(letter)) recordHit(next);
  else recordMiss(next);
  return next;
}

// Stays set for the round. A later miss clears the run only.
function recordHit(game) {
  game.run++;
  if (game.run >= HAT_TRICK_LENGTH) game.bonus = true;
}

function recordMiss(game) {
  game.misses++;
  game.run = 0;
}

function resolveStatus(game) {
  if (isNameComplete(game)) game.status = WON;
  else if (game.misses >= missAllowance(game)) game.status = LOST;
  return game;
}

function isNameComplete(game) {
  return lettersInName(game.name).every((character) =>
    game.guessed.includes(character),
  );
}

function lettersInName(name) {
  return [...name].filter((character) => NAME_LETTER.test(character));
}

// Bonus is stored as a boolean and adds one miss or none.
function missAllowance(game) {
  const bonusMiss = Number(game.bonus);
  return STANDARD_MISSES + bonusMiss;
}
