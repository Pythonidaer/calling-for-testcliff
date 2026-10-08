# Ice Time — Hockey Hangman
Mobile-first retro hockey hangman. 160 male NHL players from U.S. and Canadian NHL teams, first and last names, Legends / Modern greats / All eras. All players have played in the NHL; nationality is unrestricted. No minor-league-only or overseas-league-only players are included. Modern greats describes a playing generation, not current active status.

Six incorrect letters draw the head, body, two arms, and two legs. Three consecutive correct letter guesses earn one bonus miss per round. When earned, miss six leaves the final leg undrawn; miss seven ends the round. Repeated letters do not affect the game. Scores save locally. Players are shuffled without repeats until the selected roster is exhausted. Giving up counts as a loss; switching eras after guessing counts as a loss.

## Run
`npm start` then open http://localhost:8000. Run `npm test` for game-rule tests. No dependencies, build step, or third-party assets.

## GitHub Pages
Pages publishes from the `main` branch, `/ (root)`, as configured in Settings → Pages. The included workflow independently runs unit tests and Chromium gameplay checks at 320, 390, 768, and 1280px. All asset links are relative for repository-path hosting.

Player names are used for trivia; this project is not affiliated with the NHL or its teams. No player images or league logos are used.
