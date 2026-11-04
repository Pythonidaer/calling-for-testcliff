# TODO

- [ ] Revisit team colors. The single-accent treatment is accepted for now, not final. Review the scoreboard bottom border, dropdown bottom borders, and rink outline. Explore whether one or two team colors work better, and whether a full scoreboard treatment or hangman bar treatment is worthwhile. A themed scoreboard needs a coordinated palette of accessible surfaces, labels, digits, and borders that stays recognizable as the team. See [the color inventory and exploration notes](docs/team-colors.md).

## Mobile review checklist

Checked items have been implemented. The current How to play changes are ready for simulator review. Unchecked items remain future work.

- [x] Center the alphabetical A–Z keyboard rows.
- [x] Shorten the hangman support bars and align the rope with the rink center line.
- [x] Align the top of the head with the top of the center circle.
- [x] Apply one team accent to the scoreboard bottom border, dropdown bottom borders, and rink outline. Accepted for now, with a separate color exploration TODO above.
- [ ] Verify all NHL player names before an iOS release.
- [x] Capitalize PLAY, PLAY AGAIN, and GOAL. Remove the exclamation mark from GOAL.
- [x] Simplify How to play: full-name introduction, retain numbered rules, remove accent/punctuation and body-part explanations, remove exit/storage/streak paragraphs, and retain the give-up loss warning.
- [ ] Decide which statistics to show.
- [x] Exiting a game adds no loss and playing again starts a fresh round. Give up and reveal counts as a loss. Replace the button's ampersand with “and.”
- [ ] Explore a full scoreboard palette and the hangman support bar color.
- [ ] Add faceoff circles and a suggestion of a goal.
- [ ] Add sounds: short boo for a miss, short applause and “yeah” for a correct guess, bigger applause and a charge sound for a win.
- [x] Change the completed hat-trick bonus message to “Extra guess earned.”
- [ ] Add confetti and two charge sounds for a perfect game.
- [ ] Replace the circular Play button with a cylindrical puck labeled NEW GAME, without a triangle.
- [ ] Increase font sizes throughout and review fit and accessibility.
