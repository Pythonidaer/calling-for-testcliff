# TODO

- [ ] Revisit team colors. The single-accent treatment is accepted for now, not final. Review the scoreboard bottom border, dropdown bottom borders, and rink outline. Explore whether one or two team colors work better, and whether a full scoreboard treatment or hangman bar treatment is worthwhile. A themed scoreboard needs a coordinated palette of accessible surfaces, labels, digits, and borders that stays recognizable as the team. See [the color inventory and exploration notes](docs/team-colors.md).

## Mobile review checklist

Checked items are implemented or explicitly closed for this review pass. Deferred explorations remain documented separately. Unchecked items remain future work.

- [x] Center the alphabetical A–Z keyboard rows.
- [x] Shorten the hangman support bars and align the rope with the rink center line.
- [x] Align the top of the head with the top of the center circle.
- [x] Apply one team accent to the scoreboard bottom border, dropdown bottom borders, and rink outline. Accepted for now, with a separate color exploration TODO above.
- [ ] Verify all NHL player names and roster assignments before an iOS release. Follow the verification plan below.
- [x] Capitalize PLAY, PLAY AGAIN, and GOAL. Remove the exclamation mark from GOAL.
- [x] Simplify How to play: full-name introduction, retain numbered rules, remove accent/punctuation and body-part explanations, remove exit/storage/streak paragraphs, and retain the give-up loss warning.
- [ ] Decide which statistics to show. Currently Wins, Streak, and Best streak. This item is a placeholder for considering additional statistics, not a committed feature.
- [x] Exiting a game adds no loss and playing again starts a fresh round. Give up and reveal counts as a loss. Replace the button's ampersand with “and.”
- [x] Close full scoreboard palette and hangman bar color exploration for this review pass. Deferred to the open team-color TODO above and docs/team-colors.md, not implemented.
- [x] Add four simple faceoff circles. Position and size accepted for now.
- [ ] ON HOLD — Await client-recorded audio before adding sounds: short boo for a miss, short applause and “yeah” for a correct guess, bigger applause and a charge sound for a win.
- [x] Change the completed hat-trick bonus message to “Extra guess earned.”
- [x] Add Realistic Look confetti for a perfect win with zero misses. Remove the temporary test button.
- [ ] ON HOLD — Add two charge sounds for a perfect game when client audio is ready.
- [x] Replace the circular play buttons with SVG cylindrical pucks, without triangles. Accepted for now. Current labels are PLAY and PLAY AGAIN. NEW GAME was the earlier label idea.
- [ ] Review font sizes and accessibility for the specific text the user identifies next. Await that selection before making changes.

## Deferred rink detail

“Suggestion of a goal” meant a minimal goal or goal-crease marking at each end of the rink. It has not been added and is outside the current faceoff-circle task. No further rink details are planned without a specific request.

## Player-name verification plan

No client-preferred reference source has been selected. Start with official NHL records, then use a second historical source for gaps or conflicting records. This is planned work, not completed verification.

- [ ] Identify and document the source records and retrieval date.
- [ ] Match players by NHL player ID where available, rather than name alone.
- [ ] Compare full-name spellings, accents, punctuation, and duplicate or ambiguous names.
- [ ] Confirm regular-season appearances for each selected team and decade, including defunct and renamed teams.
- [ ] Produce an exceptions report for unmatched names, conflicting spellings, duplicates, and questionable roster assignments. Review exceptions manually.
- [ ] Check that accented names, hyphens, apostrophes, and long names work in the game.

## Sound cues — on hold until client recordings arrive

- [ ] Miss: a short boo.
- [ ] Correct guess: short applause and “yeah.”
- [ ] Win: bigger applause and one charge sound.
- [ ] Perfect game with zero misses: confetti (already implemented) and two charge sounds. When implementing, ensure this does not accidentally stack with the normal win charge and play three times.
