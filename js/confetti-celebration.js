import confetti from '../vendor/canvas-confetti/confetti.module.mjs';

const CELEBRATION_CANVAS_ID = 'confetti-celebration';
const REDUCED_MOTION_QUERY = '(prefers-reduced-motion: reduce)';

// Particle counts and speeds from canvas-confetti 1.9.4's Realistic Look demo.
// https://catdad.github.io/canvas-confetti/
const REALISTIC_PARTICLE_COUNT = 200;
const REALISTIC_ORIGIN_Y = 0.7;

const REALISTIC_BURSTS = [
  {
    particleRatio: 0.25,
    options: {
      spread: 26,
      startVelocity: 55,
    },
  },
  {
    particleRatio: 0.2,
    options: {
      spread: 60,
    },
  },
  {
    particleRatio: 0.35,
    options: {
      spread: 100,
      decay: 0.91,
      scalar: 0.8,
    },
  },
  {
    particleRatio: 0.1,
    options: {
      spread: 120,
      startVelocity: 25,
      decay: 0.92,
      scalar: 1.2,
    },
  },
  {
    particleRatio: 0.1,
    options: {
      spread: 120,
      startVelocity: 45,
    },
  },
];

let celebrationCanvas;
let canvasBurst;

export function celebratePerfectGame() {
  stopConfetti();
  if (matchMedia(REDUCED_MOTION_QUERY).matches) return;

  mountCelebration();
  const burstPromises = startRealisticBursts();
  const activeCanvas = celebrationCanvas;

  // Remove the canvas only when it is still the one these bursts used.
  Promise.all(burstPromises).then(() => {
    if (celebrationCanvas === activeCanvas) unmountCelebration();
  });
}

export function stopConfetti() {
  canvasBurst?.reset();
  unmountCelebration();
}

function mountCelebration() {
  if (celebrationCanvas) return;

  celebrationCanvas = document.createElement('canvas');
  celebrationCanvas.id = CELEBRATION_CANVAS_ID;
  celebrationCanvas.setAttribute('aria-hidden', 'true');
  document.body.append(celebrationCanvas);
  canvasBurst = confetti.create(celebrationCanvas, {
    resize: true,
    disableForReducedMotion: true,
  });
}

function startRealisticBursts() {
  const defaults = {
    origin: { y: REALISTIC_ORIGIN_Y },
  };

  return REALISTIC_BURSTS.map((recipe) =>
    canvasBurst({
      ...defaults,
      ...recipe.options,
      particleCount: Math.floor(
        REALISTIC_PARTICLE_COUNT * recipe.particleRatio,
      ),
    }),
  );
}

function unmountCelebration() {
  celebrationCanvas?.remove();
  celebrationCanvas = undefined;
  canvasBurst = undefined;
}

document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopConfetti();
});
