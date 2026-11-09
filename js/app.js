import {
  celebratePerfectGame,
  stopConfetti,
} from './confetti-celebration.js?v=home-balance-1';
import { teamAccents } from './team-accents.js?v=home-balance-1';
import {
  playerPool,
  availableTeams,
  playerDetails,
} from './pools.js?v=home-balance-1';
import { createGame, guess, bodyParts } from './game.js?v=home-balance-1';

// One sentinel for the all-decades and all-teams filters.
const ALL_FILTER = 'all';

// Active-club snapshot. Not a historical decade.
const CURRENT_ROSTER = 'current';

const START_SCREEN = 'start';
const GAME_SCREEN = 'game';
const RESULT_SCREEN = 'result';
const MENU_SCREEN = 'menu';
const RULES_SCREEN = 'rules';
const ROSTERS_SCREEN = 'rosters';

const MENU_SCREENS = Object.freeze([
  MENU_SCREEN,
  RULES_SCREEN,
  ROSTERS_SCREEN,
]);

const APP_SCREENS = Object.freeze([
  START_SCREEN,
  GAME_SCREEN,
  RESULT_SCREEN,
  MENU_SCREEN,
  RULES_SCREEN,
  ROSTERS_SCREEN,
]);

const PLAYING = 'playing';
const WON = 'won';
const LOST = 'lost';

// Six misses draw the six gallows parts. A hat trick adds a miss, not a part.
const STANDARD_MISSES = 6;
const GALLOWS_PARTS = 6;
const HAT_TRICK_LENGTH = 3;
const TWO_DIGIT_PAD = 2;

const STATS_STORAGE_KEY = 'ice-time-stats';
const OPTIONS_STORAGE_KEY = 'ice-time-options';

const ROSTER_URL = './data/rosters.json';
const ROSTER_TIMEOUT_MS = 15000;

const TEAM_ACCENT_PROPERTY = '--team-accent';
const RETRY_CLASS = 'retry';

const MENU_ICON_PATH = 'M4 6h16M4 12h16M4 18h16';
const CLOSE_ICON_PATH = 'M6 6l12 12M18 6 6 18';

const NAME_LETTER = /[A-Z]/;
const TYPED_LETTER = /^[a-z]$/i;

const PLAY_BUTTON_MARKUP =
  '<span>PLAY</span><img src="puck-button.svg" alt="" draggable="false">';

const INITIAL_STATS = Object.freeze({
  wins: 0,
  streak: 0,
  best: 0,
});

let rosterData;
let game;
let playerId;
let drawnName = '';
let nameBag = [];
let round = 0;
let outcomeRecorded = false;
let screen = START_SCREEN;
let returnScreen = START_SCREEN;
let stats = { ...INITIAL_STATS };
let preferences = { decade: ALL_FILTER, team: ALL_FILTER };

function elementById(id) {
  return document.getElementById(id);
}

function readStoredJson(key) {
  let stored;

  try {
    stored = localStorage.getItem(key);
  } catch {
    // Private browsing can throw. The in-memory default stays.
    return null;
  }

  try {
    return JSON.parse(stored);
  } catch {
    // A corrupt value must not stop the page from loading.
    return null;
  }
}

function writeStoredJson(key, value) {
  const payload = JSON.stringify(value);

  try {
    localStorage.setItem(key, payload);
  } catch {
    // Storage can be full or blocked. This session keeps the in-memory value.
  }
}

function loadStoredStats() {
  const saved = readStoredJson(STATS_STORAGE_KEY);
  if (!saved) return;

  for (const key of Object.keys(stats)) {
    if (!isStoredCount(saved[key])) continue;
    stats[key] = saved[key];
  }
}

