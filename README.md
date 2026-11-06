# Hat Trick Hangman
Mobile-first NHL hangman with first and last names, six misses, and a once-per-round bonus miss for three correct letters in a row.

## NHL records and filters
- Decades span the NHL's recorded history, starting in 1917. A decade uses the season's **start year**: 1989–90 is in the 1980s.
- Historical player pools include **regular-season appearances**, including goalies. These are not claims of full administrative rosters (players with no appearances are excluded).
- Team filters use actual historical team identities, including defunct/renamed clubs. Quebec Nordiques and Colorado Avalanche, for example, are separate options. Only teams with records in the selected decade appear.
- **Current roster** uses NHL's roster endpoint, not accumulated decade appearances. The snapshot date is recorded in the data file. Nationality is unrestricted; the league is NHL only, U.S. and Canadian clubs.
- All decades includes historical appearances; current-roster-only newcomers belong in Current roster until an appearance is recorded.
- No-repeat shuffle within a selected pool; giving up counts as a loss. Exiting to the home screen clears the round without a loss. Device-local score storage. Winning, losing, or giving up reveals a player card with the team(s) and recorded position(s) in the selected decade/team; All decades uses career records. Current roster cards use that snapshot’s team and position. No team/position spoilers during play.

## Sources and refresh
Official NHL services: https://api.nhle.com/stats/rest/en/team, https://api.nhle.com/stats/rest/en/team/summary, https://api.nhle.com/stats/rest/en/skater/summary, https://api.nhle.com/stats/rest/en/goalie/summary, https://api-web.nhle.com/v1/standings/now, https://api-web.nhle.com/v1/roster/{team}/current.

`python3 scripts/update-rosters.py` rebuilds all data. `--refresh-current` preserves closed historical decades and refreshes the current decade and current rosters. The daily GitHub workflow validates the snapshot before committing and requests a Pages rebuild. Failed NHL requests or unresolved memberships abort without replacing the existing snapshot. Daily scheduled workflows can be delayed or disabled by GitHub; the data file records the actual snapshot date, not a promise of live rosters.

## Run / publish
`npm start` → http://localhost:8000. `npm test` checks game rules and real roster memberships. GitHub Actions also checks browser gameplay and responsive widths at 320, 390, 768, and 1280px. Static assets and the roster snapshot are served from GitHub Pages `main / (root)` with relative URLs. No live API dependency in the game.

Not affiliated with the NHL or its teams. No league logos or player images.

## Web game features

Home, gameplay, results, and menu screens share the Hat Trick Hangman branding. Team accents, the puck buttons, centered alphabetical keyboard, extra-guess reward, and perfect-game confetti come from the mobile review branch. Reduced-motion preferences disable confetti. Scores remain local to the browser. Audio is on hold pending client recordings. See [TODO.md](TODO.md) and [team colors](docs/team-colors.md).

## Development

Use Node 22 or newer. Run `npm ci`, `npm test`, and `npm run build`. `npm start` serves the source version. The generated `dist/` is optional for static hosting; GitHub Pages continues serving the repository root. There is no Capacitor or Xcode dependency in this web version.

## Rollback

The main branch before this web update is preserved as `backup/main-before-web-update-2026-11-05` at commit `6b4e814`. To undo the update, revert the web-update commit on main and push the revert. This preserves later history and lets Pages publish the previous interface. The backup branch also retains the exact earlier source and roster snapshot. The iOS work remains on `mobile/capacitor-ios-prep`.

## Responsive layouts

Phones keep the compact single-column screens and hamburger menu. At 768px and above, the header spans the viewport with visible navigation and the home screen uses a centered stack with a compact scoreboard, side-by-side decade/team fields, player count, and puck. Phone fields remain stacked, with PLAY after the selections. The scoreboard sits just below the header, and the dropdowns match its total width. Gameplay keeps the rink above the player name and keyboard at every width. Information screens retain a readable text width. Resizing preserves the active game and saved scores.

The logo returns home. Desktop navigation contains How to play and Roster information; phones retain the hamburger menu. The desktop home layout balances the space above the scoreboard with the space below PLAY, distributing the remaining space around the selections. Escape closes information/menu screens and returns to the previous game or home screen.
