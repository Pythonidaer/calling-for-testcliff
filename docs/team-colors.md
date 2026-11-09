# Team colors: reference and future exploration

Status: the first accent treatment is accepted for now. Revisit before treating the design as final. See [the open TODO](../TODO.md).

## Implemented treatment

One main accent per team identity is applied to:

| Component | Applied color role |
| --- | --- |
| Home scoreboard | Bottom border only |
| Decade dropdown | Bottom border only |
| NHL team dropdown | Bottom border only |
| Game rink | Outer outline only |

The existing brand theme, scoreboard surfaces, labels, numbers, play button, keyboard, hangman, rope, and rink markings retain their existing colors. Changing the selected team updates the accent immediately. Saved team selections restore their accent on launch. The selected decade does not change a team's accent.

Selecting **All teams** restores the existing defaults: scoreboard bottom border `#BC412C`, dropdown bottom borders and rink outline `#102B33`.

The runtime source of truth is [team-accents.js](../js/team-accents.js), keyed by roster team ID. [app.js](../js/app.js) sets `--team-accent`, and [styles.css](../styles.css) applies it to the three component types above. Update this document when changing the mapping.

## Accent inventory

These are the exact implemented digital values, not a claim that every shade is an officially specified historical hex code. Each identity has one representative accent. The last column preserves the second color considered during planning. Those secondary colors are not implemented and their exact values remain to be chosen.

| Team | Roster ID | Implemented accent | Optional second color considered |
| --- | --- | --- | --- |
| Anaheim Ducks | 24 | `#CF4520` | Gold |
| Arizona Coyotes | 53 | `#862633` | Sand |
| Atlanta Flames | 47 | `#C8102E` | Gold |
| Atlanta Thrashers | 11 | `#5C88DA` | Midnight blue |
| Boston Bruins | 6 | `#FFB81C` | Black |
| Brooklyn Americans | 51 | `#C8102E` | Blue |
| Buffalo Sabres | 7 | `#003087` | Gold |
| Calgary Flames | 20 | `#C8102E` | Gold |
| California Golden Seals | 56 | `#00965E` | Gold |
| Carolina Hurricanes | 12 | `#CC0000` | Black |
| Chicago Blackhawks | 16 | `#CF0A2C` | Black |
| Cleveland Barons | 49 | `#C8102E` | Black |
| Colorado Avalanche | 21 | `#6F263D` | Blue |
| Colorado Rockies | 35 | `#0032A0` | Red |
| Columbus Blue Jackets | 29 | `#002654` | Red |
| Dallas Stars | 25 | `#006847` | Silver |
| Detroit Cougars | 40 | `#E4002B` | White |
| Detroit Falcons | 50 | `#E4002B` | Gold |
| Detroit Red Wings | 17 | `#CE1126` | White |
| Edmonton Oilers | 22 | `#0038A8` | Orange |
| Florida Panthers | 13 | `#C8102E` | Navy |
| Hamilton Tigers | 37 | `#FFC72C` | Black |
| Hartford Whalers | 34 | `#046A38` | Blue |
| Kansas City Scouts | 48 | `#0038A8` | Red |
| Los Angeles Kings | 26 | `#111111` | Silver |
| Minnesota North Stars | 31 | `#007A33` | Gold |
| Minnesota Wild | 30 | `#154734` | Red |
| Montreal Maroons | 43 | `#672146` | White |
| Montreal Wanderers | 41 | `#E4002B` | White |
| Montréal Canadiens | 8 | `#AF1E2D` | Blue |
| Nashville Predators | 18 | `#FFB81C` | Navy |
| New Jersey Devils | 1 | `#CE1126` | Black |
| New York Americans | 44 | `#C8102E` | Blue |
| New York Islanders | 2 | `#00539B` | Orange |
| New York Rangers | 3 | `#0038A8` | Red |
| Oakland Seals | 46 | `#046A38` | Royal blue |
| Ottawa Senators | 9 | `#C8102E` | Black |
| Ottawa Senators (1917) | 36 | `#DA291C` | Black |
| Philadelphia Flyers | 4 | `#F74902` | Black |
| Philadelphia Quakers | 39 | `#E35205` | Black |
| Phoenix Coyotes | 27 | `#862633` | Hunter green |
| Pittsburgh Penguins | 5 | `#FCB514` | Black |
| Pittsburgh Pirates | 38 | `#F2A900` | Black |
| Quebec Bulldogs | 42 | `#0032A0` | White |
| Quebec Nordiques | 32 | `#005EB8` | Red |
| San Jose Sharks | 28 | `#006D75` | Black |
| Seattle Kraken | 55 | `#99D9D9` | Deep sea blue |
| St. Louis Blues | 19 | `#0072CE` | Yellow |
| St. Louis Eagles | 45 | `#0032A0` | Red |
| Tampa Bay Lightning | 14 | `#002868` | White |
| Toronto Arenas | 57 | `#003087` | White |
| Toronto Maple Leafs | 10 | `#00205B` | White |
| Toronto St. Patricks | 58 | `#046A38` | White |
| Utah Hockey Club | 59 | `#71AFE5` | Rock black |
| Utah Mammoth | 68 | `#71AFE5` | Rock black |
| Vancouver Canucks | 23 | `#00205B` | Green |
| Vegas Golden Knights | 54 | `#B4975A` | Steel gray |
| Washington Capitals | 15 | `#C8102E` | Navy |
| Winnipeg Jets | 52 | `#041E42` | Blue |
| Winnipeg Jets (1979) | 33 | `#0032A0` | Red |

