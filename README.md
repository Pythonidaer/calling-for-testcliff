# Ice Time — Hockey Hangman
Mobile-first retro hockey hangman. 160 male players, first and last names, Legends / Modern greats / All eras. Modern greats describes a playing generation, not current active status.

Six incorrect letters draw the head, body, two arms, and two legs. Three consecutive correct letter guesses earn one bonus miss per round. When earned, miss six leaves the final leg undrawn; miss seven ends the round. Repeated letters do not affect the game. Scores save locally. Players are shuffled without repeats until the selected roster is exhausted. Giving up counts as a loss; switching eras after guessing counts as a loss.

## Run
`npm start` then open http://localhost:8000. Run `npm test` for game-rule tests. No dependencies, build step, or third-party assets.

## GitHub Pages
The included workflow runs unit tests and Chromium gameplay checks at 320, 390, 768, and 1280px, then deploys the static files. If automatic Pages activation is denied, choose **GitHub Actions** as the source in Settings → Pages and re-run the workflow. All asset links are relative for repository-path hosting.

Player names are used for trivia; this project is not affiliated with the NHL or its teams. No player images or league logos are used.
