const APP_MODULE_URL = './app.js?v=home-balance-1';
const LOAD_STATUS_ID = 'load-status';
const PLAY_BUTTON_ID = 'play';
const RETRY_CLASS = 'retry';
const RELOAD_LABEL = 'Reload game';
const RELOAD_QUERY_PARAM = 'reload';
const LOAD_FAILURE_MESSAGE =
  `The game update could not load. Tap ${RELOAD_LABEL} to try again.`;

// Keep module dependencies on one release; surface load failures instead of a blank game.
import(APP_MODULE_URL).catch(reportAppLoadFailure);

function reportAppLoadFailure(error) {
  console.error(error);
  document.getElementById(LOAD_STATUS_ID).textContent = LOAD_FAILURE_MESSAGE;
  enableGameReload();
}

function enableGameReload() {
  const reloadButton = document.getElementById(PLAY_BUTTON_ID);

  reloadButton.disabled = false;
  reloadButton.classList.add(RETRY_CLASS);
  reloadButton.textContent = RELOAD_LABEL;
  reloadButton.onclick = () => {
    reloadGame();
  };
}

// A unique query forces the browser to fetch this release again.
function reloadGame() {
  const url = new URL(location.href);

  url.searchParams.set(RELOAD_QUERY_PARAM, Date.now());
  location.replace(url);
}