## Components considered for later exploration

| Component | Possible future treatment | Review needed |
| --- | --- | --- |
| Entire scoreboard | Team-based background, darker number panels, borders, labels, and score digits | A coordinated palette with readable foreground/background pairs, rather than replacing every existing color with the single accent |
| Scoreboard bottom border | Retain one accent or try a narrow two-color treatment | Visibility with both dark and pale team colors |
| Dropdown bottom borders | Retain one accent or consider a second team color | Clear control boundaries, focus visibility, and disabled states |
| Rink outline | Retain one accent or explore a restrained two-color outline | Contrast against both the rink fill and page background |
| Hangman support bar | Consider a team color instead of its current ink color | Keep the figure and rope easy to distinguish from the support and rink markings |
| Faceoff circles and goal markings | Consider restrained use of team colors once the rink details are designed | Keep them subordinate to the head, rope, figure, and status text |

These are options to review, not approved implementation changes. Keep the overall game's brand recognizable. Do not automatically recolor the logo, primary action, keyboard, or page background as part of this exploration.

### Scoreboard palette requirements

The scoreboard already uses several distinct roles:

| Current role | Current value |
| --- | --- |
| Main surface | `#102B33` |
| Number-panel surface | `#071B20` |
| Number-panel border | `#B5C9C6` |
| Heading and statistic labels | `#F4F0E6` |
| Score digits | `#FFDA83` |
| Bottom trim | Selected team accent, or `#BC412C` for All teams |

A later team-themed scoreboard needs explicit decisions for each role. Explore suitable team colors and restrained light/dark variations, then check the actual foreground/background combinations for accessible contrast. A team color that works as decorative trim may be unsuitable for small text or a surface behind text.

Preserve the team's recognizable palette while choosing accessible shades. A tint or shade created for the interface should be documented as a UI adaptation, not described as an official team color. Decide whether neutral surfaces remain necessary, particularly for teams whose palettes rely on white, yellow, gold, or pale blue.

Review normal and enlarged text, saved scores, selected options, and keyboard focus. Keep team names and labels so color is never the only way to identify the selection. Test pale accents such as Seattle, dark accents such as Los Angeles and Toronto, and bright accents such as Boston and Philadelphia in the iOS simulator.

## Historical choices and references

This first pass uses a stable palette per roster identity, rather than attempting to match each decade's uniforms. For example, California Golden Seals uses the green/gold era and Pittsburgh Pirates uses its original black/gold era. Phoenix and Arizona remain separate roster identities. Utah Hockey Club and Utah Mammoth currently share an accent.

Before adding decade-dependent palettes, review which era each accent represents. Some historical shades are reconstructed estimates. Public references can also disagree on digital conversions or lag behind a team's uniform changes.

Research references:

- [TruColor: NHL franchise color history](https://www.trucolor.net/portfolio/national-hockey-league-official-colors-franchise-records-1917-1918-through-present/)
- [NHL team digital color reference](https://whatcoloristhis.com/teams/nhl/)
- [Historical team palette reference](https://teampalettes.com/historical)

Use the implemented inventory above to reproduce the current app. Consult the original references again when choosing additional colors or era-specific variations.