function isStoredCount(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

function loadStoredPreferences() {
  const saved = readStoredJson(OPTIONS_STORAGE_KEY);

  if (!saved) return;
  if (typeof saved.decade !== 'string') return;
  if (typeof saved.team !== 'string') return;

  // Keep unknown keys until the next change rewrites decade and team only.
  preferences = saved;
}

function saveStats() {
  writeStoredJson(STATS_STORAGE_KEY, stats);
}

function saveOptions() {
  preferences = {
    decade: selectedDecade(),
    team: selectedTeam(),
  };
  writeStoredJson(OPTIONS_STORAGE_KEY, preferences);
}

function showScreen(nextScreen) {
  stopConfetti();
  screen = nextScreen;
  document.body.dataset.screen = nextScreen;
  showOnly(nextScreen);
  setMenuToggle(isMenuScreen(nextScreen));
  markCurrentNav(nextScreen);
  markHomeLink(nextScreen);
  window.scrollTo(0, 0);
  elementById(headingId(nextScreen)).focus({ preventScroll: true });
}

function showOnly(nextScreen) {
  for (const name of APP_SCREENS) {
    elementById(`${name}-screen`).hidden = name !== nextScreen;
  }
}

function isMenuScreen(name) {
  return MENU_SCREENS.includes(name);
}

function setMenuToggle(menuOpen) {
  const toggle = elementById('menu-toggle');
  const iconPath = menuOpen ? CLOSE_ICON_PATH : MENU_ICON_PATH;

  toggle.querySelector('path').setAttribute('d', iconPath);
  toggle.setAttribute('aria-expanded', String(menuOpen));
  toggle.setAttribute('aria-label', menuOpen ? 'Close menu' : 'Open menu');
}

function markCurrentNav(nextScreen) {
  const menuOpen = isMenuScreen(nextScreen);

  for (const item of document.querySelectorAll('[data-nav]')) {
    const onThisScreen =
      item.dataset.nav === nextScreen && nextScreen !== START_SCREEN;

    if (onThisScreen) item.setAttribute('aria-current', 'page');
    else item.removeAttribute('aria-current');

    if (item.dataset.nav !== MENU_SCREEN) continue;

    item.textContent = menuOpen ? 'Close menu' : 'Menu';
    item.setAttribute('aria-expanded', String(menuOpen));
  }
}

function markHomeLink(nextScreen) {
  const homeLink = elementById('home-link');

  if (nextScreen === START_SCREEN) {
    homeLink.setAttribute('aria-current', 'page');
    return;
  }

  homeLink.removeAttribute('aria-current');
}

function headingId(nextScreen) {
  if (nextScreen === GAME_SCREEN) return 'round';
  if (nextScreen === START_SCREEN) return 'scores-title';
  return `${nextScreen}-title`;
}

function toggleMenu() {
  if (isMenuScreen(screen)) {
    showScreen(returnScreen);
    return;
  }

  returnScreen = screen;
  showScreen(MENU_SCREEN);
}

// Scoreboard ids wins, streak, and best are the stats keys.
function renderStats() {
  for (const key of Object.keys(stats)) {
    const padded = String(stats[key]).padStart(TWO_DIGIT_PAD, '0');
    elementById(key).textContent = padded;
  }
}

function selectedDecade() {
  return elementById('decade').value;
}

function selectedTeam() {
  return elementById('team').value;
}

function namesInFilter() {
  const ids = playerPool(rosterData, selectedDecade(), selectedTeam());
  const names = ids.map((id) => rosterData.players[id]);
  return [...new Set(names)];
}

function applyFilters() {
  nameBag = [];
  saveOptions();
  applyTeamAccent();
  renderRosterCount();
}

function applyTeamAccent() {
  const accent = teamAccents[selectedTeam()];
  const rootStyle = document.documentElement.style;

  if (accent) {
    rootStyle.setProperty(TEAM_ACCENT_PROPERTY, accent);
    return;
  }

  rootStyle.removeProperty(TEAM_ACCENT_PROPERTY);
}

function renderRosterCount() {
  const count = namesInFilter().length.toLocaleString();
  elementById('roster-count').textContent = `${count} players available`;
}

function fillTeamSelect() {
  const previousTeam = selectedTeam();
  const teamIds = availableTeams(rosterData, selectedDecade());
  const teamSelect = elementById('team');

  teamSelect.replaceChildren(new Option('All teams', ALL_FILTER));

  for (const teamId of teamIds) {
    teamSelect.add(new Option(teamOptionLabel(teamId), teamId));
  }

  const kept = teamIds.includes(previousTeam) ? previousTeam : ALL_FILTER;
  teamSelect.value = kept;
}

function teamOptionLabel(teamId) {
  const team = rosterData.teams[teamId];
  const activeNow = rosterData.pools[CURRENT_ROSTER][teamId];
  if (activeNow) return team.name;
  return `${team.name} (historical)`;
}

function refillNameBag() {
  nameBag = [...namesInFilter()];
  shuffleInPlace(nameBag);
  keepDrawnNameOffNextDraw();
}

function shuffleInPlace(names) {
  for (let index = names.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    [names[index], names[swapIndex]] = [names[swapIndex], names[index]];
  }
}

// pop() draws the last slot, so a refill must not leave the name just played there.
function keepDrawnNameOffNextDraw() {
  const lastIndex = nameBag.length - 1;
  const repeated = nameBag.at(-1) === drawnName && nameBag.length > 1;
  if (!repeated) return;

  [nameBag[0], nameBag[lastIndex]] = [nameBag.at(-1), nameBag[0]];
}

function startRound() {
  if (!rosterData) return;
  if (nameBag.length === 0) refillNameBag();

  drawnName = nameBag.pop();
  playerId = playerIdForName(drawnName);
  game = createGame(drawnName);
  round += 1;
  outcomeRecorded = false;
  renderGame();
  showScreen(GAME_SCREEN);
}

function playerIdForName(name) {
  const ids = playerPool(rosterData, selectedDecade(), selectedTeam());
  return ids.find((id) => rosterData.players[id] === name);
}

// bonus is a boolean and adds one miss, or none, for the whole round.
function missAllowance(roundGame) {
  return STANDARD_MISSES + Number(roundGame.bonus);
}

function recordOutcome() {
  if (outcomeRecorded || game.status === PLAYING) return;

  outcomeRecorded = true;

  if (game.status === WON) {
    stats.wins += 1;
    stats.streak += 1;
    stats.best = Math.max(stats.best, stats.streak);
  } else {
    stats.streak = 0;
  }

  saveStats();
  renderStats();
}

function renderName() {
  const name = elementById('name');
  name.replaceChildren();

  for (const word of game.name.split(' ')) {
    name.append(wordElement(word));
  }
}

function wordElement(word) {
  const group = document.createElement('div');

  group.className = 'word';
  group.style.setProperty('--letter-count', String(word.length));

  for (const character of word) {
    group.append(letterElement(character));
  }

  return group;
}

function letterElement(character) {
  const letter = document.createElement('span');
  const alphabetical = NAME_LETTER.test(character);
  const revealed = !alphabetical || game.guessed.includes(character);

  letter.className = alphabetical ? 'letter' : 'letter punctuation';
  letter.textContent = revealed ? character : '';
  letter.setAttribute('aria-label', letter.textContent || 'Blank letter');
  return letter;
}

function renderGame() {
  renderRoundHeader();
  renderName();
  renderGallows();
  renderKeyboard();

  if (game.status === PLAYING) return;
  finishRound();
}

function renderRoundHeader() {
  const missesLeft = missAllowance(game) - game.misses;

  elementById('round').textContent =
    `ROUND ${String(round).padStart(TWO_DIGIT_PAD, '0')}`;
  elementById('chances').textContent = `${missesLeft} MISSES LEFT`;
  elementById('bonus').textContent = bonusStatus();
}

function bonusStatus() {
  if (game.bonus) return 'Extra guess earned';

  const progress = Math.min(HAT_TRICK_LENGTH, game.run);
  return `Hat trick: ${progress} / ${HAT_TRICK_LENGTH}`;
}

function renderGallows() {
  const parts = bodyParts(game);

  for (const part of document.querySelectorAll('[data-part]')) {
    const partNumber = Number(part.dataset.part);
    part.classList.toggle('shown', partNumber <= parts);
  }

  elementById('drawing').setAttribute(
    'aria-label',
    `Gallows with ${parts} of ${GALLOWS_PARTS} body parts`,
  );
}

function renderKeyboard() {
  for (const key of document.querySelectorAll('.key')) {
    const letter = key.textContent;
    const used = game.guessed.includes(letter);

    key.disabled = used || game.status !== PLAYING;
    key.className = keyClassName(letter, used);
  }
}

function keyClassName(letter, used) {
  if (!used) return 'key';

  const mark = game.name.includes(letter) ? 'hit' : 'miss';
  return `key ${mark}`;
}

function finishRound() {
  // recordOutcome flips outcomeRecorded, so the celebration check has to be first.
  const perfect = isFreshPerfectWin();

  recordOutcome();
  renderResult();
  showScreen(RESULT_SCREEN);
  if (perfect) celebratePerfectGame();
}

function isFreshPerfectWin() {
  return !outcomeRecorded && game.status === WON && game.misses === 0;
}

function renderResult() {
  const won = game.status === WON;
  const details = playerDetails(
    rosterData,
    playerId,
    selectedDecade(),
    selectedTeam(),
  );
  const list = elementById('reveal-details');

  elementById('result-title').textContent = won ? 'GOAL' : 'Game Over';
  elementById('result-name').textContent = drawnName;
  list.replaceChildren();

  for (const detail of details) {
    list.append(detailRow(detail));
  }
}

function detailRow(detail) {
  const row = document.createElement('div');
  const team = document.createElement('dt');
  const position = document.createElement('dd');

  team.textContent = detail.team;
  position.textContent = detail.positions.join(' / ');
  row.append(team, position);
  return row;
}

function chooseLetter(letter) {
  if (screen !== GAME_SCREEN || !game) return;

  const previous = game;
  game = guess(game, letter);
  if (game !== previous) renderGame();
}

function returnHome() {
  game = undefined;
  showScreen(START_SCREEN);
}

function giveUp() {
  game = {
    ...game,
    status: LOST,
    misses: missAllowance(game),
  };
  renderGame();
}

function followNav(target) {
  if (target === START_SCREEN) {
    returnHome();
    return;
  }

  if (target === MENU_SCREEN) {
    toggleMenu();
    return;
  }

  if (!isMenuScreen(screen)) returnScreen = screen;
  showScreen(target);
}

function resetScores() {
  const confirmed = confirm('Reset your wins, streak, and best streak?');
  if (!confirmed) return;

  stats = { ...INITIAL_STATS };
  saveStats();
  renderStats();
}

function handleKeydown(event) {
  if (event.key === 'Escape' && isMenuScreen(screen)) {
    showScreen(returnScreen);
    return;
  }

  if (!acceptsLetterGuess(event)) return;
  if (!TYPED_LETTER.test(event.key)) return;

  chooseLetter(event.key);
}

function acceptsLetterGuess(event) {
  if (screen !== GAME_SCREEN) return false;
  if (event.ctrlKey || event.metaKey || event.altKey) return false;
  return !event.target.matches('select,input,textarea');
}

async function loadRosters() {
  showRosterLoading();

  const controller = new AbortController();
  const timeout = setTimeout(() => {
    controller.abort();
  }, ROSTER_TIMEOUT_MS);

  try {
    rosterData = await fetchRosterDataset(controller.signal);
    fillDecadeSelect();
    restoreDecadePreference();
    fillTeamSelect();
    restoreTeamPreference();
    applyFilters();
    showRosterReady();
  } catch (error) {
    console.error(error);
    showRosterFailure();
  } finally {
    clearTimeout(timeout);
  }
}

function showRosterLoading() {
  const playButton = elementById('play');

  playButton.disabled = true;
  playButton.classList.remove(RETRY_CLASS);
  playButton.innerHTML = PLAY_BUTTON_MARKUP;
  elementById('load-status').textContent = 'Loading NHL records…';
  elementById('decade').disabled = true;
  elementById('team').disabled = true;
}

async function fetchRosterDataset(signal) {
  const response = await fetch(ROSTER_URL, {
    cache: 'no-store',
    signal,
  });

  if (!response.ok) throw new Error('Roster fetch failed');

  const roster = await response.json();
  if (!isPlayableRoster(roster)) throw new Error('Invalid roster data');
  return roster;
}

function isPlayableRoster(roster) {
  if (!roster.positions?.[CURRENT_ROSTER]) return false;
  if (!roster.pools[CURRENT_ROSTER]) return false;
  if (!Object.keys(roster.players).length) return false;
  return true;
}

function fillDecadeSelect() {
  const decadeSelect = elementById('decade');
  const historicalDecades = Object.keys(rosterData.pools)
    .filter((decade) => decade !== CURRENT_ROSTER)
    .sort((left, right) => right - left);

  decadeSelect.replaceChildren(
    new Option('All decades', ALL_FILTER),
    new Option('Current roster', CURRENT_ROSTER),
  );

  for (const decade of historicalDecades) {
    decadeSelect.add(new Option(`${decade}s`, decade));
  }
}

function restoreDecadePreference() {
  const decadeSelect = elementById('decade');
  const savedDecade = preferences.decade;

  decadeSelect.value = selectOffers(decadeSelect, savedDecade)
    ? savedDecade
    : ALL_FILTER;
}

function restoreTeamPreference() {
  const teamSelect = elementById('team');

  if (!selectOffers(teamSelect, preferences.team)) return;
  teamSelect.value = preferences.team;
}

function selectOffers(select, value) {
  return [...select.options].some((option) => option.value === value);
}

function showRosterReady() {
  const playButton = elementById('play');

  elementById('decade').disabled = false;
  elementById('team').disabled = false;
  playButton.disabled = false;
  playButton.onclick = () => {
    startRound();
  };
  elementById('load-status').textContent = '';
}

function showRosterFailure() {
  const playButton = elementById('play');

  elementById('load-status').textContent =
    'NHL records could not load. Try loading them again.';
  playButton.textContent = 'Retry loading records';
  playButton.classList.add(RETRY_CLASS);
  playButton.disabled = false;
  playButton.onclick = () => {
    loadRosters();
  };
}

function wireControls() {
  elementById('home-link').onclick = (event) => {
    event.preventDefault();
    returnHome();
  };
  elementById('play').onclick = () => {
    startRound();
  };
  elementById('next').onclick = () => {
    startRound();
  };
  elementById('skip').onclick = () => {
    giveUp();
  };
  elementById('decade').onchange = () => {
    fillTeamSelect();
    applyFilters();
  };
  elementById('team').onchange = () => {
    applyFilters();
  };
  elementById('menu-toggle').onclick = () => {
    toggleMenu();
  };
  elementById('exit-home').onclick = () => {
    returnHome();
  };
  elementById('change-team-result').onclick = () => {
    returnHome();
  };
  elementById('open-rules').onclick = () => {
    showScreen(RULES_SCREEN);
  };
  elementById('open-rosters').onclick = () => {
    showScreen(ROSTERS_SCREEN);
  };

  for (const button of document.querySelectorAll('.info-back')) {
    button.onclick = () => {
      showScreen(MENU_SCREEN);
    };
  }

  for (const item of document.querySelectorAll('[data-nav]')) {
    item.onclick = () => {
      followNav(item.dataset.nav);
    };
  }

  elementById('reset').onclick = () => {
    resetScores();
  };

  for (const key of document.querySelectorAll('.key')) {
    key.onclick = () => {
      chooseLetter(key.textContent);
    };
  }

  document.addEventListener('keydown', handleKeydown);
}

loadStoredStats();
loadStoredPreferences();
wireControls();
renderStats();
loadRosters();
