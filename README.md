# Ice Time — Hockey Hangman
Mobile-first NHL hangman with first and last names, six misses, and a once-per-round bonus miss for three correct letters in a row.

## NHL records and filters
- Decades span the NHL's recorded history, starting in 1917. A decade uses the season's **start year**: 1989–90 is in the 1980s.
- Historical player pools include **regular-season appearances**, including goalies. These are not claims of full administrative rosters (players with no appearances are excluded).
- Team filters use actual historical team identities, including defunct/renamed clubs. Quebec Nordiques and Colorado Avalanche, for example, are separate options. Only teams with records in the selected decade appear.
- **Current roster** uses NHL's roster endpoint, not accumulated decade appearances. The snapshot date is visible. Nationality is unrestricted; the league is NHL only, U.S. and Canadian clubs.
- All decades includes historical appearances; current-roster-only newcomers belong in Current roster until an appearance is recorded.
- No-repeat shuffle within a selected pool; giving up or changing filters after guesses counts as a loss. Device-local score storage. Winning, losing, or giving up reveals a player card with the team(s) and recorded position(s) in the selected decade/team; All decades uses career records. Current roster cards use that snapshot’s team and position. No team/position spoilers during play.

## Sources and refresh
Official NHL services: https://api.nhle.com/stats/rest/en/team, https://api.nhle.com/stats/rest/en/team/summary, https://api.nhle.com/stats/rest/en/skater/summary, https://api.nhle.com/stats/rest/en/goalie/summary, https://api-web.nhle.com/v1/standings/now, https://api-web.nhle.com/v1/roster/{team}/current.

`python3 scripts/update-rosters.py` rebuilds all data. `--refresh-current` preserves closed historical decades and refreshes the current decade and current rosters. The daily GitHub workflow validates the snapshot before committing and requests a Pages rebuild. Failed NHL requests or unresolved memberships abort without replacing the existing snapshot. Daily scheduled workflows can be delayed or disabled by GitHub; the UI always displays the actual snapshot date, not a promise of live rosters.

## Run / publish
`npm start` → http://localhost:8000. `npm test` checks game rules and real roster memberships. GitHub Actions also checks browser gameplay and responsive widths at 320, 390, 768, and 1280px. Static assets and the roster snapshot are served from GitHub Pages `main / (root)` with relative URLs. No live API dependency in the game.

Not affiliated with the NHL or its teams. No league logos or player images.

## iOS simulator preparation
The iOS app uses Capacitor to bundle this same game and NHL snapshot locally. Sound and the speaker button have been removed for now. See [IOS_SETUP.md](IOS_SETUP.md) for Mac prerequisites, simulator instructions, and a testing checklist.

`npm run ios:setup` builds the web assets and creates the native project if needed. `npm run ios:open` rebuilds, syncs, and opens Xcode. No Apple upload or publication is part of these commands. Bundled current rosters reflect the snapshot at build time; a website data refresh does not update an installed native app.

## Mobile screen flow
Start: choose a decade/team, see saved scores, then tap Play. Options are remembered on this device. Game: only the round, rink, player name, alphabet buttons and give-up action. Result: reveal the player and their team/position, then Play again or Change options. Leaving a round after guessing asks for confirmation and counts as a loss; changing setup options alone does not affect scores. Compact phones use six keyboard columns instead of seven. The name and keyboard stay together on ordinary portrait screens; short screens and larger text may scroll rather than clip controls.
